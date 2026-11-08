// auto-generated renderer for shader: Pbr_Directional_Shadow_Depth_Skeletal_Animation
// do not edit manually.

Pbr_Directional_Shadow_Depth_Skeletal_Animation_Shadow_Vertex_Uniforms_Bindings :: struct {
    object_transforms: GLuint;
    world_to_light_clip: Matrix4;
}

Pbr_Directional_Shadow_Depth_Skeletal_Animation_Skinned_Shadow_Vertex_Uniforms_Bindings :: struct {
    shadow: Pbr_Directional_Shadow_Depth_Skeletal_Animation_Shadow_Vertex_Uniforms_Bindings;
    bone_transforms: GLuint;
}


Pbr_Directional_Shadow_Depth_Skeletal_Animation_Renderable :: struct {
    indices : [..] u32;
    object_index : u32;

    positions: [..] Vector3;
    normals: [..] Vector3;
    tangents: [..] Vector3;
    uvs: [..] Vector2;
    material_indices: [..] s32;
    local_to_world_indices: [..] s32;
    bone_indices: [..] Shader_UInt4;
    bone_weights: [..] Vector4;

}


Pbr_Directional_Shadow_Depth_Skeletal_Animation_Geometry :: struct {
    indices : [..] u32;
    positions: [..] Vector3;
    normals: [..] Vector3;
    tangents: [..] Vector3;
    uvs: [..] Vector2;
    material_indices: [..] s32;
    local_to_world_indices: [..] s32;
    bone_indices: [..] Shader_UInt4;
    bone_weights: [..] Vector4;
}

assign_geometry_copy :: (renderable: *Pbr_Directional_Shadow_Depth_Skeletal_Animation_Renderable, geometry: $T/interface Pbr_Directional_Shadow_Depth_Skeletal_Animation_Geometry) {
    array_copy(*renderable.indices, geometry.indices);
    array_copy(*renderable.positions, geometry.positions);
    array_copy(*renderable.normals, geometry.normals);
    array_copy(*renderable.tangents, geometry.tangents);
    array_copy(*renderable.uvs, geometry.uvs);
    array_copy(*renderable.material_indices, geometry.material_indices);
    array_copy(*renderable.local_to_world_indices, geometry.local_to_world_indices);
    array_copy(*renderable.bone_indices, geometry.bone_indices);
    array_copy(*renderable.bone_weights, geometry.bone_weights);
}

assign_geometry :: (renderable: *Pbr_Directional_Shadow_Depth_Skeletal_Animation_Renderable, geometry: $T/interface Pbr_Directional_Shadow_Depth_Skeletal_Animation_Geometry) {
    renderable.indices = geometry.indices;
    renderable.positions = geometry.positions;
    renderable.normals = geometry.normals;
    renderable.tangents = geometry.tangents;
    renderable.uvs = geometry.uvs;
    renderable.material_indices = geometry.material_indices;
    renderable.local_to_world_indices = geometry.local_to_world_indices;
    renderable.bone_indices = geometry.bone_indices;
    renderable.bone_weights = geometry.bone_weights;
}


deinit :: (renderable: *Pbr_Directional_Shadow_Depth_Skeletal_Animation_Renderable) {
    array_free(renderable.indices);
    array_free(renderable.positions);
    array_free(renderable.normals);
    array_free(renderable.tangents);
    array_free(renderable.uvs);
    array_free(renderable.material_indices);
    array_free(renderable.local_to_world_indices);
    array_free(renderable.bone_indices);
    array_free(renderable.bone_weights);
}

/*

so deinit exists but also unbuffer object exists, the difference is that deinit takes in a renderable and frees its CPU-side arrays and resets its transform slot, whereas unbuffer_object only frees the GPU-side virtual allocation, leaving the CPU data intact for potential re-buffering later.

*/
deinit :: (renderable: *Pbr_Directional_Shadow_Depth_Skeletal_Animation_Renderable, renderer: *Pbr_Directional_Shadow_Depth_Skeletal_Animation_Renderer) {
    unbuffer_object(*renderer.psr, renderable.object_index);
    array_free(renderable.indices);
    array_free(renderable.positions);
    array_free(renderable.normals);
    array_free(renderable.tangents);
    array_free(renderable.uvs);
    array_free(renderable.material_indices);
    array_free(renderable.local_to_world_indices);
    array_free(renderable.bone_indices);
    array_free(renderable.bone_weights);
}


