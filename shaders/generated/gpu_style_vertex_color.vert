#version 330 core

layout(std140, row_major) uniform LtwMatrices {
    mat4 local_to_world_matrices[1024];
};

uniform mat4 world_to_camera;
uniform mat4 camera_to_clip;

in vec3 position;
in vec3 color;
in uint local_to_world_index;

out vec3 v_color;

void main() {
    mat4 local_to_world = local_to_world_matrices[local_to_world_index];
    vec4 world_position = local_to_world * vec4(position, 1.0);
    v_color = color;
    gl_Position = camera_to_clip * world_to_camera * world_position;
}
