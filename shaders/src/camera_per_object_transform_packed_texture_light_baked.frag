#version 330 core

#include "packed_texture_sampling.glsl"

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
    float brightness;
};

uniform sampler2DArray lightmap_textures;
uniform StaticPointLight static_point_lights[MAX_STATIC_POINT_LIGHTS];
uniform int static_point_light_count;

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
uniform float exposure;
uniform bool output_hdr;

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

out vec4 frag_color;

const float PI = 3.14159265359;
const float ALPHA_MODE_MASK = 1.0;
const uint INVALID_TEXTURE_INDEX = 0xffffffffu;

vec3 srgb_to_linear(vec3 value) {
    vec3 lower = value / 12.92;
    vec3 upper = pow((value + 0.055) / 1.055, vec3(2.4));
    return mix(upper, lower, lessThanEqual(value, vec3(0.04045)));
}

vec3 linear_to_srgb(vec3 value) {
    value = max(value, vec3(0.0));
    vec3 lower = value * 12.92;
    vec3 upper = 1.055 * pow(value, vec3(1.0 / 2.4)) - 0.055;
    return mix(upper, lower, lessThanEqual(value, vec3(0.0031308)));
}

vec4 sample_material_texture(vec2 uv, uint texture_index, uint bounding_box_index, vec4 fallback) {
    if (texture_index == INVALID_TEXTURE_INDEX
        || bounding_box_index == INVALID_TEXTURE_INDEX) return fallback;

    vec4 bounds = get_bounding_box(int(bounding_box_index));
    vec2 repeated_uv = fract(uv);
    vec2 packed_uv = bounds.xy + repeated_uv * bounds.zw;

    // Stay half a texel inside the packed rectangle so bilinear filtering does
    // not pull a neighboring material into this one.
    vec2 half_texel = 0.5 / vec2(textureSize(packed_textures, 0).xy);
    packed_uv = clamp(packed_uv, bounds.xy + half_texel, bounds.xy + bounds.zw - half_texel);
    return texture(packed_textures, vec3(packed_uv, float(texture_index)));
}

float distribution_ggx(vec3 normal, vec3 halfway, float roughness) {
    float alpha = roughness * roughness;
    float alpha_squared = alpha * alpha;
    float normal_dot_halfway = max(dot(normal, halfway), 0.0);
    float denominator = normal_dot_halfway * normal_dot_halfway * (alpha_squared - 1.0) + 1.0;
    return alpha_squared / max(PI * denominator * denominator, 0.0000001);
}

float geometry_schlick_ggx(float normal_dot_direction, float roughness) {
    float r = roughness + 1.0;
    float k = r * r / 8.0;
    return normal_dot_direction / max(normal_dot_direction * (1.0 - k) + k, 0.0001);
}

float geometry_smith(vec3 normal, vec3 view_direction, vec3 light_direction, float roughness) {
    return geometry_schlick_ggx(max(dot(normal, view_direction), 0.0), roughness)
        * geometry_schlick_ggx(max(dot(normal, light_direction), 0.0), roughness);
}

vec3 fresnel_schlick(float cosine, vec3 f0) {
    return f0 + (vec3(1.0) - f0) * pow(clamp(1.0 - cosine, 0.0, 1.0), 5.0);
}

vec3 normal_from_material_texture(vec3 sampled_normal) {
    vec3 normal = normalize(world_normal);
    vec3 tangent = normalize(world_tangent.xyz - normal * dot(normal, world_tangent.xyz));
    vec3 bitangent = normalize(cross(normal, tangent)) * world_tangent.w;
    vec3 tangent_normal = sampled_normal * 2.0 - 1.0;
    tangent_normal.xy *= material_parameters.z;
    return normalize(mat3(tangent, bitangent, normal) * tangent_normal);
}

vec3 point_light_specular(
    StaticPointLight light,
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
    float range_fade = 1.0 - normalized_distance_squared * normalized_distance_squared;
    range_fade *= range_fade;
    vec3 radiance = light.color * light.intensity
        * range_fade / (distance_squared + 0.0001);

    vec3 halfway = normalize(view_direction + light_direction);
    float distribution = distribution_ggx(normal, halfway, roughness);
    float geometry = geometry_smith(normal, view_direction, light_direction, roughness);
    vec3 fresnel = fresnel_schlick(max(dot(halfway, view_direction), 0.0), f0);
    float denominator = 4.0
        * max(dot(normal, view_direction), 0.0)
        * normal_dot_light
        + 0.0001;
    return distribution * geometry * fresnel / denominator * radiance * normal_dot_light;
}

vec3 sample_reflection_probe(int probe_index, vec3 direction, float mip) {
    if (probe_index == 0) return textureLod(reflection_probe_cubemap_0, direction, mip).rgb;
    if (probe_index == 1) return textureLod(reflection_probe_cubemap_1, direction, mip).rgb;
    if (probe_index == 2) return textureLod(reflection_probe_cubemap_2, direction, mip).rgb;
    if (probe_index == 3) return textureLod(reflection_probe_cubemap_3, direction, mip).rgb;
    if (probe_index == 4) return textureLod(reflection_probe_cubemap_4, direction, mip).rgb;
    if (probe_index == 5) return textureLod(reflection_probe_cubemap_5, direction, mip).rgb;
    if (probe_index == 6) return textureLod(reflection_probe_cubemap_6, direction, mip).rgb;
    return textureLod(reflection_probe_cubemap_7, direction, mip).rgb;
}

