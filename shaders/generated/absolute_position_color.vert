#version 330 core

struct Absolute_Position_Color_Vertex {
    vec3 position;
    vec3 color;
};

uniform mat4 transform;

layout(location = 0) in vec3 position;
layout(location = 1) in vec3 color;

out vec3 v_color;

Absolute_Position_Color_Vertex run_vertex_shader(Absolute_Position_Color_Vertex input) {
    Absolute_Position_Color_Vertex output = input;
    vec4 p = (transform * vec4(input.position.x, input.position.y, input.position.z, 1.0));
    output.position = vec3(p.x, p.y, p.z);
    return output;
}

void main() {
    Absolute_Position_Color_Vertex input_vertex = Absolute_Position_Color_Vertex(position, color);
    Absolute_Position_Color_Vertex output_vertex = run_vertex_shader(input_vertex);
    v_color = output_vertex.color;
    gl_Position = vec4(output_vertex.position, 1.0);
}
