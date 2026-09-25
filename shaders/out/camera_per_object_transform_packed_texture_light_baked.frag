#version 330 core

// Begin include: light_baked_surface.glsl
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
// End include: light_baked_surface.glsl
// Begin include: light_baked_pbr.glsl
#define MAX_STATIC_POINT_LIGHTS 16
#define MAX_REFLECTION_PROBES 8

struct StaticPointLight {
    vec3 position;
    vec3 color;
    float intensity;
    float range;
};

struct ReflectionProbe {
    vec3 position;
    float influence_radius;
    float average_brightness;
};

uniform StaticPointLight static_point_lights[MAX_STATIC_POINT_LIGHTS];
uniform int static_point_light_count;
uniform sampler2DArray static_point_light_visibility_textures;
uniform int static_point_light_visibility_group_count;

uniform samplerCube reflection_probe_cubemap_0;
uniform samplerCube reflection_probe_cubemap_1;
uniform samplerCube reflection_probe_cubemap_2;
uniform samplerCube reflection_probe_cubemap_3;
uniform samplerCube reflection_probe_cubemap_4;
uniform samplerCube reflection_probe_cubemap_5;
uniform samplerCube reflection_probe_cubemap_6;
uniform samplerCube reflection_probe_cubemap_7;
uniform ReflectionProbe reflection_probes[MAX_REFLECTION_PROBES];
uniform int reflection_probe_count;
uniform float reflection_probe_max_mip;

uniform vec3 camera_position;

const float PI = 3.14159265359;

float static_point_light_visibility(int light_index) {
    int group_index = light_index / 4;
    int channel_index = light_index - group_index * 4;
    int texture_layer = int(lightmap_atlas_index)
        * static_point_light_visibility_group_count
        + group_index;
    vec4 visibility = texture(
        static_point_light_visibility_textures,
        vec3(lightmap_texture_coordinate, float(texture_layer)));
    if (channel_index == 0) return visibility.r;
    if (channel_index == 1) return visibility.g;
    if (channel_index == 2) return visibility.b;
    return visibility.a;
}

vec3 linear_to_srgb(vec3 value) {
    value = max(value, vec3(0.0));
    vec3 lower = value * 12.92;
    vec3 upper = 1.055 * pow(value, vec3(1.0 / 2.4)) - 0.055;
    return mix(upper, lower, lessThanEqual(value, vec3(0.0031308)));
}

float distribution_ggx(vec3 normal, vec3 halfway, float roughness) {
    float alpha = roughness * roughness;
    float alpha_squared = alpha * alpha;
    float normal_dot_halfway = max(dot(normal, halfway), 0.0);
    float denominator = normal_dot_halfway * normal_dot_halfway
        * (alpha_squared - 1.0) + 1.0;
    return alpha_squared / max(PI * denominator * denominator, 0.0000001);
}

float geometry_schlick_ggx(float normal_dot_direction, float roughness) {
    float r = roughness + 1.0;
    float k = r * r / 8.0;
    return normal_dot_direction
        / max(normal_dot_direction * (1.0 - k) + k, 0.0001);
}

float geometry_smith(
    vec3 normal,
    vec3 view_direction,
    vec3 light_direction,
    float roughness
) {
    return geometry_schlick_ggx(
        max(dot(normal, view_direction), 0.0),
        roughness
    ) * geometry_schlick_ggx(
        max(dot(normal, light_direction), 0.0),
        roughness
    );
}

vec3 fresnel_schlick(float cosine, vec3 f0) {
    return f0 + (vec3(1.0) - f0)
        * pow(clamp(1.0 - cosine, 0.0, 1.0), 5.0);
}

vec3 normal_from_material_texture(vec3 sampled_normal) {
    vec3 normal = normalize(world_normal);
    vec3 tangent = normalize(
        world_tangent.xyz - normal * dot(normal, world_tangent.xyz)
    );
    vec3 bitangent = normalize(cross(normal, tangent)) * world_tangent.w;
    vec3 tangent_normal = sampled_normal * 2.0 - 1.0;
    tangent_normal.xy *= material_parameters.z;
    return normalize(mat3(tangent, bitangent, normal) * tangent_normal);
}