vec3 environment_brdf_approximation(vec3 f0, float roughness, float normal_dot_view) {
    vec4 c0 = vec4(-1.0, -0.0275, -0.572, 0.022);
    vec4 c1 = vec4(1.0, 0.0425, 1.04, -0.04);
    vec4 r = roughness * c0 + c1;
    float a004 = min(r.x * r.x, exp2(-9.28 * normal_dot_view)) * r.x + r.y;
    vec2 ab = vec2(-1.04, 1.04) * a004 + r.zw;
    float f90 = clamp(50.0 * f0.g, 0.0, 1.0);
    return f0 * ab.x + f90 * ab.y;
}

vec3 reflection_probe_specular(
    vec3 normal,
    vec3 view_direction,
    vec3 f0,
    float roughness,
    float ambient_occlusion
) {
    if (reflection_probe_count <= 0) return vec3(0.0);

    vec3 reflection_direction = reflect(-view_direction, normal);
    float mip = roughness * reflection_probe_max_mip;
    vec3 accumulated = vec3(0.0);
    float accumulated_weight = 0.0;

    for (int probe_index = 0; probe_index < MAX_REFLECTION_PROBES; ++probe_index) {
        if (probe_index >= reflection_probe_count) break;
        ReflectionProbe probe = reflection_probes[probe_index];
        float distance_to_probe = distance(world_position, probe.position);
        float weight = clamp(1.0 - distance_to_probe / max(probe.influence_radius, 0.0001), 0.0, 1.0);
        weight *= weight;
        if (weight <= 0.0) continue;

        accumulated += sample_reflection_probe(probe_index, reflection_direction, mip)
            * probe.brightness * weight;
        accumulated_weight += weight;
    }

    if (accumulated_weight <= 0.0) return vec3(0.0);
    vec3 environment = accumulated / accumulated_weight;
    float normal_dot_view = max(dot(normal, view_direction), 0.001);
    float specular_occlusion = clamp(
        pow(normal_dot_view + ambient_occlusion, roughness * roughness)
            - 1.0 + ambient_occlusion,
        0.0,
        1.0
    );
    return environment
        * environment_brdf_approximation(f0, roughness, normal_dot_view)
        * specular_occlusion;
}

void main() {
    vec4 sampled_base_color = sample_material_texture(
        base_color_texture_coordinate,
        packed_texture_index_for_base_color,
        packed_texture_bounding_box_index_for_base_color,
        vec4(1.0)
    );
    vec4 sampled_normal = sample_material_texture(
        normal_texture_coordinate,
        packed_texture_index_for_normal,
        packed_texture_bounding_box_index_for_normal,
        vec4(0.5, 0.5, 1.0, 1.0)
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

    vec3 base_color = srgb_to_linear(sampled_base_color.rgb) * base_color_factor.rgb;
    float alpha = sampled_base_color.a * base_color_factor.a;
    if (alpha_parameters.x == ALPHA_MODE_MASK && alpha < alpha_parameters.y) discard;

    float metallic = clamp(sampled_metallic_roughness.b * material_parameters.x, 0.0, 1.0);
    float roughness = clamp(sampled_metallic_roughness.g * material_parameters.y, 0.04, 1.0);
    float ambient_occlusion = mix(
        1.0,
        clamp(sampled_ambient_occlusion.r, 0.0, 1.0),
        clamp(material_parameters.w, 0.0, 1.0)
    );
    vec3 normal = normal_from_material_texture(sampled_normal.rgb);
    vec3 view_direction = normalize(camera_position - world_position);
    vec3 f0 = mix(vec3(0.04), base_color, metallic);

    vec3 baked_irradiance = max(texture(
        lightmap_textures,
        vec3(clamp(lightmap_texture_coordinate, vec2(0.0), vec2(1.0)), float(lightmap_atlas_index))
    ).rgb, vec3(0.0));
    vec3 diffuse_color = base_color * (1.0 - metallic);
    vec3 baked_diffuse = baked_irradiance * diffuse_color * ambient_occlusion;

    vec3 direct_specular = vec3(0.0);
    for (int light_index = 0; light_index < MAX_STATIC_POINT_LIGHTS; ++light_index) {
        if (light_index >= static_point_light_count) break;
        direct_specular += point_light_specular(
            static_point_lights[light_index],
            normal,
            view_direction,
            f0,
            roughness
        );
    }

    vec3 indirect_specular = reflection_probe_specular(
        normal,
        view_direction,
        f0,
        roughness,
        ambient_occlusion
    );
    vec3 emissive = srgb_to_linear(sampled_emissive.rgb) * emissive_factor;
    vec3 hdr_lighting = max(
        baked_diffuse + direct_specular + indirect_specular + emissive,
        vec3(0.0)
    );

    if (output_hdr) {
        // Reflection capture stores linear HDR surface lighting. It is tone
        // mapped only when the cubemap is sampled by the final view.
        frag_color = vec4(hdr_lighting, alpha);
    } else {
        vec3 display_lighting = vec3(1.0) - exp(-hdr_lighting * exposure);
        frag_color = vec4(linear_to_srgb(display_lighting), alpha);
    }
}
