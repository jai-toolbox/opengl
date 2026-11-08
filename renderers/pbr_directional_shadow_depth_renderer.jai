// auto-generated renderer for shader: Pbr_Directional_Shadow_Depth
// do not edit manually.

Pbr_Directional_Shadow_Depth_Shadow_Vertex_Uniforms_Bindings :: struct {
    object_transforms: GLuint;
    world_to_light_clip: Matrix4;
}


Pbr_Directional_Shadow_Depth_Renderable :: struct {
    indices : [..] u32;
    object_index : u32;

    positions: [..] Vector3;
    normals: [..] Vector3;
    tangents: [..] Vector3;
    uvs: [..] Vector2;
    material_indices: [..] s32;
    local_to_world_indices: [..] s32;

}


Pbr_Directional_Shadow_Depth_Geometry :: struct {
    indices : [..] u32;
    positions: [..] Vector3;
    normals: [..] Vector3;
    tangents: [..] Vector3;
    uvs: [..] Vector2;
    material_indices: [..] s32;
    local_to_world_indices: [..] s32;
}

assign_geometry_copy :: (renderable: *Pbr_Directional_Shadow_Depth_Renderable, geometry: $T/interface Pbr_Directional_Shadow_Depth_Geometry) {
    array_copy(*renderable.indices, geometry.indices);
    array_copy(*renderable.positions, geometry.positions);
    array_copy(*renderable.normals, geometry.normals);
    array_copy(*renderable.tangents, geometry.tangents);
    array_copy(*renderable.uvs, geometry.uvs);
    array_copy(*renderable.material_indices, geometry.material_indices);
    array_copy(*renderable.local_to_world_indices, geometry.local_to_world_indices);
}

assign_geometry :: (renderable: *Pbr_Directional_Shadow_Depth_Renderable, geometry: $T/interface Pbr_Directional_Shadow_Depth_Geometry) {
    renderable.indices = geometry.indices;
    renderable.positions = geometry.positions;
    renderable.normals = geometry.normals;
    renderable.tangents = geometry.tangents;
    renderable.uvs = geometry.uvs;
    renderable.material_indices = geometry.material_indices;
    renderable.local_to_world_indices = geometry.local_to_world_indices;
}


deinit :: (renderable: *Pbr_Directional_Shadow_Depth_Renderable) {
    array_free(renderable.indices);
    array_free(renderable.positions);
    array_free(renderable.normals);
    array_free(renderable.tangents);
    array_free(renderable.uvs);
    array_free(renderable.material_indices);
    array_free(renderable.local_to_world_indices);
}

/*

so deinit exists but also unbuffer object exists, the difference is that deinit takes in a renderable and frees its CPU-side arrays and resets its transform slot, whereas unbuffer_object only frees the GPU-side virtual allocation, leaving the CPU data intact for potential re-buffering later.

*/
deinit :: (renderable: *Pbr_Directional_Shadow_Depth_Renderable, renderer: *Pbr_Directional_Shadow_Depth_Renderer) {
    unbuffer_object(*renderer.psr, renderable.object_index);
    array_free(renderable.indices);
    array_free(renderable.positions);
    array_free(renderable.normals);
    array_free(renderable.tangents);
    array_free(renderable.uvs);
    array_free(renderable.material_indices);
    array_free(renderable.local_to_world_indices);
}


unbuffer_object :: (renderer: *Pbr_Directional_Shadow_Depth_Renderer, renderable: *Pbr_Directional_Shadow_Depth_Renderable) {
    unbuffer_object(*renderer.psr, renderable.object_index);
    renderable.object_index = 0;
}


queue_render :: (using renderer: *Pbr_Directional_Shadow_Depth_Renderer, renderable: Pbr_Directional_Shadow_Depth_Renderable) {
    queue_render(*renderer.psr, renderable.object_index);
}

// Indices are relative to this buffered object's first vertex.
update_object_indices :: (renderer : *Pbr_Directional_Shadow_Depth_Renderer, object_index : u32, indices : [] u32) -> bool {
    return update_object_indices(*renderer.psr, object_index, indices);
}

update_object_indices :: (renderer : *Pbr_Directional_Shadow_Depth_Renderer, renderable : $T/interface Pbr_Directional_Shadow_Depth_Renderable, indices : [] u32) -> bool {
    return update_object_indices(renderer, renderable.object_index, indices);
}

queue_render :: (renderer : *Pbr_Directional_Shadow_Depth_Renderer, object_index : u32) {
    queue_render(*renderer.psr, object_index);
}


unbuffer_object :: (renderer : *Pbr_Directional_Shadow_Depth_Renderer, object_index : u32) {
    unbuffer_object(*renderer.psr, object_index);
}

buffer_object :: (renderer : *Pbr_Directional_Shadow_Depth_Renderer, vertices : [] Mesh_Vertex, indices : [] u32) -> (object_index : u32, success : bool) {
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
    for vertex : vertices {
        array_add(*positions, vertex.position);
        array_add(*normals, vertex.normal);
        array_add(*tangents, vertex.tangent);
        array_add(*uvs, vertex.uv);
        array_add(*material_indices, vertex.material_index);
        array_add(*local_to_world_indices, vertex.local_to_world_index);
    }
    buffered_index, buffered := buffer_object(renderer, indices, positions, normals, tangents, uvs, material_indices, local_to_world_indices);
    return buffered_index, buffered;
}


