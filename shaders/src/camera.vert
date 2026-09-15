#version 330 core
layout (location = 0) in vec3 position;
uniform mat4 world_to_camera;
uniform mat4 camera_to_clip;

void main() {
    gl_Position = camera_to_clip * world_to_camera * vec4(position, 1.0);
}
