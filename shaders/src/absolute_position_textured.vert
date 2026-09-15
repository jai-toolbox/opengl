#version 330 core

in vec3 position;
in vec2 passthrough_texture_coordinate;
in vec4 passthrough_rgba_color;

out vec2 texture_coordinate;
out vec4 rgba_color;

#include "aspect_ratio_correction.glsl"

void main() {
    texture_coordinate = passthrough_texture_coordinate;
    rgba_color = passthrough_rgba_color;
    gl_Position = vec4(scale_position_by_aspect_ratio(position, aspect_ratio), 1.0f);
}
