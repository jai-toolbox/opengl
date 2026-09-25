#version 330 core

#include "light_baked_surface.glsl"
#include "light_baked_pbr.glsl"

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
