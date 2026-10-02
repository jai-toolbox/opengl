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
    surface.base_color = packed_texture_index_for_base_color
        == INVALID_TEXTURE_INDEX
        ? base_color_factor.rgb
        : srgb_to_linear(sampled_base_color.rgb) * base_color_factor.rgb;
    surface.emissive = packed_texture_index_for_emissive
        == INVALID_TEXTURE_INDEX
        ? emissive_factor
        : srgb_to_linear(sampled_emissive.rgb) * emissive_factor;
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
#define MAX_DYNAMIC_POINT_LIGHTS 16
#define MAX_REFLECTION_PROBES 64

#extension GL_ARB_texture_cube_map_array : require

struct PointLight {
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

uniform PointLight static_point_lights[MAX_STATIC_POINT_LIGHTS];
uniform int static_point_light_count;
uniform int can_static_point_light_reach_surface_group_indices[MAX_STATIC_POINT_LIGHTS / 4];
uniform bool use_can_static_point_light_reach_surface_texture;
uniform sampler2DArray can_static_point_light_reach_surface_textures;
uniform int can_static_point_light_reach_surface_rgba_group_count;
uniform PointLight dynamic_point_lights[MAX_DYNAMIC_POINT_LIGHTS];
uniform int dynamic_point_light_count;

uniform samplerCubeArray reflection_probe_cubemaps;
uniform ReflectionProbe reflection_probes[MAX_REFLECTION_PROBES];
uniform int reflection_probe_count;
uniform float reflection_probe_max_mip;

uniform vec3 camera_position;

const float PI = 3.14159265359;

vec4 sample_can_static_point_lights_reach_surface(int group_index) {
    int texture_layer = int(lightmap_atlas_index)
        * can_static_point_light_reach_surface_rgba_group_count
        + group_index;
    return texture(
        can_static_point_light_reach_surface_textures,
        vec3(lightmap_texture_coordinate, float(texture_layer)));
}

vec3 linear_to_srgb(vec3 value) {
    value = max(value, vec3(0.0));
    vec3 lower = value * 12.92;
    vec3 upper = 1.055 * pow(value, vec3(1.0 / 2.4)) - 0.055;
    return mix(upper, lower, lessThanEqual(value, vec3(0.0031308)));
}

float distribution_ggx(
    float normal_dot_halfway,
    float alpha_squared
) {
    float denominator = normal_dot_halfway * normal_dot_halfway
        * (alpha_squared - 1.0) + 1.0;
    return alpha_squared / max(PI * denominator * denominator, 0.0000001);
}

float geometry_schlick_ggx(float normal_dot_direction, float k) {
    return normal_dot_direction
        / max(normal_dot_direction * (1.0 - k) + k, 0.0001);
}

vec3 fresnel_schlick(float cosine, vec3 f0) {
    float one_minus_cosine = clamp(1.0 - cosine, 0.0, 1.0);
    float one_minus_cosine_squared = one_minus_cosine * one_minus_cosine;
    float one_minus_cosine_fifth = one_minus_cosine_squared
        * one_minus_cosine_squared * one_minus_cosine;
    return f0 + (vec3(1.0) - f0) * one_minus_cosine_fifth;
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
    PointLight light,
    float light_reaches_surface_factor,
    vec3 normal,
    vec3 view_direction,
    vec3 f0,
    float normal_dot_view,
    float alpha_squared,
    float geometry_k,
    float geometry_view
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

    float view_dot_light = dot(view_direction, light_direction);
    float inverse_halfway_length = inversesqrt(
        max(2.0 + 2.0 * view_dot_light, 0.00000001));
    float normal_dot_halfway = max(
        (normal_dot_view + normal_dot_light) * inverse_halfway_length,
        0.0);
    float halfway_dot_view = max(
        (1.0 + view_dot_light) * inverse_halfway_length,
        0.0);
    float distribution = distribution_ggx(
        normal_dot_halfway, alpha_squared);
    float geometry = geometry_view
        * geometry_schlick_ggx(normal_dot_light, geometry_k);
    vec3 fresnel = fresnel_schlick(
        halfway_dot_view,
        f0
    );
    float denominator = 4.0
        * normal_dot_view * normal_dot_light
        + 0.0001;
    return distribution * geometry * fresnel
        / denominator * radiance * normal_dot_light * light_reaches_surface_factor;
}

vec3 dynamic_point_light_direct(
    PointLight light,
    vec3 normal,
    vec3 view_direction,
    vec3 base_color,
    float metallic,
    vec3 f0,
    float normal_dot_view,
    float alpha_squared,
    float geometry_k,
    float geometry_view
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

    float view_dot_light = dot(view_direction, light_direction);
    float inverse_halfway_length = inversesqrt(
        max(2.0 + 2.0 * view_dot_light, 0.00000001));
    float normal_dot_halfway = max(
        (normal_dot_view + normal_dot_light) * inverse_halfway_length,
        0.0);
    float halfway_dot_view = max(
        (1.0 + view_dot_light) * inverse_halfway_length,
        0.0);
    vec3 fresnel = fresnel_schlick(
        halfway_dot_view, f0);
    vec3 diffuse_brdf = (vec3(1.0) - fresnel)
        * (1.0 - metallic) * base_color / PI;
    float distribution = distribution_ggx(
        normal_dot_halfway, alpha_squared);
    float geometry = geometry_view
        * geometry_schlick_ggx(normal_dot_light, geometry_k);
    float denominator = 4.0
        * normal_dot_view * normal_dot_light + 0.0001;
    vec3 specular_brdf = distribution * geometry * fresnel / denominator;
    return (diffuse_brdf + specular_brdf) * radiance * normal_dot_light;
}

vec3 sample_reflection_probe(int probe_index, vec3 direction, float mip) {
    return textureLod(
        reflection_probe_cubemaps,
        vec4(direction, float(probe_index)),
        mip
    ).rgb;
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
    vec3 weighted_reflection_sum = vec3(0.0);
    float weighted_average_brightness_sum = 0.0;
    float total_probe_weight = 0.0;
    float reflection_coverage = 0.0;
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

        // distance weighting has no full-weight plateau. Raising proximity
        // to the fourth power makes the closest probe dominate while keeping
        // the result continuous as the dominant probe changes.
        float proximity = max(1.0 - normalized_distance, 0.0);
        float proximity_squared = proximity * proximity;
        float distance_weight = proximity_squared * proximity_squared;

        // coverage is separate from blending so a small normalized weight does
        // not darken reflections. It only fades across the outer 10% of a
        // probe's influence volume when no neighboring probe covers the point.
        float coverage = 1.0 - smoothstep(
            0.9,
            1.0,
            normalized_distance
        );

        // intersect the reflected ray with the probe's influence sphere. The
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

        weighted_reflection_sum += sample_reflection_probe(
            probe_index,
            projected_direction,
            mip
        ) * distance_weight;
        weighted_average_brightness_sum += probe.average_brightness
            * distance_weight;
        total_probe_weight += distance_weight;
        reflection_coverage = max(reflection_coverage, coverage);
    }

