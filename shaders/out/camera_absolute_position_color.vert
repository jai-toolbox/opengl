#version 330 core

in vec3 position;

in vec3 passthrough_rgb_color;
out vec3 rgb_color;

uniform mat4 world_to_camera;
uniform mat4 camera_to_clip;

void main() {
    rgb_color = passthrough_rgb_color;
    gl_Position = camera_to_clip * world_to_camera * vec4(position, 1.0);
}
