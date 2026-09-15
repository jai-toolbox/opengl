#version 330 core

struct Lit_Color_Vertex {
    vec3 position;
    vec3 normal;
    vec3 color;
};

uniform float angle;
uniform vec3 camera_position;
uniform vec3 light_direction;
uniform float ambient;

layout(location = 0) in vec3 position;
layout(location = 1) in vec3 normal;
layout(location = 2) in vec3 color;

out vec3 v_position;
out vec3 v_normal;
out vec3 v_color;

vec3 rotate_lit_color_position(vec3 p, float angle) {
    float cy = cos(angle);
    float sy = sin(angle);
    float cx = cos((angle * 0.63));
    float sx = sin((angle * 0.63));
    vec3 xz = vec3(((p.x * cy) + (p.z * sy)), p.y, ((-p.x * sy) + (p.z * cy)));
    return vec3(xz.x, ((xz.y * cx) - (xz.z * sx)), ((xz.y * sx) + (xz.z * cx)));
}

Lit_Color_Vertex run_vertex_shader(Lit_Color_Vertex input) {
    Lit_Color_Vertex output = input;
    output.position = rotate_lit_color_position(input.position, angle);
    output.position.z += 4.0;
    output.normal = normalize(rotate_lit_color_position(input.normal, angle));
    return output;
}

void main() {
    Lit_Color_Vertex input_vertex = Lit_Color_Vertex(position, normal, color);
    Lit_Color_Vertex output_vertex = run_vertex_shader(input_vertex);
    v_position = output_vertex.position;
    v_normal = output_vertex.normal;
    v_color = output_vertex.color;
    gl_Position = vec4(output_vertex.position.x / output_vertex.position.z, output_vertex.position.y / output_vertex.position.z, output_vertex.position.z / 100.0, 1.0);
}
