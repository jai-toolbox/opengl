// auto-generated renderer for shader: Transform_MSDF_Text
// do not edit manually.


Transform_MSDF_Text_Renderable :: struct {
    indices : [..] u32;
    object_index : u32;

    positions: [..] Vector3;
    texture_coordinates: [..] Vector2;

}


Transform_MSDF_Text_Geometry :: struct {
    indices : [..] u32;
    positions: [..] Vector3;
    texture_coordinates: [..] Vector2;
}

assign_geometry_copy :: (renderable: *Transform_MSDF_Text_Renderable, geometry: $T/interface Transform_MSDF_Text_Geometry) {
    array_copy(*renderable.indices, geometry.indices);
    array_copy(*renderable.positions, geometry.positions);
    array_copy(*renderable.texture_coordinates, geometry.texture_coordinates);
}

assign_geometry :: (renderable: *Transform_MSDF_Text_Renderable, geometry: $T/interface Transform_MSDF_Text_Geometry) {
    renderable.indices = geometry.indices;
    renderable.positions = geometry.positions;
    renderable.texture_coordinates = geometry.texture_coordinates;
}


deinit :: (renderable: *Transform_MSDF_Text_Renderable) {
    array_free(renderable.indices);
    array_free(renderable.positions);
    array_free(renderable.texture_coordinates);
}

/*

so deinit exists but also unbuffer object exists, the difference is that deinit takes in a renderable and frees its CPU-side arrays and resets its transform slot, whereas unbuffer_object only frees the GPU-side virtual allocation, leaving the CPU data intact for potential re-buffering later.

*/
deinit :: (renderable: *Transform_MSDF_Text_Renderable, renderer: *Transform_MSDF_Text_Renderer) {
    unbuffer_object(*renderer.psr, renderable.object_index);
    array_free(renderable.indices);
    array_free(renderable.positions);
    array_free(renderable.texture_coordinates);
}


unbuffer_object :: (renderer: *Transform_MSDF_Text_Renderer, renderable: *Transform_MSDF_Text_Renderable) {
    unbuffer_object(*renderer.psr, renderable.object_index);
    renderable.object_index = 0;
}


queue_render :: (using renderer: *Transform_MSDF_Text_Renderer, renderable: Transform_MSDF_Text_Renderable) {
    queue_render(*renderer.psr, renderable.object_index);
}


Transform_MSDF_Text_Renderer :: struct {
    using #as psr : Per_Shader_Renderer;


    transform_uniform_location : GLint = -1;
    texture_sampler_uniform_location : GLint = -1;

    positions_buffer_gl_handle: GLuint;
    passthrough_texture_coordinates_buffer_gl_handle: GLuint;


    // immediate-mode buffers
    immediate_vertex_attribute_array_gl_handle: GLuint;
    immediate_index_buffer_gl_handle: GLuint;
    immediate_positions_buffer_gl_handle: GLuint;
    immediate_passthrough_texture_coordinates_buffer_gl_handle: GLuint;

}


set_transform_uniform :: (renderer : *Transform_MSDF_Text_Renderer, v: Matrix4) {
    gl_set_uniform_matrix_4fv_on_active_shader_program(renderer.transform_uniform_location, 1, GL_TRUE, *v.coef[0][0]);
}

set_texture_sampler_uniform :: (renderer : *Transform_MSDF_Text_Renderer, v: s32) {
    gl_set_uniform_1i_on_active_shader_program(renderer.texture_sampler_uniform_location, v);
}

init :: (using renderer : *Transform_MSDF_Text_Renderer) {
    vertex_shader_source := #run read_entire_file(tprint("%../shaders/out/transform_position_textured.vert", #filepath));
    fragment_shader_source := #run read_entire_file(tprint("%../shaders/out/multi_channel_signed_distance_field_text.frag", #filepath));

    init(renderer, vertex_shader_source, fragment_shader_source, max_num_elements_in_each_buffer);
    init_buffers_no_data(renderer);
    init_immediate_buffers(renderer);


    transform_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "transform");
    texture_sampler_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "texture_sampler");

}


deinit :: (using renderer : *Transform_MSDF_Text_Renderer) {
    deinit(*psr);

    gl_delete_buffer(positions_buffer_gl_handle);
    gl_delete_buffer(passthrough_texture_coordinates_buffer_gl_handle);

    // immediate-mode cleanup
    gl_delete_buffer(immediate_index_buffer_gl_handle);
    gl_delete_buffer(immediate_positions_buffer_gl_handle);
    gl_delete_buffer(immediate_passthrough_texture_coordinates_buffer_gl_handle);
    gl_delete_vertex_array(immediate_vertex_attribute_array_gl_handle);
}



init_buffers_no_data :: (using apcr : *Transform_MSDF_Text_Renderer) { // todo change renderer name

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

    generate_buffer_for_vertex_attribute(*passthrough_texture_coordinates_buffer_gl_handle, Vector2, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, passthrough_texture_coordinates_buffer_gl_handle, "passthrough_texture_coordinate", 2, GL_FLOAT, GL_FALSE, 0, null);



	gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, 0);
}



