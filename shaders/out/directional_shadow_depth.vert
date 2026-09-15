#version 330 core

// Begin include: local_to_world_1024_ubo.glsl
in uint local_to_world_index;

layout(std140, row_major) uniform LtwMatrices {
    mat4 local_to_world_matrices[1024];
};
// End include: local_to_world_1024_ubo.glsl

in vec3 position;

uniform mat4 world_to_light_clip;

void main() {
    mat4 local_to_world = local_to_world_matrices[local_to_world_index];
    gl_Position = world_to_light_clip * local_to_world * vec4(position, 1.0);
}
