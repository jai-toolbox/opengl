#version 330 core

#include "local_to_world_1024_ubo.glsl"
#include "skeletal_animation_100_bones_4_bones_per_vertex.glsl"

in vec3 position;
in vec3 passthrough_normal;
in vec3 passthrough_tangent;
in vec2 passthrough_texture_coordinate;
in vec4 passthrough_base_color_factor; // @constant_across_object
in vec2 passthrough_alpha_parameters; // @constant_across_object

in int passthrough_packed_texture_index_for_base_color; // @constant_across_object
in int passthrough_packed_texture_bounding_box_index_for_base_color; // @constant_across_object

in int passthrough_packed_texture_index_for_normal; // @constant_across_object
in int passthrough_packed_texture_bounding_box_index_for_normal; // @constant_across_object

in int passthrough_packed_texture_index_for_metallic_roughness; // @constant_across_object
in int passthrough_packed_texture_bounding_box_index_for_metallic_roughness; // @constant_across_object

in int passthrough_packed_texture_index_for_ambient_occlusion; // @constant_across_object
in int passthrough_packed_texture_bounding_box_index_for_ambient_occlusion; // @constant_across_object

out vec3 world_position;
out vec3 world_normal;
out vec3 world_tangent;
out vec2 texture_coordinate;
flat out vec4 base_color_factor;
flat out vec2 alpha_parameters;
out vec4 light_clip_position;

flat out int packed_texture_index_for_base_color;
flat out int packed_texture_bounding_box_index_for_base_color;

flat out int packed_texture_index_for_normal;
flat out int packed_texture_bounding_box_index_for_normal;

flat out int packed_texture_index_for_metallic_roughness;
flat out int packed_texture_bounding_box_index_for_metallic_roughness;

flat out int packed_texture_index_for_ambient_occlusion;
flat out int packed_texture_bounding_box_index_for_ambient_occlusion;

uniform mat4 world_to_camera;
uniform mat4 camera_to_clip;
uniform mat4 world_to_light_clip;

void main() {
    mat4 animation_transform = compute_animation_transform(bone_transform_indices, bone_weights);
    vec4 animated_position = animation_transform * vec4(position, 1.0);

    mat4 local_to_world = local_to_world_matrices[local_to_world_index];
    vec4 world_pos4 = local_to_world * animated_position;
    world_position = world_pos4.xyz;

    mat3 normal_matrix = mat3(local_to_world) * mat3(animation_transform);
    world_normal  = normalize(normal_matrix * passthrough_normal);
    world_tangent = normalize(normal_matrix * passthrough_tangent);

    texture_coordinate = passthrough_texture_coordinate;
    base_color_factor = passthrough_base_color_factor;
    alpha_parameters = passthrough_alpha_parameters;
    light_clip_position = world_to_light_clip * world_pos4;

    packed_texture_index_for_base_color              = passthrough_packed_texture_index_for_base_color;
    packed_texture_bounding_box_index_for_base_color = passthrough_packed_texture_bounding_box_index_for_base_color;

    packed_texture_index_for_normal              = passthrough_packed_texture_index_for_normal;
    packed_texture_bounding_box_index_for_normal = passthrough_packed_texture_bounding_box_index_for_normal;

    packed_texture_index_for_metallic_roughness              = passthrough_packed_texture_index_for_metallic_roughness;
    packed_texture_bounding_box_index_for_metallic_roughness = passthrough_packed_texture_bounding_box_index_for_metallic_roughness;

    packed_texture_index_for_ambient_occlusion              = passthrough_packed_texture_index_for_ambient_occlusion;
    packed_texture_bounding_box_index_for_ambient_occlusion = passthrough_packed_texture_bounding_box_index_for_ambient_occlusion;

    gl_Position = camera_to_clip * world_to_camera * world_pos4;
}