vec3 point_light_specular(
    StaticPointLight light,
    int light_index,
    vec3 normal,
    vec3 view_direction,
    vec3 f0,
    float roughness
) {
    vec3 to_light = light.position - world_position;
    float distance_squared = dot(to_light, to_light);
    if (distance_squared <= 0.00000001) return vec3(0.0);

    float range_squared = light.range * light.range;
    if (distance_squared >= range_squared) return vec3(0.0);

    vec3 light_direction = to_light * inversesqrt(distance_squared);
    float normal_dot_light = max(dot(normal, light_direction), 0.0);
    if (normal_dot_light <= 0.0) return vec3(0.0);

    float normalized_distance_squared = distance_squared / range_squared;
    float range_fade = 1.0
        - normalized_distance_squared * normalized_distance_squared;
    range_fade *= range_fade;
    vec3 radiance = light.color * light.intensity
        * range_fade / (distance_squared + 0.0001);

    vec3 halfway = normalize(view_direction + light_direction);
    float distribution = distribution_ggx(normal, halfway, roughness);
    float geometry = geometry_smith(
        normal,
        view_direction,
        light_direction,
        roughness
    );
    vec3 fresnel = fresnel_schlick(
        max(dot(halfway, view_direction), 0.0),
        f0
    );
    float denominator = 4.0
        * max(dot(normal, view_direction), 0.0)
        * normal_dot_light
        + 0.0001;
    // Fetch the baked shadow value only after the inexpensive range and
    // facing tests establish that this light can contribute to the fragment.
    float visibility = static_point_light_visibility(light_index);
    return distribution * geometry * fresnel
        / denominator * radiance * normal_dot_light * visibility;
}

vec3 sample_reflection_probe(int probe_index, vec3 direction, float mip) {
    if (probe_index == 0) {
        return textureLod(reflection_probe_cubemap_0, direction, mip).rgb;
    }
    if (probe_index == 1) {
        return textureLod(reflection_probe_cubemap_1, direction, mip).rgb;
    }
    if (probe_index == 2) {
        return textureLod(reflection_probe_cubemap_2, direction, mip).rgb;
    }
    if (probe_index == 3) {
        return textureLod(reflection_probe_cubemap_3, direction, mip).rgb;
    }
    if (probe_index == 4) {
        return textureLod(reflection_probe_cubemap_4, direction, mip).rgb;
    }
    if (probe_index == 5) {
        return textureLod(reflection_probe_cubemap_5, direction, mip).rgb;
    }
    if (probe_index == 6) {
        return textureLod(reflection_probe_cubemap_6, direction, mip).rgb;
    }
    return textureLod(reflection_probe_cubemap_7, direction, mip).rgb;
}

vec3 environment_brdf_approximation(
    vec3 f0,
    float roughness,
    float normal_dot_view
) {
    vec4 c0 = vec4(-1.0, -0.0275, -0.572, 0.022);
    vec4 c1 = vec4(1.0, 0.0425, 1.04, -0.04);
    vec4 r = roughness * c0 + c1;
    float a004 = min(r.x * r.x, exp2(-9.28 * normal_dot_view))
        * r.x + r.y;
    vec2 ab = vec2(-1.04, 1.04) * a004 + r.zw;
    float f90 = clamp(50.0 * f0.g, 0.0, 1.0);
    return f0 * ab.x + f90 * ab.y;
}

