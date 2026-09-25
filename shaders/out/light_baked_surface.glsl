// Begin include: packed_texture_sampling.glsl
// Resource contract:
// packed_textures is an OpenGL 3.3 bindless-texture workaround. It is a texture
// array whose layers are power-of-two container textures. Each container layer
// may itself hold many smaller source textures packed into rectangular regions.
// The runtime texture packer owns creating and uploading this array.
//
// Geometry does not bind a different texture per object. Instead, vertex
// attributes carry integer indices that select a packed container layer and a
// bounding-box entry. This lets many objects draw together without one draw call
// per texture bind.
uniform sampler2DArray packed_textures;

// the next lines are really bad and cause stuff to break 
// because running out of uniform space, instead 
// use a texture thing: https://stackoverflow.com/questions/51781227/estimate-number-of-registers-required-in-glsl-shader

// packed_texture_bounding_boxes stores vec4 entries in the form:
//   x = top-left u, y = top-left v, z = width, w = height
// Each entry describes the sub-rectangle for one packed source texture inside a
// container layer of packed_textures. Vertex attributes choose which entry to
// use for each object/material channel.
uniform sampler1D packed_texture_bounding_boxes;
//
// note that before we used to do this, but it caused an array about using up too many constant registers
// which come from using too many uniforms, so we no longer do the below, but instead the above.
// 
#define MAX_NUM_TEXTURES 1024
// uniform vec4 packed_texture_bounding_boxes[MAX_NUM_TEXTURES];


vec4 get_bounding_box(int index) {
    // this is the definition of how bounding boxes are stored in textures, as vector4s
    return texture( packed_texture_bounding_boxes, float(index) / float(MAX_NUM_TEXTURES));
}

/*

Wraps a texture coordinate (tc) to stay within the given bounding box. 

We assume that the tc is in the packed texture space (not local uvs)

 */
vec2 wrap_texture_coordinate(vec2 tc, vec4 bbox) {
    float tlx = bbox.x;      // top-left x
    float tly = bbox.y;      // top-left y
    float width = bbox.z;    
    float height = bbox.w;   

    // calculate deltas from the top-left corner
    float dx = tc.x - tlx;
    float dy = tc.y - tly;

    // wrap the coordinates using modulo and shift back into the bounding box
    float wrapped_x = mod(dx, width) + tlx;
    float wrapped_y = mod(dy, height) + tly;

    return vec2(wrapped_x, wrapped_y);
}

/**
 * @brief Samples from a 2D texture array.
 * 
 * @param texture_array The sampler2DArray containing the packed textures.
 * @param tex_coord The 2D texture coordinates for sampling.
 * @param texture_index The index of the texture in the array.
 * @param bounding_boxes The array of bounding boxes for the textures.
 * @param bounding_box_index The index of the bounding box for the current texture.
 * @return vec4 The sampled color from the texture.
 */
vec4 sample_packed_texture(
    sampler2DArray texture_array,
    vec2 tex_coord,
    int texture_index,
    int bounding_box_index
) {
    vec4 bbox = get_bounding_box(bounding_box_index);
    return texture(texture_array, vec3(wrap_texture_coordinate(tex_coord, bbox), texture_index));
}
// End include: packed_texture_sampling.glsl

uniform sampler2DArray lightmap_textures;
uniform float packed_texture_max_mip_level;

in vec3 world_position;
in vec3 world_normal;
in vec4 world_tangent;

in vec2 base_color_texture_coordinate;
in vec2 normal_texture_coordinate;
in vec2 metallic_roughness_texture_coordinate;
in vec2 ambient_occlusion_texture_coordinate;
in vec2 emissive_texture_coordinate;
in vec2 lightmap_texture_coordinate;

flat in vec4 base_color_factor;
flat in vec4 material_parameters;
flat in vec3 emissive_factor;
flat in vec2 alpha_parameters;

flat in uint packed_texture_index_for_base_color;
flat in uint packed_texture_bounding_box_index_for_base_color;
flat in uint packed_texture_index_for_normal;
flat in uint packed_texture_bounding_box_index_for_normal;
flat in uint packed_texture_index_for_metallic_roughness;
flat in uint packed_texture_bounding_box_index_for_metallic_roughness;
flat in uint packed_texture_index_for_ambient_occlusion;
flat in uint packed_texture_bounding_box_index_for_ambient_occlusion;
flat in uint packed_texture_index_for_emissive;
flat in uint packed_texture_bounding_box_index_for_emissive;
flat in uint lightmap_atlas_index;

const float ALPHA_MODE_MASK = 1.0;
const uint INVALID_TEXTURE_INDEX = 0xffffffffu;

struct LightBakedSurface {
    vec3 base_color;
    vec3 emissive;
    float alpha;
    float alpha_mode;
    float alpha_cutoff;
    float metallic;
    float roughness;
    float ambient_occlusion;
};

