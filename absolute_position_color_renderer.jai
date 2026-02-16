// Auto-generated renderer for shader: Absolute_Position_Color
// Do not edit manually.


Per_Object_Absolute_Position_Color_Renderer :: struct {
    using #as psr : Per_Shader_Renderer;

    positions_buffer_gl_handle: GLuint;
    passthrough_rgb_colors_buffer_gl_handle: GLuint;

}



init_buffers_no_data :: (using apcr : *Per_Object_Absolute_Position_Color_Renderer) { // todo change renderer name

    glGenVertexArrays(1, *vertex_attribute_array_gl_handle);
    glBindVertexArray(vertex_attribute_array_gl_handle);

    glGenBuffers(1, *index_buffer_gl_handle);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index_buffer_gl_handle);
    // NOTE: it's probably wrong to use  MAX_NUM_ELEMENTS_IN_EACH_BUFFER because as noted before the number of indices
    // could be larger than this value if we try and render all objects, but we won't care about that until it's a problem.
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, size_of(u32) *  MAX_NUM_ELEMENTS_IN_EACH_BUFFER, null, GL_DYNAMIC_DRAW);
    // note: we don't have to init the vertex attribute for indices because they used in the shader program for rendering, they're just used during glDrawElements.

    generate_a_buffer_for_a_vertex_attribute(positions_buffer_gl_handle, Vector3, MAX_NUM_ELEMENTS_IN_EACH_BUFFER);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, positions_buffer_gl_handle, .POSITION);

    generate_a_buffer_for_a_vertex_attribute(passthrough_rgb_colors_buffer_gl_handle, Vector3, MAX_NUM_ELEMENTS_IN_EACH_BUFFER);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, passthrough_rgb_colors_buffer_gl_handle, .PASSTHROUGH_RGB_COLOR);



	glBindBuffer (GL_ARRAY_BUFFER, 0);
}

// todo ability to specify the transform matrix upon buffering?
buffer_object :: (
        using renderer: *Per_Object_Absolute_Position_Color_Renderer,
        indices : [..] u32,
        positions : [..] Vector3
        rgb_colors : [..] Vector3


        ) -> object_index: u32, local_to_world_index: u32, success: bool {

    // note: we use the positions as count, becaues that is the actual data that needs to be in the buffer
    // the indices use duplicates sometimes to refer to the same vertex multiple times.
    length := positions.count; // TODO: need to metaprogram this out, but it's pretty safe for now.
    index, success := virtual_alloc(*first_fit_virtual_allocator, xx length);
    if !success {
        log("ran out of virtual memory");
        return 0, 0, false;
    }

    global_indices_for_object : [..] u32;
    for indices 
        array_add(*global_indices_for_object, xx index + it);

    table_add(*buffered_object_index_to_global_indices, xx index, global_indices_for_object);

    glBindVertexArray(vertex_attribute_array_gl_handle);

    
    glBindBuffer(GL_ARRAY_BUFFER, positions_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, index * size_of(Vector3), positions.count * size_of(Vector3), positions.data);


    
    glBindBuffer(GL_ARRAY_BUFFER, passthrough_rgb_colors_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, index * size_of(Vector3), rgb_colors.count * size_of(Vector3), rgb_colors.data);




    // glBindBuffer(GL_ARRAY_BUFFER, position_buffer_gl_handle);
    // glBufferSubData(GL_ARRAY_BUFFER, index * size_of(Vector3), positions.count * size_of(Vector3), positions.data);

    // glBindBuffer(GL_ARRAY_BUFFER, color_buffer_gl_handle);
    // glBufferSubData(GL_ARRAY_BUFFER, index * size_of(Vector3), colors.count * size_of(Vector3), colors.data);

    // later on we only need to do local to world indices if the shader uses per object transforms.

    // local_to_world_indices are an array of the same value which is the local to world index
    // the alternative to this is binding the uniform per object, which we're trying to avoid because we want to render
    // everything at once in one big draw call.

    local_to_world_indices: [..] u32;
    for 0..positions.count array_add(*local_to_world_indices, current_local_to_world_index);

    ltw_index_we_used := current_local_to_world_index;
    current_local_to_world_index += 1;

    glBindBuffer(GL_ARRAY_BUFFER, local_to_world_index_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, index * size_of(u32), local_to_world_indices.count * size_of(u32), local_to_world_indices.data);

    glBindVertexArray(0);

    return index, ltw_index_we_used, true;
}
