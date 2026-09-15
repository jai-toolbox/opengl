#version 330

in vec3 position;
in vec4 passthrough_rgba_color;

uniform mat4 transform;

out vec4 rgba_color;

void main() {
    rgba_color = passthrough_rgba_color;
    gl_Position = transform * vec4(position, 1.0);
}
