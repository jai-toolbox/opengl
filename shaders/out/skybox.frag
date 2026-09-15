#version 330 core

in vec3 cubemap_direction;

uniform samplerCube skybox_cubemap;

out vec4 frag_color;

void main() {
    frag_color = texture(skybox_cubemap, cubemap_direction);
}