vec3 reflection_probe_specular(
    vec3 normal,
    vec3 view_direction,
    vec3 f0,
    float roughness,
    float ambient_occlusion,
    vec3 indirect_irradiance
) {
    if (reflection_probe_count <= 0) return vec3(0.0);

    float alpha = roughness * roughness;
    vec3 reflected = reflect(-view_direction, normal);
    vec3 reflection_direction = mix(
        normal,
        reflected,
        (1.0 - alpha) * (sqrt(1.0 - alpha) + alpha)
    );
    float level_from_one_by_one = 1.0
        - 1.2 * log2(max(roughness, 0.001));
    float mip = clamp(
        reflection_probe_max_mip - 1.0 - level_from_one_by_one,
        0.0,
        reflection_probe_max_mip
    );
    vec3 accumulated = vec3(0.0);
    float remaining_alpha = 1.0;
    float composited_average_brightness = 0.0;
    float remaining_brightness_alpha = 1.0;
    float normal_dot_view = max(dot(normal, view_direction), 0.001);
    float specular_occlusion = clamp(
        pow(normal_dot_view + ambient_occlusion, alpha)
            - 1.0 + ambient_occlusion,
        0.0,
        1.0
    );

    for (int probe_index = 0; probe_index < MAX_REFLECTION_PROBES; ++probe_index) {
        if (probe_index >= reflection_probe_count) break;
        ReflectionProbe probe = reflection_probes[probe_index];
        vec3 local_position = world_position - probe.position;
        float normalized_distance = length(local_position)
            / max(probe.influence_radius, 0.0001);
        if (normalized_distance >= 1.0) continue;

        float fade_position = clamp(
            2.5 * normalized_distance - 1.5,
            0.0,
            1.0
        );
        float distance_alpha = 1.0 - fade_position * fade_position
            * (3.0 - 2.0 * fade_position);

        // Intersect the reflected ray with the probe's influence sphere. The
        // vector from the capture position to that hit point is the cubemap
        // lookup direction, which keeps reflected features anchored in space.
        float ray_projection = dot(reflection_direction, local_position);
        float sphere_term = dot(local_position, local_position)
            - probe.influence_radius * probe.influence_radius;
        float determinant = ray_projection * ray_projection - sphere_term;
        if (determinant < 0.0) continue;
        float hit_distance = sqrt(determinant) - ray_projection;
        vec3 projected_direction = local_position
            + hit_distance * reflection_direction;

        accumulated += sample_reflection_probe(
            probe_index,
            projected_direction,
            mip
        ) * distance_alpha * specular_occlusion * remaining_alpha;
        remaining_alpha *= 1.0 - distance_alpha;
        composited_average_brightness += probe.average_brightness
            * distance_alpha * remaining_brightness_alpha;
        remaining_brightness_alpha *= 1.0 - distance_alpha;
        if (remaining_alpha <= 0.001) break;
    }

    float indirect_luminance = dot(
        max(indirect_irradiance, vec3(0.0)),
        vec3(0.2126, 0.7152, 0.0722)
    );
    float mixing_alpha = smoothstep(
        0.0,
        1.0,
        clamp(roughness * 5.0 - 0.5, 0.0, 1.0)
    );
    float mixing_weight = min(
        indirect_luminance / max(composited_average_brightness, 0.0001),
        10000.0
    );
    accumulated *= mix(1.0, mixing_weight, mixing_alpha);

    return accumulated
        * environment_brdf_approximation(f0, roughness, normal_dot_view);
}
// End include: light_baked_pbr.glsl

uniform float exposure;
out vec4 frag_color;

void main() {
    LightBakedSurface surface = sample_light_baked_surface();
    vec4 sampled_normal = sample_material_texture(
        normal_texture_coordinate,
        packed_texture_index_for_normal,
        packed_texture_bounding_box_index_for_normal,
        vec4(0.5, 0.5, 1.0, 1.0)
    );
    vec3 normal = normal_from_material_texture(sampled_normal.rgb);
    vec3 view_direction = normalize(camera_position - world_position);
    vec3 f0 = mix(vec3(0.04), surface.base_color, surface.metallic);

    vec3 baked_irradiance = sample_baked_irradiance();
    vec3 diffuse_color = surface.base_color * (1.0 - surface.metallic);
    vec3 baked_diffuse = baked_irradiance
        * diffuse_color
        * surface.ambient_occlusion;

    vec3 direct_specular = vec3(0.0);
    for (int light_index = 0; light_index < MAX_STATIC_POINT_LIGHTS; ++light_index) {
        if (light_index >= static_point_light_count) break;
        direct_specular += point_light_specular(
            static_point_lights[light_index],
            light_index,
            normal,
            view_direction,
            f0,
            surface.roughness
        );
    }

    vec3 indirect_specular = reflection_probe_specular(
        normal,
        view_direction,
        f0,
        surface.roughness,
        surface.ambient_occlusion,
        baked_irradiance
    );
    vec3 hdr_lighting = max(
        baked_diffuse + direct_specular + indirect_specular + surface.emissive,
        vec3(0.0)
    );

    vec3 display_lighting = vec3(1.0) - exp(-hdr_lighting * exposure);
    frag_color = vec4(linear_to_srgb(display_lighting), surface.alpha);
}
