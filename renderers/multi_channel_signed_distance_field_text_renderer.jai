// auto-generated renderer for shader: Multi_Channel_Signed_Distance_Field_Text
// do not edit manually.


Multi_Channel_Signed_Distance_Field_Text_Renderable :: struct {
    indices : [..] u32;
    object_index : u32;

    positions: [..] Vector3;
    texture_coordinates: [..] Vector2;

}


Multi_Channel_Signed_Distance_Field_Text_Geometry :: struct {
    indices : [..] u32;
    positions: [..] Vector3;
    texture_coordinates: [..] Vector2;
}

assign_geometry_copy :: (renderable: *Multi_Channel_Signed_Distance_Field_Text_Renderable, geometry: $T/interface Multi_Channel_Signed_Distance_Field_Text_Geometry) {
    array_copy(*renderable.indices, geometry.indices);
    array_copy(*renderable.positions, geometry.positions);
    array_copy(*renderable.texture_coordinates, geometry.texture_coordinates);
}

assign_geometry :: (renderable: *Multi_Channel_Signed_Distance_Field_Text_Renderable, geometry: $T/interface Multi_Channel_Signed_Distance_Field_Text_Geometry) {
    renderable.indices = geometry.indices;
    renderable.positions = geometry.positions;
    renderable.texture_coordinates = geometry.texture_coordinates;
}


deinit :: (renderable: *Multi_Channel_Signed_Distance_Field_Text_Renderable) {
    array_free(renderable.indices);
    array_free(renderable.positions);
    array_free(renderable.texture_coordinates);
}

/*

So deinit exists but also unbuffer object exists, the difference is that deinit takes in a renderable and frees its CPU-side arrays and resets its transform slot, whereas unbuffer_object only frees the GPU-side virtual allocation, leaving the CPU data intact for potential re-buffering later.

*/
deinit :: (renderable: *Multi_Channel_Signed_Distance_Field_Text_Renderable, renderer: *Multi_Channel_Signed_Distance_Field_Text_Renderer) {
    unbuffer_object(*renderer.psr, renderable.object_index);
    array_free(renderable.indices);
    array_free(renderable.positions);
    array_free(renderable.texture_coordinates);
}


unbuffer_object :: (renderer: *Multi_Channel_Signed_Distance_Field_Text_Renderer, renderable: *Multi_Channel_Signed_Distance_Field_Text_Renderable) {
    unbuffer_object(*renderer.psr, renderable.object_index);
    renderable.object_index = 0;
}


queue_render :: (using renderer: *Multi_Channel_Signed_Distance_Field_Text_Renderer, renderable: Multi_Channel_Signed_Distance_Field_Text_Renderable) {
    queue_render(*renderer.psr, renderable.object_index);
}


Multi_Channel_Signed_Distance_Field_Text_Renderer :: struct {
    using #as psr : Per_Shader_Renderer;


    aspect_ratio_uniform_location : GLint = -1;
    texture_sampler_uniform_location : GLint = -1;
    rgba_color_uniform_location : GLint = -1;

    positions_buffer_gl_handle: GLuint;
    passthrough_texture_coordinates_buffer_gl_handle: GLuint;


    // immediate-mode buffers
    immediate_vertex_attribute_array_gl_handle: GLuint;
    immediate_index_buffer_gl_handle: GLuint;
    immediate_positions_buffer_gl_handle: GLuint;
    immediate_passthrough_texture_coordinates_buffer_gl_handle: GLuint;

}


set_aspect_ratio_uniform :: (renderer : *Multi_Channel_Signed_Distance_Field_Text_Renderer, v: Vector2) {
    glUniform2f(renderer.aspect_ratio_uniform_location, v.x, v.y);
}

set_texture_sampler_uniform :: (renderer : *Multi_Channel_Signed_Distance_Field_Text_Renderer, v: s32) {
    glUniform1i(renderer.texture_sampler_uniform_location, v);
}

set_rgba_color_uniform :: (renderer : *Multi_Channel_Signed_Distance_Field_Text_Renderer, v: Vector4) {
    glUniform4f(renderer.rgba_color_uniform_location, v.x, v.y, v.z, v.w);
}

init :: (using renderer : *Multi_Channel_Signed_Distance_Field_Text_Renderer) { 
    vertex_shader_loaded, vertex_shader_source := load_asset("data/shaders/out/absolute_position_textured.vert");
    assert(vertex_shader_loaded, "Failed to load vertex shader asset: data/shaders/out/absolute_position_textured.vert");
    fragment_shader_loaded, fragment_shader_source := load_asset("data/shaders/out/multi_channel_signed_distance_field_text.frag");
    assert(fragment_shader_loaded, "Failed to load fragment shader asset: data/shaders/out/multi_channel_signed_distance_field_text.frag");

    init(renderer, vertex_shader_source, fragment_shader_source, max_num_elements_in_each_buffer);
    init_buffers_no_data(renderer);
    init_immediate_buffers(renderer);


    aspect_ratio_uniform_location = glGetUniformLocation(shader_program_gl_handle, "aspect_ratio");
    texture_sampler_uniform_location = glGetUniformLocation(shader_program_gl_handle, "texture_sampler");
    rgba_color_uniform_location = glGetUniformLocation(shader_program_gl_handle, "rgba_color");

}


