// auto-generated renderer for shader: Camera_Per_Object_Transform_Deferred_Lighting_Compute_Light_Pass
// do not edit manually.


Camera_Per_Object_Transform_Deferred_Lighting_Compute_Light_Pass_Renderable :: struct {
    indices : [..] u32;
    object_index : u32;

    positions: [..] Vector3;
    texture_coordinates: [..] Vector2;

}


Camera_Per_Object_Transform_Deferred_Lighting_Compute_Light_Pass_Geometry :: struct {
    indices : [..] u32;
    positions: [..] Vector3;
    texture_coordinates: [..] Vector2;
}

assign_geometry :: (renderable: *Camera_Per_Object_Transform_Deferred_Lighting_Compute_Light_Pass_Renderable, geometry: $T/interface Camera_Per_Object_Transform_Deferred_Lighting_Compute_Light_Pass_Geometry) {
    array_copy(*renderable.indices, geometry.indices);
    array_copy(*renderable.positions, geometry.positions);
    array_copy(*renderable.texture_coordinates, geometry.texture_coordinates);
}


/*

So deinit exists but also unbuffer object exists, the difference is that deinit takes in a renderable and frees its CPU-side arrays and resets its transform slot, whereas unbuffer_object only frees the GPU-side virtual allocation, leaving the CPU data intact for potential re-buffering later.

*/
deinit :: (renderable: *Camera_Per_Object_Transform_Deferred_Lighting_Compute_Light_Pass_Renderable, renderer: *Camera_Per_Object_Transform_Deferred_Lighting_Compute_Light_Pass_Renderer) {
    unbuffer_object(*renderer.psr, renderable.object_index);
    array_free(renderable.indices);
    array_free(renderable.positions);
    array_free(renderable.texture_coordinates);
}


unbuffer_object :: (renderer: *Camera_Per_Object_Transform_Deferred_Lighting_Compute_Light_Pass_Renderer, renderable: *Camera_Per_Object_Transform_Deferred_Lighting_Compute_Light_Pass_Renderable) {
    unbuffer_object(*renderer.psr, renderable.object_index);
    renderable.object_index = 0;
}


Camera_Per_Object_Transform_Deferred_Lighting_Compute_Light_Pass_Renderer :: struct {
    using #as psr : Per_Shader_Renderer;


    aspect_ratio_uniform_location : GLint = -1;
    position_texture_uniform_location : GLint = -1;
    color_texture_uniform_location : GLint = -1;
    normal_texture_uniform_location : GLint = -1;

    positions_buffer_gl_handle: GLuint;
    passthrough_texture_coordinates_buffer_gl_handle: GLuint;


}


set_aspect_ratio_uniform :: (renderer : *Camera_Per_Object_Transform_Deferred_Lighting_Compute_Light_Pass_Renderer, v: Vector2) {
    glUniform2f(renderer.aspect_ratio_uniform_location, v.x, v.y);
}

set_position_texture_uniform :: (renderer : *Camera_Per_Object_Transform_Deferred_Lighting_Compute_Light_Pass_Renderer, v: s32) {
    glUniform1i(renderer.position_texture_uniform_location, v);
}

set_color_texture_uniform :: (renderer : *Camera_Per_Object_Transform_Deferred_Lighting_Compute_Light_Pass_Renderer, v: s32) {
    glUniform1i(renderer.color_texture_uniform_location, v);
}

set_normal_texture_uniform :: (renderer : *Camera_Per_Object_Transform_Deferred_Lighting_Compute_Light_Pass_Renderer, v: s32) {
    glUniform1i(renderer.normal_texture_uniform_location, v);
}

init :: (using renderer : *Camera_Per_Object_Transform_Deferred_Lighting_Compute_Light_Pass_Renderer) { 
    vertex_shader_source := read_entire_file("data/shaders/out/absolute_position_textured.vert");
    fragment_shader_source := read_entire_file("data/shaders/out/lighting/compute_lighting_from_position_color_normal_textures.frag");

    init(renderer, vertex_shader_source, fragment_shader_source, max_num_elements_in_each_buffer);
    init_buffers_no_data(renderer);


    aspect_ratio_uniform_location = glGetUniformLocation(shader_program_gl_handle, "aspect_ratio");
    position_texture_uniform_location = glGetUniformLocation(shader_program_gl_handle, "position_texture");
    color_texture_uniform_location = glGetUniformLocation(shader_program_gl_handle, "color_texture");
    normal_texture_uniform_location = glGetUniformLocation(shader_program_gl_handle, "normal_texture");

}



init_buffers_no_data :: (using apcr : *Camera_Per_Object_Transform_Deferred_Lighting_Compute_Light_Pass_Renderer) { // todo change renderer name

    glGenVertexArrays(1, *vertex_attribute_array_gl_handle);
    glBindVertexArray(vertex_attribute_array_gl_handle);



    glGenBuffers(1, *index_buffer_gl_handle);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index_buffer_gl_handle);
    // NOTE: it's probably wrong to use  max_num_elements_in_each_buffer because as noted before the number of indices
    // could be larger than this value if we try and render all objects, but we won't care about that until it's a problem.
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, size_of(u32) *  max_num_elements_in_each_buffer, null, GL_DYNAMIC_DRAW);
    // note: we don't have to init the vertex attribute for indices because they used in the shader program for rendering, they're just used during glDrawElements.

    generate_buffer_for_vertex_attribute(*positions_buffer_gl_handle, Vector3, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, positions_buffer_gl_handle, .POSITION);

    generate_buffer_for_vertex_attribute(*passthrough_texture_coordinates_buffer_gl_handle, Vector2, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, passthrough_texture_coordinates_buffer_gl_handle, .PASSTHROUGH_TEXTURE_COORDINATE);



	glBindBuffer (GL_ARRAY_BUFFER, 0);
}


buffer_object :: (using renderer : *Camera_Per_Object_Transform_Deferred_Lighting_Compute_Light_Pass_Renderer, renderable : *$T/interface Camera_Per_Object_Transform_Deferred_Lighting_Compute_Light_Pass_Renderable) -> success: bool {


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
        using renderer: *Camera_Per_Object_Transform_Deferred_Lighting_Compute_Light_Pass_Renderer,
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
rebuffer_object :: (using renderer : *Camera_Per_Object_Transform_Deferred_Lighting_Compute_Light_Pass_Renderer, renderable : $T/interface Camera_Per_Object_Transform_Deferred_Lighting_Compute_Light_Pass_Renderable) {

    glBindVertexArray(vertex_attribute_array_gl_handle);

    glBindBuffer(GL_ARRAY_BUFFER, positions_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, renderable.object_index * size_of(Vector3), renderable.positions.count * size_of(Vector3), renderable.positions.data);

    glBindBuffer(GL_ARRAY_BUFFER, passthrough_texture_coordinates_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, renderable.object_index * size_of(Vector2), renderable.texture_coordinates.count * size_of(Vector2), renderable.texture_coordinates.data);


    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);
}

render :: (using renderer : *Camera_Per_Object_Transform_Deferred_Lighting_Compute_Light_Pass_Renderer, primitive_mode: GLenum = GL_TRIANGLES) {

    // todo think about if we should be using temporary storage.

    glUseProgram(shader_program_gl_handle);



    glBindVertexArray(vertex_attribute_array_gl_handle);
    // todo: reserve so we don't get a ton of reallocations in this for loop
    geom_indices_to_render : [..] u32; 
    // array_reserve(*geom_indices_to_render, ???); // needs some running count whenever we buffer an obj.
    for object_indices_to_render_this_frame {
        geom_indices , success := table_find(*buffered_object_index_to_global_indices, it);
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

