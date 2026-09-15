#version 330 core

layout(std140, row_major) uniform LtwMatrices {
    mat4 local_to_world_matrices[1024];
};

uniform mat4 world_to_light_clip;

in vec3 position;
in uint local_to_world_index;

void main() {
    mat4 local_to_world = local_to_world_matrices[local_to_world_index];
    vec4 world_position = local_to_world * vec4(position, 1.0);
    gl_Position = world_to_light_clip * world_position;
}
