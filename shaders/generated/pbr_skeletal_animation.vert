#version 330 core
// Generated from Jai procedure mesh_skinned_vertex_shader.
struct Mesh_Transform_Result {
    vec4 position;
    vec3 normal;
    vec3 tangent;
};
struct Mesh_Vertex_Uniforms {
    sampler2D object_transforms;
    mat4 world_to_camera;
    mat4 camera_to_clip;
};
struct Skinned_Mesh_Vertex_Uniforms {
    Mesh_Vertex_Uniforms mesh;
    sampler2D bone_transforms;
};
struct GLSL_Vertex_Shader_Input_Built_In_Variables {
    int vertex_index;
    int instance_index;
};
struct Mesh_Vertex {
    vec3 position;
    vec3 normal;
    vec3 tangent;
    vec2 uv;
    int material_index;
    int local_to_world_index;
    GLSL_Vertex_Shader_Input_Built_In_Variables gpu;
};
struct Skinned_Mesh_Vertex {
    Mesh_Vertex mesh;
    uvec4 bone_indices;
    vec4 bone_weights;
};
in vec3 position;
in vec3 normal;
in vec3 tangent;
in vec2 uv;
in int material_index;
in int local_to_world_index;
in uvec4 bone_indices;
in vec4 bone_weights;
out vec3 passthrough_world_position;
out vec3 passthrough_normal;
out vec3 passthrough_tangent;
out vec2 passthrough_uv;
flat out int passthrough_material_index;
uniform Skinned_Mesh_Vertex_Uniforms vertex_uniforms;

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

Mesh_Transform_Result jai_mesh_skinned_geometry(Skinned_Mesh_Vertex_Uniforms uniforms, Skinned_Mesh_Vertex jai_var_input) {
    vec4 p = jai_mesh_skin(uniforms.bone_transforms, jai_var_input.bone_indices, jai_var_input.bone_weights, vec4(jai_var_input.mesh.position.x, jai_var_input.mesh.position.y, jai_var_input.mesh.position.z, 1.0));
    vec4 n = jai_mesh_skin(uniforms.bone_transforms, jai_var_input.bone_indices, jai_var_input.bone_weights, vec4(jai_var_input.mesh.normal.x, jai_var_input.mesh.normal.y, jai_var_input.mesh.normal.z, 0.0));
    vec4 t = jai_mesh_skin(uniforms.bone_transforms, jai_var_input.bone_indices, jai_var_input.bone_weights, vec4(jai_var_input.mesh.tangent.x, jai_var_input.mesh.tangent.y, jai_var_input.mesh.tangent.z, 0.0));
    p.w = 1.0;
    p = jai_mesh_transform(uniforms.mesh.object_transforms, jai_var_input.mesh.local_to_world_index, p);
    n = jai_mesh_transform(uniforms.mesh.object_transforms, jai_var_input.mesh.local_to_world_index, n);
    t = jai_mesh_transform(uniforms.mesh.object_transforms, jai_var_input.mesh.local_to_world_index, t);
    return Mesh_Transform_Result(p, normalize(vec3(n.x, n.y, n.z)), normalize(vec3(t.x, t.y, t.z)));
}

void main() {
    Skinned_Mesh_Vertex jai_var_input;
    jai_var_input.mesh.position = position;
    jai_var_input.mesh.normal = normal;
    jai_var_input.mesh.tangent = tangent;
    jai_var_input.mesh.uv = uv;
    jai_var_input.mesh.material_index = material_index;
    jai_var_input.mesh.local_to_world_index = local_to_world_index;
    jai_var_input.mesh.gpu.vertex_index = gl_VertexID;
    jai_var_input.mesh.gpu.instance_index = gl_InstanceID;
    jai_var_input.bone_indices = bone_indices;
    jai_var_input.bone_weights = bone_weights;
    Mesh_Transform_Result world = jai_mesh_skinned_geometry(vertex_uniforms, jai_var_input);
    gl_Position = ((vertex_uniforms.mesh.camera_to_clip * vertex_uniforms.mesh.world_to_camera) * world.position);
    passthrough_world_position = vec3(world.position.x, world.position.y, world.position.z);
    passthrough_normal = world.normal;
    passthrough_tangent = world.tangent;
    passthrough_uv = jai_var_input.mesh.uv;
    passthrough_material_index = jai_var_input.mesh.material_index;
}
