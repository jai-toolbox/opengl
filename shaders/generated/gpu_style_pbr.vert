#version 330 core

layout(std140, row_major) uniform LtwMatrices {
    mat4 local_to_world_matrices[1024];
};

uniform mat4 world_to_camera;
uniform mat4 camera_to_clip;

in vec3 position;
in vec3 normal;
in vec3 tangent;
in vec2 uv;
in uint material_index;
in uint local_to_world_index;

out vec3 v_world_position;
out vec3 v_normal;
out vec3 v_tangent;
out vec2 v_uv;
flat out uint v_material_index;

void main() {
    mat4 local_to_world = local_to_world_matrices[local_to_world_index];
    vec4 world_position = local_to_world * vec4(position, 1.0);
    v_world_position = world_position.xyz;
    v_normal = normalize(mat3(local_to_world) * normal);
    v_tangent = normalize(mat3(local_to_world) * tangent);
    v_uv = uv;
    v_material_index = material_index;
    gl_Position = camera_to_clip * world_to_camera * world_position;
}
