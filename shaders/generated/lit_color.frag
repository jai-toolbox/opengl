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

in vec3 v_position;
in vec3 v_normal;
in vec3 v_color;

out vec4 out_color;

vec4 run_fragment_shader(Lit_Color_Vertex input) {
    vec3 n = normalize(input.normal);
    vec3 l = normalize(light_direction);
    float diffuse = max(float(0.0), dot(n, l));
    float intensity = min(max((ambient + (diffuse * (1.0 - ambient))), 0.0), 1.0);
    vec3 color = (input.color * intensity);
    return vec4(color.x, color.y, color.z, 1.0);
}

void main() {
    Lit_Color_Vertex input_fragment = Lit_Color_Vertex(v_position, v_normal, v_color);
    out_color = run_fragment_shader(input_fragment);
}