    if (total_probe_weight <= 0.000000000001) return vec3(0.0);

    // dividing by the shared sum makes the result independent of probe loop
    // order while retaining the relative distance preference.
    vec3 accumulated = weighted_reflection_sum
        / total_probe_weight
        * reflection_coverage
        * specular_occlusion;
    float composited_average_brightness =
        weighted_average_brightness_sum
        / total_probe_weight
        * reflection_coverage;

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
uniform bool use_light_volume;
uniform vec3 light_volume_coefficients[9];
out vec4 frag_color;

vec3 light_volume_diffuse_irradiance(vec3 normal) {
    normal = normalize(normal);
    float basis[9];
    basis[0] = 0.282095;
    basis[1] = 0.488603 * normal.y;
    basis[2] = 0.488603 * normal.z;
    basis[3] = 0.488603 * normal.x;
    basis[4] = 1.092548 * normal.x * normal.y;
    basis[5] = 1.092548 * normal.y * normal.z;
    basis[6] = 0.315392 * (3.0 * normal.z * normal.z - 1.0);
    basis[7] = 1.092548 * normal.x * normal.z;
    basis[8] = 0.546274 * (normal.x * normal.x - normal.y * normal.y);

    vec3 result = light_volume_coefficients[0] * basis[0] * PI;
    for (int coefficient_index = 1; coefficient_index <= 3; ++coefficient_index) {
        result += light_volume_coefficients[coefficient_index]
            * basis[coefficient_index] * (2.0 * PI / 3.0);
    }
    for (int coefficient_index = 4; coefficient_index <= 8; ++coefficient_index) {
        result += light_volume_coefficients[coefficient_index]
            * basis[coefficient_index] * (PI / 4.0);
    }
    return max(result, vec3(0.0));
}

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
    float normal_dot_view = max(dot(normal, view_direction), 0.0);
    float alpha = surface.roughness * surface.roughness;
    float alpha_squared = alpha * alpha;
    float roughness_plus_one = surface.roughness + 1.0;
    float geometry_k = roughness_plus_one * roughness_plus_one / 8.0;
    float geometry_view = geometry_schlick_ggx(
        normal_dot_view, geometry_k);

    vec3 baked_irradiance = use_light_volume
        ? light_volume_diffuse_irradiance(normal)
        : sample_baked_irradiance();
    vec3 diffuse_color = surface.base_color * (1.0 - surface.metallic);
    vec3 baked_diffuse = baked_irradiance
        * diffuse_color
        * surface.ambient_occlusion;

    vec3 direct_specular = vec3(0.0);
    for (int group_slot = 0; group_slot < MAX_STATIC_POINT_LIGHTS / 4; ++group_slot) {
        int first_light_index = group_slot * 4;
        if (first_light_index >= static_point_light_count) break;
        int source_group_index =
            can_static_point_light_reach_surface_group_indices[group_slot];
        vec4 static_lights_reach_surface_factors = use_can_static_point_light_reach_surface_texture
            ? sample_can_static_point_lights_reach_surface(source_group_index)
            : vec4(1.0);
        for (int channel_index = 0; channel_index < 4; ++channel_index) {
            int light_index = first_light_index + channel_index;
            if (light_index >= static_point_light_count) break;
            if (static_lights_reach_surface_factors[channel_index] <= 0.0) continue;
            direct_specular += point_light_specular(
                static_point_lights[light_index],
                static_lights_reach_surface_factors[channel_index],
                normal,
                view_direction,
                f0,
                normal_dot_view,
                alpha_squared,
                geometry_k,
                geometry_view
            );
        }
    }

    vec3 dynamic_direct = vec3(0.0);
    for (int light_index = 0; light_index < MAX_DYNAMIC_POINT_LIGHTS; ++light_index) {
        if (light_index >= dynamic_point_light_count) break;
        dynamic_direct += dynamic_point_light_direct(
            dynamic_point_lights[light_index],
            normal,
            view_direction,
            surface.base_color,
            surface.metallic,
            f0,
            normal_dot_view,
            alpha_squared,
            geometry_k,
            geometry_view
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
        baked_diffuse + direct_specular + dynamic_direct
            + indirect_specular + surface.emissive,
        vec3(0.0)
    );

    vec3 display_lighting = vec3(1.0) - exp(-hdr_lighting * exposure);
    frag_color = vec4(linear_to_srgb(display_lighting), surface.alpha);
}