deinit :: (using renderer : *Multi_Channel_Signed_Distance_Field_Text_Renderer) {
    deinit(*psr);

    glDeleteBuffers(1, *positions_buffer_gl_handle);
    glDeleteBuffers(1, *passthrough_texture_coordinates_buffer_gl_handle);

    // immediate-mode cleanup
    glDeleteBuffers(1, *immediate_index_buffer_gl_handle);
    glDeleteBuffers(1, *immediate_positions_buffer_gl_handle);
    glDeleteBuffers(1, *immediate_passthrough_texture_coordinates_buffer_gl_handle);
    glDeleteVertexArrays(1, *immediate_vertex_attribute_array_gl_handle);
}



init_buffers_no_data :: (using apcr : *Multi_Channel_Signed_Distance_Field_Text_Renderer) { // todo change renderer name

    glGenVertexArrays(1, *vertex_attribute_array_gl_handle);
    glBindVertexArray(vertex_attribute_array_gl_handle);



    glGenBuffers(1, *index_buffer_gl_handle);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index_buffer_gl_handle);
    // NOTE: it's probably wrong to use  max_num_elements_in_each_buffer because as noted before the number of indices
    // could be larger than this value if we try and render all objects, but we won't care about that until it's a problem.
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, size_of(u32) *  max_num_elements_in_each_buffer, null, GL_DYNAMIC_DRAW);
    // note: we don't have to init the vertex attribute for indices because they used in the shader program for rendering, they're just used during glDrawElements.

    generate_buffer_for_vertex_attribute(*positions_buffer_gl_handle, Vector3, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, positions_buffer_gl_handle, "position", 3, GL_FLOAT, GL_FALSE, 0, null);

    generate_buffer_for_vertex_attribute(*passthrough_texture_coordinates_buffer_gl_handle, Vector2, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, passthrough_texture_coordinates_buffer_gl_handle, "passthrough_texture_coordinate", 2, GL_FLOAT, GL_FALSE, 0, null);



	glBindBuffer (GL_ARRAY_BUFFER, 0);
}



init_immediate_buffers :: (using renderer : *Multi_Channel_Signed_Distance_Field_Text_Renderer) {

    glGenVertexArrays(1, *immediate_vertex_attribute_array_gl_handle);
    glBindVertexArray(immediate_vertex_attribute_array_gl_handle);

    glGenBuffers(1, *immediate_index_buffer_gl_handle);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, immediate_index_buffer_gl_handle);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, size_of(u32) * 4096, null, GL_STREAM_DRAW);

    generate_buffer_for_vertex_attribute(*immediate_positions_buffer_gl_handle, Vector3, 4096);
    init_vertex_attribute(shader_program_gl_handle, immediate_vertex_attribute_array_gl_handle, immediate_positions_buffer_gl_handle, "position", 3, GL_FLOAT, GL_FALSE, 0, null);

    generate_buffer_for_vertex_attribute(*immediate_passthrough_texture_coordinates_buffer_gl_handle, Vector2, 4096);
    init_vertex_attribute(shader_program_gl_handle, immediate_vertex_attribute_array_gl_handle, immediate_passthrough_texture_coordinates_buffer_gl_handle, "passthrough_texture_coordinate", 2, GL_FLOAT, GL_FALSE, 0, null);



    glBindBuffer(GL_ARRAY_BUFFER, 0);
}


buffer_object :: (using renderer : *Multi_Channel_Signed_Distance_Field_Text_Renderer, renderable : *$T/interface Multi_Channel_Signed_Distance_Field_Text_Renderable) -> success: bool {


    object_index, success := buffer_object(renderer, 
            renderable.indices, 

            renderable.positions,
            renderable.texture_coordinates
    );

    if success {
        renderable.object_index = object_index;

    };
    return success;
}

