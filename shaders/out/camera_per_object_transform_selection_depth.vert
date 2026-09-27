#version 330 core

// Begin include: local_to_world_1024_ubo.glsl
in uint local_to_world_index;

layout(std140, row_major) uniform LtwMatrices {
    mat4 local_to_world_matrices[1024];
};
// End include: local_to_world_1024_ubo.glsl

in vec3 position;

uniform mat4 camera_to_clip;
uniform mat4 world_to_camera;

void main() {
    gl_Position = camera_to_clip
        * world_to_camera
        * local_to_world_matrices[local_to_world_index]
        * vec4(position, 1.0);
}
