#version 330

in vec3 position;
in vec4 passthrough_rgba_color;

uniform mat4 camera_to_clip;
uniform mat4 world_to_camera;

#include "local_to_world_1024_ubo.glsl"

out vec4 rgba_color;

void main() {
    rgba_color = passthrough_rgba_color;
    gl_Position = camera_to_clip * world_to_camera * local_to_world_matrices[local_to_world_index] * vec4(position, 1.0);
}