unbuffer_object :: (renderer: *Pbr_Directional_Shadow_Depth_Skeletal_Animation_Renderer, renderable: *Pbr_Directional_Shadow_Depth_Skeletal_Animation_Renderable) {
    unbuffer_object(*renderer.psr, renderable.object_index);
    renderable.object_index = 0;
}


queue_render :: (using renderer: *Pbr_Directional_Shadow_Depth_Skeletal_Animation_Renderer, renderable: Pbr_Directional_Shadow_Depth_Skeletal_Animation_Renderable) {
    queue_render(*renderer.psr, renderable.object_index);
}

// Indices are relative to this buffered object's first vertex.
update_object_indices :: (renderer : *Pbr_Directional_Shadow_Depth_Skeletal_Animation_Renderer, object_index : u32, indices : [] u32) -> bool {
    return update_object_indices(*renderer.psr, object_index, indices);
}

update_object_indices :: (renderer : *Pbr_Directional_Shadow_Depth_Skeletal_Animation_Renderer, renderable : $T/interface Pbr_Directional_Shadow_Depth_Skeletal_Animation_Renderable, indices : [] u32) -> bool {
    return update_object_indices(renderer, renderable.object_index, indices);
}

queue_render :: (renderer : *Pbr_Directional_Shadow_Depth_Skeletal_Animation_Renderer, object_index : u32) {
    queue_render(*renderer.psr, object_index);
}


unbuffer_object :: (renderer : *Pbr_Directional_Shadow_Depth_Skeletal_Animation_Renderer, object_index : u32) {
    unbuffer_object(*renderer.psr, object_index);
}

buffer_object :: (renderer : *Pbr_Directional_Shadow_Depth_Skeletal_Animation_Renderer, vertices : [] Skinned_Mesh_Vertex, indices : [] u32) -> (object_index : u32, success : bool) {
    positions : [..] Vector3;
    defer array_free(positions);
    normals : [..] Vector3;
    defer array_free(normals);
    tangents : [..] Vector3;
    defer array_free(tangents);
    uvs : [..] Vector2;
    defer array_free(uvs);
    material_indices : [..] s32;
    defer array_free(material_indices);
    local_to_world_indices : [..] s32;
    defer array_free(local_to_world_indices);
    bone_indices : [..] Shader_UInt4;
    defer array_free(bone_indices);
    bone_weights : [..] Vector4;
    defer array_free(bone_weights);
    for vertex : vertices {
        array_add(*positions, vertex.mesh.position);
        array_add(*normals, vertex.mesh.normal);
        array_add(*tangents, vertex.mesh.tangent);
        array_add(*uvs, vertex.mesh.uv);
        array_add(*material_indices, vertex.mesh.material_index);
        array_add(*local_to_world_indices, vertex.mesh.local_to_world_index);
        array_add(*bone_indices, vertex.bone_indices);
        array_add(*bone_weights, vertex.bone_weights);
    }
    buffered_index, buffered := buffer_object(renderer, indices, positions, normals, tangents, uvs, material_indices, local_to_world_indices, bone_indices, bone_weights);
    return buffered_index, buffered;
}


Pbr_Directional_Shadow_Depth_Skeletal_Animation_Renderer :: struct {
    using #as psr : Per_Shader_Renderer = .{max_num_elements_in_each_buffer = 100000};


    typed_0_uniform_location : GLint = -1;
    typed_1_uniform_location : GLint = -1;
    typed_2_uniform_location : GLint = -1;

    positions_buffer_gl_handle: GLuint;
    normals_buffer_gl_handle: GLuint;
    tangents_buffer_gl_handle: GLuint;
    uvs_buffer_gl_handle: GLuint;
    material_indices_buffer_gl_handle: GLuint;
    local_to_world_indices_buffer_gl_handle: GLuint;
    bone_indices_buffer_gl_handle: GLuint;
    bone_weights_buffer_gl_handle: GLuint;


}

