#version 330 core

in vec3 position;

out vec3 cubemap_direction;

uniform mat4 world_to_camera;
uniform mat4 camera_to_clip;

void main() {
    cubemap_direction = position;
    vec4 clip_position = camera_to_clip * world_to_camera * vec4(position, 1.0);
    gl_Position = clip_position.xyww;
}
