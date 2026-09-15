#version 330

in vec3 position;
in vec2 passthrough_texture_coordinate;

out vec2 texture_coordinate;

uniform mat4 transform;

void main() {
    texture_coordinate = passthrough_texture_coordinate;
    gl_Position = transform * vec4(position, 1.0);
}