set_uniforms :: (renderer: *Pbr_Directional_Shadow_Depth_Skeletal_Animation_Renderer, ctx: Pbr_Directional_Shadow_Depth_Skeletal_Animation_Skinned_Shadow_Vertex_Uniforms_Bindings) {
    gl_set_active_shader_program(renderer.shader_program_gl_handle);
    gl_set_active_texture_unit(GL_TEXTURE0 + 0);
    gl_bind_texture_to_binding_target_of_active_texture_unit(GL_TEXTURE_2D,ctx.shadow.object_transforms);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_0_uniform_location,0);
    gl_set_uniform_matrix_4fv_on_active_shader_program(renderer.typed_1_uniform_location, 1, GL_TRUE, *ctx.shadow.world_to_light_clip.coef[0][0]);
    gl_set_active_texture_unit(GL_TEXTURE0 + 1);
    gl_bind_texture_to_binding_target_of_active_texture_unit(GL_TEXTURE_2D,ctx.bone_transforms);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_2_uniform_location,1);
    gl_set_active_texture_unit(GL_TEXTURE0);
    gl_clear_active_shader_program();
}


init :: (using renderer : *Pbr_Directional_Shadow_Depth_Skeletal_Animation_Renderer) -> bool {
    vertex_shader_source := Pbr_Directional_Shadow_Depth_Skeletal_Animation_Vertex_Source;
    fragment_shader_source := Pbr_Directional_Shadow_Depth_Skeletal_Animation_Fragment_Source;

    if !init(*renderer.psr, vertex_shader_source, fragment_shader_source, max_num_elements_in_each_buffer) return false;
    init_buffers_no_data(renderer);


    typed_0_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "shadow.object_transforms");
    typed_1_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "shadow.world_to_light_clip");
    typed_2_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "bone_transforms");

    return true;
}


deinit :: (using renderer : *Pbr_Directional_Shadow_Depth_Skeletal_Animation_Renderer) {
    deinit(*psr);

    gl_delete_buffer(positions_buffer_gl_handle);
    gl_delete_buffer(normals_buffer_gl_handle);
    gl_delete_buffer(tangents_buffer_gl_handle);
    gl_delete_buffer(uvs_buffer_gl_handle);
    gl_delete_buffer(material_indices_buffer_gl_handle);
    gl_delete_buffer(local_to_world_indices_buffer_gl_handle);
    gl_delete_buffer(bone_indices_buffer_gl_handle);
    gl_delete_buffer(bone_weights_buffer_gl_handle);
}



