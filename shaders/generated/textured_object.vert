#version 330 core

in uint local_to_world_index;

layout(std140, row_major) uniform LtwMatrices {
    mat4 local_to_world_matrices[1024];
};

in vec3 position;
in vec3 normal;
// Resource contract:
// The packed texture index selects a sampler2DArray layer. The bounding-box
// index selects a packed source rectangle in packed_texture_bounding_boxes.
// These are material/resource IDs, not interpolated geometry data, and let the
// renderer draw many textured objects without binding a new texture per object.
in int passthrough_packed_texture_index;
in vec2 passthrough_texture_coordinate;
in int passthrough_packed_texture_bounding_box_index;

uniform mat4 world_to_camera;
uniform mat4 camera_to_clip;

out vec3 world_normal;
out vec2 texture_coordinate;
flat out int packed_texture_index;
flat out int packed_texture_bounding_box_index;

void main() {
    texture_coordinate = passthrough_texture_coordinate;
    packed_texture_index = passthrough_packed_texture_index;
    packed_texture_bounding_box_index = passthrough_packed_texture_bounding_box_index;

    mat4 local_to_world = local_to_world_matrices[local_to_world_index];
    vec4 world_position = local_to_world * vec4(position, 1.0);
    world_normal = normalize(mat3(local_to_world) * normal);
    gl_Position = camera_to_clip * world_to_camera * world_position;
}
