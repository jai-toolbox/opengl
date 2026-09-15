#version 330 core

#include "aspect_ratio_correction.glsl";

in vec3 position;

in vec4 passthrough_rgba_color;
out vec4 rgba_color;

void main() {
   rgba_color = passthrough_rgba_color;
   gl_Position = vec4(scale_position_by_aspect_ratio(position, aspect_ratio), 1.0f);
}
