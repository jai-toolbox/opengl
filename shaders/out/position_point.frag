#version 330 core

uniform vec3 point_color = vec3(1.0, 1.0, 1.0);

out vec4 frag_color;

void main() {

    // make circular points instead of square
    vec2 coord = gl_PointCoord * 2.0 - 1.0;
    if (dot(coord, coord) > 1.0)
        discard;

    frag_color = vec4(point_color, 1.0);
}
