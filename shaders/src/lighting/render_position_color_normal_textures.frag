#version 330 core

// these locations specify what color buffer to render to
layout (location = 0) out vec3 position_texture;
layout (location = 1) out vec3 normal_texture;
layout (location = 2) out vec4 color_texture;

in vec3 world_space_position;
in vec3 rgb_color;
in vec3 normal;

void main() {
    position_texture = world_space_position;
    normal_texture = normalize(normal);
    color_texture = vec4(rgb_color, 1);
}
