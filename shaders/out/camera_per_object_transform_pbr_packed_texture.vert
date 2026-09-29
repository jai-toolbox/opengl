#version 330 core

// Begin include: local_to_world_1024_ubo.glsl
in uint local_to_world_index;

layout(std140, row_major) uniform LtwMatrices {
    mat4 local_to_world_matrices[1024];
};
// End include: local_to_world_1024_ubo.glsl

in vec3 position;
in vec3 passthrough_normal;
in vec4 passthrough_tangent;
/*
xy = base color UV, zw = normal UV. A second packed attribute carries MR/AO
so every glTF texture can use its own texCoord/texture transform.
*/
in vec4 passthrough_texture_coordinate_0;
in vec4 passthrough_texture_coordinate_1;
in vec4 passthrough_base_color_factor; // @constant_across_object
in vec4 passthrough_material_parameters; // @constant_across_object
in vec2 passthrough_alpha_parameters; // @constant_across_object

// channel 0: base color
in ivec2 passthrough_base_color_texture_binding; // @constant_across_object

// channel 1: normal map
in ivec2 passthrough_normal_texture_binding; // @constant_across_object

// channel 2: metallic roughness (combined)
in ivec2 passthrough_metallic_roughness_texture_binding; // @constant_across_object

// channel 3: ambient occlusion (optional)
in ivec2 passthrough_ambient_occlusion_texture_binding; // @constant_across_object

// outputs to fragment shader

out vec3 world_position;
out vec3 world_normal;
out vec4 world_tangent;
out vec4 texture_coordinate_0;
out vec4 texture_coordinate_1;
flat out vec4 base_color_factor;
flat out vec4 material_parameters;
flat out vec2 alpha_parameters;
out vec4 light_clip_position;

flat out ivec2 base_color_texture_binding;
flat out ivec2 normal_texture_binding;
flat out ivec2 metallic_roughness_texture_binding;
flat out ivec2 ambient_occlusion_texture_binding;

uniform mat4 world_to_camera;
uniform mat4 camera_to_clip;
uniform mat4 world_to_light_clip;

void main() {
    mat4 local_to_world = local_to_world_matrices[local_to_world_index];

    vec4 world_pos4 = local_to_world * vec4(position, 1.0);
    world_position = world_pos4.xyz;

    mat3 tangent_matrix = mat3(local_to_world);
    mat3 normal_matrix = transpose(inverse(tangent_matrix));
    float transform_handedness = determinant(tangent_matrix) < 0.0 ? -1.0 : 1.0;
    world_normal = normalize(normal_matrix * passthrough_normal);
    world_tangent = vec4(
        normalize(tangent_matrix * passthrough_tangent.xyz),
        passthrough_tangent.w * transform_handedness
    );

    texture_coordinate_0 = passthrough_texture_coordinate_0;
    texture_coordinate_1 = passthrough_texture_coordinate_1;
    base_color_factor = passthrough_base_color_factor;
    material_parameters = passthrough_material_parameters;
    alpha_parameters = passthrough_alpha_parameters;
    light_clip_position = world_to_light_clip * world_pos4;

    base_color_texture_binding = passthrough_base_color_texture_binding;
    normal_texture_binding = passthrough_normal_texture_binding;
    metallic_roughness_texture_binding = passthrough_metallic_roughness_texture_binding;
    ambient_occlusion_texture_binding = passthrough_ambient_occlusion_texture_binding;

    gl_Position = camera_to_clip * world_to_camera * world_pos4;
}
