#version 330 core

in vec3 rgb_color;

out vec4 frag_color;

void main() {

    // make circular points instead of square
    vec2 coord = gl_PointCoord * 2.0 - 1.0;
    if (dot(coord, coord) > 1.0)
        discard;

    frag_color = vec4(rgb_color, 1.0);
}
