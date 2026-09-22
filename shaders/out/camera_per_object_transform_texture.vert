#version 330 core

// Begin include: local_to_world_1024_ubo.glsl
in uint local_to_world_index;

layout(std140, row_major) uniform LtwMatrices {
    mat4 local_to_world_matrices[1024];
};
// End include: local_to_world_1024_ubo.glsl

in vec3 position;
in vec2 passthrough_texture_coordinate;
out vec2 texture_coordinate;

uniform mat4 world_to_camera;
uniform mat4 camera_to_clip;

void main() {
    texture_coordinate = passthrough_texture_coordinate;
    gl_Position = camera_to_clip * world_to_camera * local_to_world_matrices[local_to_world_index] * vec4(position, 1.0);
}