Pbr_Directional_Shadow_Depth_Renderer :: struct {
    using #as psr : Per_Shader_Renderer = .{max_num_elements_in_each_buffer = 100000};


    typed_0_uniform_location : GLint = -1;
    typed_1_uniform_location : GLint = -1;

    positions_buffer_gl_handle: GLuint;
    normals_buffer_gl_handle: GLuint;
    tangents_buffer_gl_handle: GLuint;
    uvs_buffer_gl_handle: GLuint;
    material_indices_buffer_gl_handle: GLuint;
    local_to_world_indices_buffer_gl_handle: GLuint;


}

set_uniforms :: (renderer: *Pbr_Directional_Shadow_Depth_Renderer, ctx: Pbr_Directional_Shadow_Depth_Shadow_Vertex_Uniforms_Bindings) {
    gl_set_active_shader_program(renderer.shader_program_gl_handle);
    gl_set_active_texture_unit(GL_TEXTURE0 + 0);
    gl_bind_texture_to_binding_target_of_active_texture_unit(GL_TEXTURE_2D,ctx.object_transforms);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_0_uniform_location,0);
    gl_set_uniform_matrix_4fv_on_active_shader_program(renderer.typed_1_uniform_location, 1, GL_TRUE, *ctx.world_to_light_clip.coef[0][0]);
    gl_set_active_texture_unit(GL_TEXTURE0);
    gl_clear_active_shader_program();
}


init :: (using renderer : *Pbr_Directional_Shadow_Depth_Renderer) -> bool {
    vertex_shader_source := Pbr_Directional_Shadow_Depth_Vertex_Source;
    fragment_shader_source := Pbr_Directional_Shadow_Depth_Fragment_Source;

    if !init(*renderer.psr, vertex_shader_source, fragment_shader_source, max_num_elements_in_each_buffer) return false;
    init_buffers_no_data(renderer);


    typed_0_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "object_transforms");
    typed_1_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "world_to_light_clip");

    return true;
}


deinit :: (using renderer : *Pbr_Directional_Shadow_Depth_Renderer) {
    deinit(*psr);

    gl_delete_buffer(positions_buffer_gl_handle);
    gl_delete_buffer(normals_buffer_gl_handle);
    gl_delete_buffer(tangents_buffer_gl_handle);
    gl_delete_buffer(uvs_buffer_gl_handle);
    gl_delete_buffer(material_indices_buffer_gl_handle);
    gl_delete_buffer(local_to_world_indices_buffer_gl_handle);
}



init_buffers_no_data :: (using apcr : *Pbr_Directional_Shadow_Depth_Renderer) { // todo change renderer name

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



	gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, 0);
}


buffer_object :: (
    using renderer : *Pbr_Directional_Shadow_Depth_Renderer,
    renderable : *$T/interface Pbr_Directional_Shadow_Depth_Renderable,
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
            budgeter
    );

    if success {
        renderable.object_index = object_index;

    };
    return success;
}

// todo ability to specify the transform matrix upon buffering?
buffer_object :: (
        using renderer: *Pbr_Directional_Shadow_Depth_Renderer,
        indices : [] u32,
        positions : [] Vector3,
        normals : [] Vector3,
        tangents : [] Vector3,
        uvs : [] Vector2,
        material_indices : [] s32,
        local_to_world_indices : [] s32,

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




    gl_bind_vertex_array(0);

    return index, true;
}

/*

so this function is kinda sketchy right now, you can only rebuffer an object if it takes up the exact same size,
if you're rebuffering things and using up more space then you did before you'll start having undefined behavior in rendering and things
will go off the rails.

*/
rebuffer_object :: (using renderer : *Pbr_Directional_Shadow_Depth_Renderer, renderable : $T/interface Pbr_Directional_Shadow_Depth_Renderable) {

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


    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, 0);
    gl_bind_vertex_array(0);
}

render :: (using renderer : *Pbr_Directional_Shadow_Depth_Renderer, primitive_mode: GLenum = GL_TRIANGLES) {

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

Pbr_Directional_Shadow_Depth_Vertex_Source :: #string END_Pbr_Directional_Shadow_Depth_Vertex_Source
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

END_Pbr_Directional_Shadow_Depth_Vertex_Source

Pbr_Directional_Shadow_Depth_Fragment_Source :: #string END_Pbr_Directional_Shadow_Depth_Fragment_Source
#version 330 core
// Generated from Jai procedure shadow_depth_fragment_shader.
layout(location=0) out vec4 gpu_rendering_pipeline_stage_attachment_color;

void main() {
    gpu_rendering_pipeline_stage_attachment_color = vec4(0.0, 0.0, 0.0, 1.0);
}

END_Pbr_Directional_Shadow_Depth_Fragment_Source
