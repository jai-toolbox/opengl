#version 330 core

#include "light_baked_surface.glsl"
#include "light_baked_pbr.glsl"

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