vec3 srgb_to_linear(vec3 value) {
    vec3 lower = value / 12.92;
    vec3 upper = pow((value + 0.055) / 1.055, vec3(2.4));
    return mix(upper, lower, lessThanEqual(value, vec3(0.04045)));
}

vec4 sample_material_texture(
    vec2 uv,
    uint texture_index,
    uint bounding_box_index,
    vec4 fallback
) {
    if (texture_index == INVALID_TEXTURE_INDEX
        || bounding_box_index == INVALID_TEXTURE_INDEX) return fallback;

    vec4 bounds = get_bounding_box(int(bounding_box_index));
    vec2 atlas_size = vec2(textureSize(packed_textures, 0).xy);
    vec2 packed_gradient_x = dFdx(uv) * bounds.zw;
    vec2 packed_gradient_y = dFdy(uv) * bounds.zw;
    vec2 pixel_gradient_x = packed_gradient_x * atlas_size;
    vec2 pixel_gradient_y = packed_gradient_y * atlas_size;
    float footprint_squared = max(
        dot(pixel_gradient_x, pixel_gradient_x),
        dot(pixel_gradient_y, pixel_gradient_y));
    float requested_mip = max(
        0.0,
        0.5 * log2(max(footprint_squared, 1.0)));
    vec2 source_size = max(bounds.zw * atlas_size, vec2(1.0));
    float maximum_region_mip = floor(log2(min(source_size.x, source_size.y)));
    float sampled_mip = min(
        ceil(requested_mip),
        min(maximum_region_mip, packed_texture_max_mip_level));

    vec2 repeated_uv = fract(uv);
    vec2 packed_uv = bounds.xy + repeated_uv * bounds.zw;

    // Filtering happens in the selected mip level. Its texels are larger than
    // base-level texels, so use a matching inset to keep bilinear filtering
    // inside this material's packed rectangle. Explicit gradients also avoid
    // a false, very coarse mip choice at fract() wrap boundaries.
    vec2 half_mip_texel = 0.5 * exp2(sampled_mip) / atlas_size;
    packed_uv = clamp(
        packed_uv,
        bounds.xy + half_mip_texel,
        bounds.xy + bounds.zw - half_mip_texel
    );
    return textureGrad(
        packed_textures,
        vec3(packed_uv, float(texture_index)),
        packed_gradient_x,
        packed_gradient_y);
}

bool light_baked_surface_passes_alpha_mask() {
    if (alpha_parameters.x != ALPHA_MODE_MASK) return true;

    vec4 sampled_base_color = sample_material_texture(
        base_color_texture_coordinate,
        packed_texture_index_for_base_color,
        packed_texture_bounding_box_index_for_base_color,
        vec4(1.0)
    );
    float alpha = sampled_base_color.a * base_color_factor.a;
    return alpha >= alpha_parameters.y;
}

LightBakedSurface sample_light_baked_surface() {
    vec4 sampled_base_color = sample_material_texture(
        base_color_texture_coordinate,
        packed_texture_index_for_base_color,
        packed_texture_bounding_box_index_for_base_color,
        vec4(1.0)
    );
    vec4 sampled_metallic_roughness = sample_material_texture(
        metallic_roughness_texture_coordinate,
        packed_texture_index_for_metallic_roughness,
        packed_texture_bounding_box_index_for_metallic_roughness,
        vec4(1.0)
    );
    vec4 sampled_ambient_occlusion = sample_material_texture(
        ambient_occlusion_texture_coordinate,
        packed_texture_index_for_ambient_occlusion,
        packed_texture_bounding_box_index_for_ambient_occlusion,
        vec4(1.0)
    );
    vec4 sampled_emissive = sample_material_texture(
        emissive_texture_coordinate,
        packed_texture_index_for_emissive,
        packed_texture_bounding_box_index_for_emissive,
        vec4(1.0)
    );

    LightBakedSurface surface;
    surface.base_color = srgb_to_linear(sampled_base_color.rgb)
        * base_color_factor.rgb;
    surface.emissive = srgb_to_linear(sampled_emissive.rgb) * emissive_factor;
    surface.alpha = sampled_base_color.a * base_color_factor.a;
    surface.alpha_mode = alpha_parameters.x;
    surface.alpha_cutoff = alpha_parameters.y;
    surface.metallic = clamp(
        sampled_metallic_roughness.b * material_parameters.x,
        0.0,
        1.0
    );
    surface.roughness = clamp(
        sampled_metallic_roughness.g * material_parameters.y,
        0.04,
        1.0
    );
    surface.ambient_occlusion = mix(
        1.0,
        clamp(sampled_ambient_occlusion.r, 0.0, 1.0),
        clamp(material_parameters.w, 0.0, 1.0)
    );
    return surface;
}

vec3 sample_baked_irradiance() {
    return max(texture(
        lightmap_textures,
        vec3(
            clamp(lightmap_texture_coordinate, vec2(0.0), vec2(1.0)),
            float(lightmap_atlas_index)
        )
    ).rgb, vec3(0.0));
}
