#version 330 core
// Generated from Jai procedure shadow_depth_vertex_shader.
in vec3 position;
in vec3 normal;
in vec3 tangent;
in vec2 uv;
in int material_index;
in int local_to_world_index;
uniform sampler2D object_transforms;
uniform mat4 world_to_light_clip;

vec4 jai_mesh_transform(sampler2D table, int index, vec4 value) {
    return vec4(dot(texelFetch(table, ivec2(0, index), 0), value), dot(texelFetch(table, ivec2(1, index), 0), value), dot(texelFetch(table, ivec2(2, index), 0), value), dot(texelFetch(table, ivec2(3, index), 0), value));
}

void main() {
    vec4 world = jai_mesh_transform(object_transforms, local_to_world_index, vec4(position.x, position.y, position.z, 1.0));
    gl_Position = (world_to_light_clip * world);
}
