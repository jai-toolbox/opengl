#version 330 core
// Generated from Jai procedure animated_mesh_vertex.
in vec3 position;
in vec3 normal;
in vec2 uv;
in float spacing;
out vec3 passthrough_position_in_world;
out vec3 passthrough_normal;
out vec2 passthrough_uv;
out float passthrough_spacing;
uniform mat4 world_to_clip;

void main() {
    gl_Position = (world_to_clip * vec4(position.x, position.y, position.z, 1.0));
    passthrough_position_in_world = position;
    passthrough_normal = normal;
    passthrough_uv = uv;
    passthrough_spacing = spacing;
}
