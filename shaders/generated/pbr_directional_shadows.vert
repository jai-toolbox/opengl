#version 330 core
// Generated from Jai procedure mesh_vertex_shader.
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
in vec3 position;
in vec3 normal;
in vec3 tangent;
in vec2 uv;
in int material_index;
in int local_to_world_index;
out vec3 passthrough_world_position;
out vec3 passthrough_normal;
out vec3 passthrough_tangent;
out vec2 passthrough_uv;
flat out int passthrough_material_index;
uniform Mesh_Vertex_Uniforms vertex_uniforms;

vec4 jai_mesh_transform(sampler2D table, int index, vec4 value) {
    return vec4(dot(texelFetch(table, ivec2(0, index), 0), value), dot(texelFetch(table, ivec2(1, index), 0), value), dot(texelFetch(table, ivec2(2, index), 0), value), dot(texelFetch(table, ivec2(3, index), 0), value));
}

Mesh_Transform_Result jai_mesh_world_geometry(Mesh_Vertex_Uniforms uniforms, Mesh_Vertex jai_var_input) {
    vec4 p = jai_mesh_transform(uniforms.object_transforms, jai_var_input.local_to_world_index, vec4(jai_var_input.position.x, jai_var_input.position.y, jai_var_input.position.z, 1.0));
    vec4 n = jai_mesh_transform(uniforms.object_transforms, jai_var_input.local_to_world_index, vec4(jai_var_input.normal.x, jai_var_input.normal.y, jai_var_input.normal.z, 0.0));
    vec4 t = jai_mesh_transform(uniforms.object_transforms, jai_var_input.local_to_world_index, vec4(jai_var_input.tangent.x, jai_var_input.tangent.y, jai_var_input.tangent.z, 0.0));
    return Mesh_Transform_Result(p, normalize(vec3(n.x, n.y, n.z)), normalize(vec3(t.x, t.y, t.z)));
}

void main() {
    Mesh_Vertex jai_var_input;
    jai_var_input.position = position;
    jai_var_input.normal = normal;
    jai_var_input.tangent = tangent;
    jai_var_input.uv = uv;
    jai_var_input.material_index = material_index;
    jai_var_input.local_to_world_index = local_to_world_index;
    jai_var_input.gpu.vertex_index = gl_VertexID;
    jai_var_input.gpu.instance_index = gl_InstanceID;
    Mesh_Transform_Result world = jai_mesh_world_geometry(vertex_uniforms, jai_var_input);
    gl_Position = ((vertex_uniforms.camera_to_clip * vertex_uniforms.world_to_camera) * world.position);
    passthrough_world_position = vec3(world.position.x, world.position.y, world.position.z);
    passthrough_normal = world.normal;
    passthrough_tangent = world.tangent;
    passthrough_uv = jai_var_input.uv;
    passthrough_material_index = jai_var_input.material_index;
}
