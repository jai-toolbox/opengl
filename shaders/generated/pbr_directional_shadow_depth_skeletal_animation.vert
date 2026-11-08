#version 330 core
// Generated from Jai procedure shadow_depth_skinned_vertex_shader.
struct Shadow_Vertex_Uniforms {
    sampler2D object_transforms;
    mat4 world_to_light_clip;
};
in vec3 position;
in vec3 normal;
in vec3 tangent;
in vec2 uv;
in int material_index;
in int local_to_world_index;
in uvec4 bone_indices;
in vec4 bone_weights;
uniform Shadow_Vertex_Uniforms shadow;
uniform sampler2D bone_transforms;

vec4 jai_mesh_transform(sampler2D table, int index, vec4 value) {
    return vec4(dot(texelFetch(table, ivec2(0, index), 0), value), dot(texelFetch(table, ivec2(1, index), 0), value), dot(texelFetch(table, ivec2(2, index), 0), value), dot(texelFetch(table, ivec2(3, index), 0), value));
}

vec4 jai_mesh_skin_contribution(sampler2D table, uint index, float weight, vec4 value) {
    if (((index >= 100u) || (weight <= 0.0))) {
        return vec4(0.0);
    }
    return (jai_mesh_transform(table, int(index), value) * weight);
}

vec4 jai_mesh_skin(sampler2D table, uvec4 indices, vec4 weights, vec4 value) {
    float total = 0.0;
    if (((indices.x < 100u) && (weights.x > 0.0))) {
        total += weights.x;
    }
    if (((indices.y < 100u) && (weights.y > 0.0))) {
        total += weights.y;
    }
    if (((indices.z < 100u) && (weights.z > 0.0))) {
        total += weights.z;
    }
    if (((indices.w < 100u) && (weights.w > 0.0))) {
        total += weights.w;
    }
    if ((total <= 0.0)) {
        return value;
    }
    return (((jai_mesh_skin_contribution(table, indices.x, weights.x, value) + jai_mesh_skin_contribution(table, indices.y, weights.y, value)) + jai_mesh_skin_contribution(table, indices.z, weights.z, value)) + jai_mesh_skin_contribution(table, indices.w, weights.w, value));
}

void main() {
    vec4 local = jai_mesh_skin(bone_transforms, bone_indices, bone_weights, vec4(position.x, position.y, position.z, 1.0));
    local.w = 1.0;
    vec4 world = jai_mesh_transform(shadow.object_transforms, local_to_world_index, local);
    gl_Position = (shadow.world_to_light_clip * world);
}