init_immediate_buffers :: (using renderer : *Transform_MSDF_Text_Renderer) {

    immediate_vertex_attribute_array_gl_handle = gl_create_vertex_array();
    gl_bind_vertex_array(immediate_vertex_attribute_array_gl_handle);

    immediate_index_buffer_gl_handle = gl_create_buffer();
    gl_bind_buffer_to_binding_target(GL_ELEMENT_ARRAY_BUFFER, immediate_index_buffer_gl_handle);
    gl_allocate_storage_for_buffer_bound_to_binding_target(GL_ELEMENT_ARRAY_BUFFER, size_of(u32) * 65536, null, GL_STREAM_DRAW);


    generate_buffer_for_vertex_attribute(*immediate_positions_buffer_gl_handle, Vector3, 65536);
    init_vertex_attribute(shader_program_gl_handle, immediate_vertex_attribute_array_gl_handle, immediate_positions_buffer_gl_handle, "position", 3, GL_FLOAT, GL_FALSE, 0, null);

    generate_buffer_for_vertex_attribute(*immediate_passthrough_texture_coordinates_buffer_gl_handle, Vector2, 65536);
    init_vertex_attribute(shader_program_gl_handle, immediate_vertex_attribute_array_gl_handle, immediate_passthrough_texture_coordinates_buffer_gl_handle, "passthrough_texture_coordinate", 2, GL_FLOAT, GL_FALSE, 0, null);



    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, 0);
}


buffer_object :: (
    using renderer : *Transform_MSDF_Text_Renderer,
    renderable : *$T/interface Transform_MSDF_Text_Renderable,
    budgeter: *GL_Budgeter = null,
) -> success: bool {


    object_index, success := buffer_object(renderer,
            renderable.indices,

            renderable.positions,
            renderable.texture_coordinates,
            budgeter
    );

    if success {
        renderable.object_index = object_index;

    };
    return success;
}

// todo ability to specify the transform matrix upon buffering?
buffer_object :: (
        using renderer: *Transform_MSDF_Text_Renderer,
        indices : [..] u32,
        positions : [..] Vector3,
        texture_coordinates : [..] Vector2,

        budgeter: *GL_Budgeter = null

        ) -> object_index: u32, success: bool {

    /*
    note: we use the positions as count, becaues that is the actual data that needs to be in the buffer
    the indices use duplicates sometimes to refer to the same vertex multiple times.
    */
    length := positions.count; // todo: need to metaprogram this out, but it's pretty safe for now.
    index, success := virtual_alloc(*first_fit_virtual_allocator, xx length);
    if !success {
        log("ran out of virtual memory");
        return 0, false;
    }



    global_indices_for_object : [..] u32;
    for indices
        array_add(*global_indices_for_object, xx index + it);

    table_add(*buffered_object_index_to_global_indices, xx index, global_indices_for_object);
    invalidate_cached_index_buffer(*renderer.psr);

    gl_bind_vertex_array(vertex_attribute_array_gl_handle);


    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, positions_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(budgeter, GL_ARRAY_BUFFER, index * size_of(Vector3), positions.count * size_of(Vector3), positions.data);



    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, passthrough_texture_coordinates_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(budgeter, GL_ARRAY_BUFFER, index * size_of(Vector2), texture_coordinates.count * size_of(Vector2), texture_coordinates.data);




    gl_bind_vertex_array(0);

    return index, true;
}

/*

so this function is kinda sketchy right now, you can only rebuffer an object if it takes up the exact same size,
if you're rebuffering things and using up more space then you did before you'll start having undefined behavior in rendering and things
will go off the rails.

*/
rebuffer_object :: (using renderer : *Transform_MSDF_Text_Renderer, renderable : $T/interface Transform_MSDF_Text_Renderable) {

    gl_bind_vertex_array(vertex_attribute_array_gl_handle);

    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, positions_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, renderable.object_index * size_of(Vector3), renderable.positions.count * size_of(Vector3), renderable.positions.data);

    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, passthrough_texture_coordinates_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, renderable.object_index * size_of(Vector2), renderable.texture_coordinates.count * size_of(Vector2), renderable.texture_coordinates.data);


    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, 0);
    gl_bind_vertex_array(0);
}

render :: (using renderer : *Transform_MSDF_Text_Renderer, primitive_mode: GLenum = GL_TRIANGLES) {

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


immediate_render :: (
        using renderer: *Transform_MSDF_Text_Renderer,
        indices : [] u32,
        positions : [] Vector3,
        texture_coordinates : [] Vector2
        ) {

    assert(indices.count > 0, "No indices to render.");

    gl_set_active_shader_program(shader_program_gl_handle);
    gl_bind_vertex_array(immediate_vertex_attribute_array_gl_handle);

    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, immediate_positions_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, 0, positions.count * size_of(Vector3), positions.data);

    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, immediate_passthrough_texture_coordinates_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, 0, texture_coordinates.count * size_of(Vector2), texture_coordinates.data);


    gl_bind_buffer_to_binding_target(GL_ELEMENT_ARRAY_BUFFER, immediate_index_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ELEMENT_ARRAY_BUFFER, 0, indices.count * size_of(u32), indices.data);

    gl_draw_indexed_vertices_from_bound_vertex_array(GL_TRIANGLES, xx indices.count, GL_UNSIGNED_INT, cast(*void) 0);

    gl_bind_vertex_array(0);
    gl_clear_active_shader_program();
}


immediate_render :: (using renderer : *Transform_MSDF_Text_Renderer, geometry : $T/interface Transform_MSDF_Text_Geometry) {
    immediate_render(renderer,
            geometry.indices,
            geometry.positions,
            geometry.texture_coordinates
    );
}