init_buffers_no_data :: (using apcr : *Pbr_Directional_Shadow_Depth_Skeletal_Animation_Renderer) { // todo change renderer name

    vertex_attribute_array_gl_handle = gl_create_vertex_array();
    gl_bind_vertex_array(vertex_attribute_array_gl_handle);



    index_buffer_gl_handle = gl_create_buffer();
    gl_bind_buffer_to_binding_target(GL_ELEMENT_ARRAY_BUFFER, index_buffer_gl_handle);
    // note: it's probably wrong to use  max_num_elements_in_each_buffer because as noted before the number of indices
    // could be larger than this value if we try and render all objects, but we won't care about that until it's a problem.
    gl_allocate_storage_for_buffer_bound_to_binding_target(GL_ELEMENT_ARRAY_BUFFER, size_of(u32) * max_num_elements_in_each_buffer, null, GL_DYNAMIC_DRAW);
    index_buffer_capacity_in_indices = cast(int) max_num_elements_in_each_buffer;
    // note: we don't have to init the vertex attribute for indices because they used in the shader program for rendering, they're just used during glDrawElements.

    generate_buffer_for_vertex_attribute(*positions_buffer_gl_handle, Vector3, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, positions_buffer_gl_handle, "position", 3, GL_FLOAT, GL_FALSE, 0, null);

    generate_buffer_for_vertex_attribute(*normals_buffer_gl_handle, Vector3, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, normals_buffer_gl_handle, "normal", 3, GL_FLOAT, GL_FALSE, 0, null);

    generate_buffer_for_vertex_attribute(*tangents_buffer_gl_handle, Vector3, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, tangents_buffer_gl_handle, "tangent", 3, GL_FLOAT, GL_FALSE, 0, null);

    generate_buffer_for_vertex_attribute(*uvs_buffer_gl_handle, Vector2, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, uvs_buffer_gl_handle, "uv", 2, GL_FLOAT, GL_FALSE, 0, null);

    generate_buffer_for_vertex_attribute(*material_indices_buffer_gl_handle, s32, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, material_indices_buffer_gl_handle, "material_index", 1, GL_INT, GL_FALSE, 0, null);

    generate_buffer_for_vertex_attribute(*local_to_world_indices_buffer_gl_handle, s32, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, local_to_world_indices_buffer_gl_handle, "local_to_world_index", 1, GL_INT, GL_FALSE, 0, null);

    generate_buffer_for_vertex_attribute(*bone_indices_buffer_gl_handle, Shader_UInt4, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, bone_indices_buffer_gl_handle, "bone_indices", 4, GL_UNSIGNED_INT, GL_FALSE, 0, null);

    generate_buffer_for_vertex_attribute(*bone_weights_buffer_gl_handle, Vector4, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, bone_weights_buffer_gl_handle, "bone_weights", 4, GL_FLOAT, GL_FALSE, 0, null);



	gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, 0);
}


buffer_object :: (
    using renderer : *Pbr_Directional_Shadow_Depth_Skeletal_Animation_Renderer,
    renderable : *$T/interface Pbr_Directional_Shadow_Depth_Skeletal_Animation_Renderable,
    budgeter: *GL_Budgeter = null,
) -> success: bool {


    object_index, success := buffer_object(renderer,
            renderable.indices,

            renderable.positions,
            renderable.normals,
            renderable.tangents,
            renderable.uvs,
            renderable.material_indices,
            renderable.local_to_world_indices,
            renderable.bone_indices,
            renderable.bone_weights,
            budgeter
    );

    if success {
        renderable.object_index = object_index;

    };
    return success;
}

// todo ability to specify the transform matrix upon buffering?
buffer_object :: (
        using renderer: *Pbr_Directional_Shadow_Depth_Skeletal_Animation_Renderer,
        indices : [] u32,
        positions : [] Vector3,
        normals : [] Vector3,
        tangents : [] Vector3,
        uvs : [] Vector2,
        material_indices : [] s32,
        local_to_world_indices : [] s32,
        bone_indices : [] Shader_UInt4,
        bone_weights : [] Vector4,

        budgeter: *GL_Budgeter = null

        ) -> object_index: u32, success: bool {

    /*
    note: we use the positions as count, becaues that is the actual data that needs to be in the buffer
    the indices use duplicates sometimes to refer to the same vertex multiple times.
    */
    length := positions.count;
    if length == 0 { return 0, false; }
    index, success := allocate_buffered_object(*renderer.psr, cast(u32) length, indices);
    if !success {
        log("ran out of virtual memory");
        return 0, false;
    }



    gl_bind_vertex_array(vertex_attribute_array_gl_handle);


    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, positions_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(budgeter, GL_ARRAY_BUFFER, index * size_of(Vector3), positions.count * size_of(Vector3), positions.data);



    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, normals_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(budgeter, GL_ARRAY_BUFFER, index * size_of(Vector3), normals.count * size_of(Vector3), normals.data);



    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, tangents_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(budgeter, GL_ARRAY_BUFFER, index * size_of(Vector3), tangents.count * size_of(Vector3), tangents.data);



    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, uvs_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(budgeter, GL_ARRAY_BUFFER, index * size_of(Vector2), uvs.count * size_of(Vector2), uvs.data);



    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, material_indices_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(budgeter, GL_ARRAY_BUFFER, index * size_of(s32), material_indices.count * size_of(s32), material_indices.data);



    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, local_to_world_indices_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(budgeter, GL_ARRAY_BUFFER, index * size_of(s32), local_to_world_indices.count * size_of(s32), local_to_world_indices.data);



    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, bone_indices_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(budgeter, GL_ARRAY_BUFFER, index * size_of(Shader_UInt4), bone_indices.count * size_of(Shader_UInt4), bone_indices.data);



    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, bone_weights_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(budgeter, GL_ARRAY_BUFFER, index * size_of(Vector4), bone_weights.count * size_of(Vector4), bone_weights.data);




    gl_bind_vertex_array(0);

    return index, true;
}

