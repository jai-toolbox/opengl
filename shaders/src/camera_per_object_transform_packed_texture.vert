#version 330 core

#include "local_to_world_1024_ubo.glsl"
#include "packed_texture_input_passthrough.glsl"

in vec3 position;

uniform mat4 world_to_camera;
uniform mat4 camera_to_clip;

void main() {
    texture_packer_passthrough(passthrough_texture_coordinate, passthrough_packed_texture_index, passthrough_packed_texture_bounding_box_index, texture_coordinate, packed_texture_index, packed_texture_bounding_box_index);

    gl_Position = camera_to_clip * world_to_camera * local_to_world_matrices[local_to_world_index] * vec4(position, 1.0);
}
