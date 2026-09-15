#version 330 core

#include "aspect_ratio_correction.glsl";

in vec3 position;

in vec3 passthrough_rgb_color;
out vec3 rgb_color;

void main() {
   rgb_color = passthrough_rgb_color;
   gl_Position = vec4(scale_position_by_aspect_ratio(position, aspect_ratio), 1.0f);
}