/*

so this function is kinda sketchy right now, you can only rebuffer an object if it takes up the exact same size,
if you're rebuffering things and using up more space then you did before you'll start having undefined behavior in rendering and things
will go off the rails.

*/
rebuffer_object :: (using renderer : *Pbr_Directional_Shadow_Depth_Skeletal_Animation_Renderer, renderable : $T/interface Pbr_Directional_Shadow_Depth_Skeletal_Animation_Renderable) {

    gl_bind_vertex_array(vertex_attribute_array_gl_handle);

    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, positions_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, renderable.object_index * size_of(Vector3), renderable.positions.count * size_of(Vector3), renderable.positions.data);

    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, normals_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, renderable.object_index * size_of(Vector3), renderable.normals.count * size_of(Vector3), renderable.normals.data);

    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, tangents_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, renderable.object_index * size_of(Vector3), renderable.tangents.count * size_of(Vector3), renderable.tangents.data);

    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, uvs_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, renderable.object_index * size_of(Vector2), renderable.uvs.count * size_of(Vector2), renderable.uvs.data);

    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, material_indices_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, renderable.object_index * size_of(s32), renderable.material_indices.count * size_of(s32), renderable.material_indices.data);

    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, local_to_world_indices_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, renderable.object_index * size_of(s32), renderable.local_to_world_indices.count * size_of(s32), renderable.local_to_world_indices.data);

    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, bone_indices_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, renderable.object_index * size_of(Shader_UInt4), renderable.bone_indices.count * size_of(Shader_UInt4), renderable.bone_indices.data);

    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, bone_weights_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, renderable.object_index * size_of(Vector4), renderable.bone_weights.count * size_of(Vector4), renderable.bone_weights.data);


    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, 0);
    gl_bind_vertex_array(0);
}

render :: (using renderer : *Pbr_Directional_Shadow_Depth_Skeletal_Animation_Renderer, primitive_mode: GLenum = GL_TRIANGLES) {

    // todo think about if we should be using temporary storage.

    gl_set_active_shader_program(shader_program_gl_handle);



    gl_bind_vertex_array(vertex_attribute_array_gl_handle);
    index_count := prepare_index_buffer_for_queued_objects(*renderer.psr);
    gl_draw_indexed_vertices_from_bound_vertex_array(
        primitive_mode,
        index_count,
        GL_UNSIGNED_INT,
        cast(*void) 0);
    array_reset(*object_indices_to_render_this_frame);

    gl_bind_vertex_array(0);
    gl_clear_active_shader_program();
}

Pbr_Directional_Shadow_Depth_Skeletal_Animation_Vertex_Source :: #string END_Pbr_Directional_Shadow_Depth_Skeletal_Animation_Vertex_Source
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

END_Pbr_Directional_Shadow_Depth_Skeletal_Animation_Vertex_Source

Pbr_Directional_Shadow_Depth_Skeletal_Animation_Fragment_Source :: #string END_Pbr_Directional_Shadow_Depth_Skeletal_Animation_Fragment_Source
#version 330 core
// Generated from Jai procedure shadow_depth_fragment_shader.
layout(location=0) out vec4 gpu_rendering_pipeline_stage_attachment_color;

void main() {
    gpu_rendering_pipeline_stage_attachment_color = vec4(0.0, 0.0, 0.0, 1.0);
}

END_Pbr_Directional_Shadow_Depth_Skeletal_Animation_Fragment_Source
