#version 330 core

struct Absolute_Position_Color_Vertex {
    vec3 position;
    vec3 color;
};

uniform mat4 transform;

in vec3 v_color;

out vec4 out_color;

vec4 run_fragment_shader(Absolute_Position_Color_Vertex input) {
    return vec4(input.color.x, input.color.y, input.color.z, 1.0);
}

void main() {
    Absolute_Position_Color_Vertex input_fragment = Absolute_Position_Color_Vertex(vec3(0.0), v_color);
    out_color = run_fragment_shader(input_fragment);
}
