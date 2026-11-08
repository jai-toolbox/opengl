#version 330 core
// Generated from Jai procedure lightmapped_mesh_vertex_shader.
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
struct Lightmapped_Mesh_Vertex {
    Mesh_Vertex mesh;
    vec2 lightmap_uv;
};
in vec3 position;
in vec3 normal;
in vec3 tangent;
in vec2 uv;
in int material_index;
in int local_to_world_index;
in vec2 lightmap_uv;
out vec3 passthrough_world_position;
out vec3 passthrough_normal;
out vec3 passthrough_tangent;
out vec2 passthrough_uv;
flat out int passthrough_material_index;
out vec2 passthrough_lightmap_uv;
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
    Lightmapped_Mesh_Vertex jai_var_input;
    jai_var_input.mesh.position = position;
    jai_var_input.mesh.normal = normal;
    jai_var_input.mesh.tangent = tangent;
    jai_var_input.mesh.uv = uv;
    jai_var_input.mesh.material_index = material_index;
    jai_var_input.mesh.local_to_world_index = local_to_world_index;
    jai_var_input.mesh.gpu.vertex_index = gl_VertexID;
    jai_var_input.mesh.gpu.instance_index = gl_InstanceID;
    jai_var_input.lightmap_uv = lightmap_uv;
    Mesh_Transform_Result world = jai_mesh_world_geometry(vertex_uniforms, jai_var_input.mesh);
    gl_Position = ((vertex_uniforms.camera_to_clip * vertex_uniforms.world_to_camera) * world.position);
    passthrough_world_position = vec3(world.position.x, world.position.y, world.position.z);
    passthrough_normal = world.normal;
    passthrough_tangent = world.tangent;
    passthrough_uv = jai_var_input.mesh.uv;
    passthrough_material_index = jai_var_input.mesh.material_index;
    passthrough_lightmap_uv = jai_var_input.lightmap_uv;
}