// todo ability to specify the transform matrix upon buffering?
buffer_object :: (
        using renderer: *Multi_Channel_Signed_Distance_Field_Text_Renderer,
        indices : [..] u32,
        positions : [..] Vector3,
        texture_coordinates : [..] Vector2

        ) -> object_index: u32, success: bool {

    // note: we use the positions as count, becaues that is the actual data that needs to be in the buffer
    // the indices use duplicates sometimes to refer to the same vertex multiple times.
    length := positions.count; // TODO: need to metaprogram this out, but it's pretty safe for now.
    index, success := virtual_alloc(*first_fit_virtual_allocator, xx length);
    if !success {
        log("ran out of virtual memory");
        return 0, false;
    }

    global_indices_for_object : [..] u32;
    for indices 
        array_add(*global_indices_for_object, xx index + it);

    table_add(*buffered_object_index_to_global_indices, xx index, global_indices_for_object);

    glBindVertexArray(vertex_attribute_array_gl_handle);

    
    glBindBuffer(GL_ARRAY_BUFFER, positions_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, index * size_of(Vector3), positions.count * size_of(Vector3), positions.data);


    
    glBindBuffer(GL_ARRAY_BUFFER, passthrough_texture_coordinates_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, index * size_of(Vector2), texture_coordinates.count * size_of(Vector2), texture_coordinates.data);




    glBindVertexArray(0);

    return index, true;
}

/*

So this function is kinda sketchy right now, you can only rebuffer an object if it takes up the exact same size, 
if you're rebuffering things and using up more space then you did before you'll start having undefined behavior in rendering and things 
will go off the rails.

*/
rebuffer_object :: (using renderer : *Multi_Channel_Signed_Distance_Field_Text_Renderer, renderable : $T/interface Multi_Channel_Signed_Distance_Field_Text_Renderable) {

    glBindVertexArray(vertex_attribute_array_gl_handle);

    glBindBuffer(GL_ARRAY_BUFFER, positions_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, renderable.object_index * size_of(Vector3), renderable.positions.count * size_of(Vector3), renderable.positions.data);

    glBindBuffer(GL_ARRAY_BUFFER, passthrough_texture_coordinates_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, renderable.object_index * size_of(Vector2), renderable.texture_coordinates.count * size_of(Vector2), renderable.texture_coordinates.data);


    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);
}

render :: (using renderer : *Multi_Channel_Signed_Distance_Field_Text_Renderer, primitive_mode: GLenum = GL_TRIANGLES) {

    // todo think about if we should be using temporary storage.

    glUseProgram(shader_program_gl_handle);



    glBindVertexArray(vertex_attribute_array_gl_handle);
    // todo: reserve so we don't get a ton of reallocations in this for loop
    geom_indices_to_render : [..] u32;  // can we just use temp storage?
    defer array_free(geom_indices_to_render);
    // array_reserve(*geom_indices_to_render, ???); // needs some running count whenever we buffer an obj.
    for object_indices_to_render_this_frame {
        success, geom_indices := table_find(*buffered_object_index_to_global_indices, it);
        if !success log("couldn't find the global indices of object with id: GL_TRIANGLES", it);
        for geom_indices 
            array_add(*geom_indices_to_render, it);
    }


    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index_buffer_gl_handle);
    // here we're just overwriting the buffer on each draw call, if there's less data written than last iteration it's fine
    // as we will only access the smaller portion
    glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, 0, geom_indices_to_render.count * size_of(u32), geom_indices_to_render.data);

    glDrawElements(primitive_mode, xx geom_indices_to_render.count, GL_UNSIGNED_INT, cast (*void) 0);

    // the rendering the same objects test as last frame test is a worthwhile optimization that should occur.

    array_reset(*object_indices_to_render_this_frame);

    glBindVertexArray(0);
    glUseProgram(0);
}


immediate_render :: (
        using renderer: *Multi_Channel_Signed_Distance_Field_Text_Renderer,
        indices : [] u32,
        positions : [] Vector3,
        texture_coordinates : [] Vector2
        ) {

    assert(indices.count > 0, "No indices to render.");

    glUseProgram(shader_program_gl_handle);
    glBindVertexArray(immediate_vertex_attribute_array_gl_handle);

    glBindBuffer(GL_ARRAY_BUFFER, immediate_positions_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, 0, positions.count * size_of(Vector3), positions.data);

    glBindBuffer(GL_ARRAY_BUFFER, immediate_passthrough_texture_coordinates_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, 0, texture_coordinates.count * size_of(Vector2), texture_coordinates.data);


    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, immediate_index_buffer_gl_handle);
    glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, 0, indices.count * size_of(u32), indices.data);

    glDrawElements(GL_TRIANGLES, xx indices.count, GL_UNSIGNED_INT, cast(*void) 0);

    glBindVertexArray(0);
    glUseProgram(0);
}


immediate_render :: (using renderer : *Multi_Channel_Signed_Distance_Field_Text_Renderer, geometry : $T/interface Multi_Channel_Signed_Distance_Field_Text_Geometry) {
    immediate_render(renderer,
            geometry.indices,
            geometry.positions,
            geometry.texture_coordinates
    );
}

