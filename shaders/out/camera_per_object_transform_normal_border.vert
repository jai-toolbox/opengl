#version 330

in vec3 position;
in vec3 normal;

uniform mat4 camera_to_clip;
uniform mat4 world_to_camera;

uniform float border_thickness;

// Begin include: local_to_world_1024_ubo.glsl
in uint local_to_world_index;

layout(std140, row_major) uniform LtwMatrices {
    mat4 local_to_world_matrices[1024];
};
// End include: local_to_world_1024_ubo.glsl

void main() {
    gl_Position = camera_to_clip * world_to_camera * local_to_world_matrices[local_to_world_index] * vec4(position + normal * border_thickness, 1.0);
}
