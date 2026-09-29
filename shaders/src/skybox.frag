#version 330 core

in vec3 cubemap_direction;

uniform samplerCube skybox_cubemap;
uniform float exposure;

out vec4 frag_color;

void main() {
    vec3 color = texture(skybox_cubemap, cubemap_direction).rgb;
    color = max(color, vec3(0.0));
    color *= exposure;
    color = color / (color + vec3(1.0));
    color = pow(color, vec3(1.0 / 2.2));
    frag_color = vec4(color, 1.0);
}
