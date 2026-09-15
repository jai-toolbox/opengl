#version 330 core

in vec3 rgb_color;

out vec4 frag_color;

void main() {
    frag_color = vec4(rgb_color, 1.0);
}
