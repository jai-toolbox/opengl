#version 330 core

#include "local_to_world_1024_ubo.glsl"
#include "skeletal_animation_100_bones_4_bones_per_vertex.glsl"

uniform mat4 camera_to_clip;
uniform mat4 world_to_camera;

in vec3 position;
in vec3 passthrough_rgb_color;

out vec3 rgb_color;

void main() {

    rgb_color = passthrough_rgb_color;

    // the animation transform contains the entire hierarchical structure for that vertex
    mat4 animation_transform = compute_animation_transform(bone_transform_indices, bone_weights);
    vec4 animated_position = animation_transform * vec4(position, 1.0);

    gl_Position = camera_to_clip * world_to_camera * local_to_world_matrices[local_to_world_index] * animated_position;
}
