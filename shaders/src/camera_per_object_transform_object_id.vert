#version 330

in uint passthrough_object_id; // @constant_across_object
in vec3 position;

uniform mat4 camera_to_clip;
uniform mat4 world_to_camera;
// measured in pixels (todo rename)
uniform float point_size = 12.0;

#include "local_to_world_1024_ubo.glsl"


flat out uint object_id;

void main() {
    object_id = passthrough_object_id;
    gl_Position = camera_to_clip * world_to_camera * local_to_world_matrices[local_to_world_index] * vec4(position, 1.0);
    gl_PointSize = point_size;
}
