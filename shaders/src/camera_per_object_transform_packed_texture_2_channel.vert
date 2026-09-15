#version 330 core

#include "local_to_world_1024_ubo.glsl"
#include "packed_texture_input_passthrough_2_channel.glsl"

in vec3 position;

uniform mat4 world_to_camera;
uniform mat4 camera_to_clip;

void main() {

    packed_texture_passthrough(
        passthrough_texture_coordinate_0, passthrough_packed_texture_index_0, passthrough_packed_texture_bounding_box_index_0,
        texture_coordinate_0, packed_texture_index_0, packed_texture_bounding_box_index_0,

        passthrough_texture_coordinate_1, passthrough_packed_texture_index_1, passthrough_packed_texture_bounding_box_index_1,
        texture_coordinate_1, packed_texture_index_1, packed_texture_bounding_box_index_1
    );

    gl_Position = camera_to_clip * world_to_camera * local_to_world_matrices[local_to_world_index] * vec4(position, 1.0);
}
