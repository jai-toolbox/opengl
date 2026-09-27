#version 330 core

#include "local_to_world_1024_ubo.glsl"

in vec3 position;

uniform mat4 camera_to_clip;
uniform mat4 world_to_camera;

void main() {
    gl_Position = camera_to_clip
        * world_to_camera
        * local_to_world_matrices[local_to_world_index]
        * vec4(position, 1.0);
}
