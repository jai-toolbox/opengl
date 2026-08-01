// auto-generated renderer for shader: Lit_Color
// do not edit manually.


Lit_Color_Renderable :: struct {
    indices : [..] u32;
    object_index : u32;

    positions: [..] Vector3;
    normals: [..] Vector3;
    colors: [..] Vector3;

}


Lit_Color_Geometry :: struct {
    indices : [..] u32;
    positions: [..] Vector3;
    normals: [..] Vector3;
    colors: [..] Vector3;
}

assign_geometry_copy :: (renderable: *Lit_Color_Renderable, geometry: $T/interface Lit_Color_Geometry) {
    array_copy(*renderable.indices, geometry.indices);
    array_copy(*renderable.positions, geometry.positions);
    array_copy(*renderable.normals, geometry.normals);
    array_copy(*renderable.colors, geometry.colors);
}

assign_geometry :: (renderable: *Lit_Color_Renderable, geometry: $T/interface Lit_Color_Geometry) {
    renderable.indices = geometry.indices;
    renderable.positions = geometry.positions;
    renderable.normals = geometry.normals;
    renderable.colors = geometry.colors;
}


deinit :: (renderable: *Lit_Color_Renderable) {
    array_free(renderable.indices);
    array_free(renderable.positions);
    array_free(renderable.normals);
    array_free(renderable.colors);
}

/*

So deinit exists but also unbuffer object exists, the difference is that deinit takes in a renderable and frees its CPU-side arrays and resets its transform slot, whereas unbuffer_object only frees the GPU-side virtual allocation, leaving the CPU data intact for potential re-buffering later.

*/
deinit :: (renderable: *Lit_Color_Renderable, renderer: *Lit_Color_Renderer) {
    unbuffer_object(*renderer.psr, renderable.object_index);
    array_free(renderable.indices);
    array_free(renderable.positions);
    array_free(renderable.normals);
    array_free(renderable.colors);
}


unbuffer_object :: (renderer: *Lit_Color_Renderer, renderable: *Lit_Color_Renderable) {
    unbuffer_object(*renderer.psr, renderable.object_index);
    renderable.object_index = 0;
}


queue_render :: (using renderer: *Lit_Color_Renderer, renderable: Lit_Color_Renderable) {
    queue_render(*renderer.psr, renderable.object_index);
}


Lit_Color_Renderer :: struct {
    using #as psr : Per_Shader_Renderer;


    angle_uniform_location : GLint = -1;
    camera_position_uniform_location : GLint = -1;
    light_direction_uniform_location : GLint = -1;
    ambient_uniform_location : GLint = -1;

    positions_buffer_gl_handle: GLuint;
    normals_buffer_gl_handle: GLuint;
    colors_buffer_gl_handle: GLuint;


}


set_angle_uniform :: (renderer : *Lit_Color_Renderer, v: float32) {
    glUniform1f(renderer.angle_uniform_location, v);
}

set_camera_position_uniform :: (renderer : *Lit_Color_Renderer, v: Vector3) {
    glUniform3f(renderer.camera_position_uniform_location, v.x, v.y, v.z);
}

set_light_direction_uniform :: (renderer : *Lit_Color_Renderer, v: Vector3) {
    glUniform3f(renderer.light_direction_uniform_location, v.x, v.y, v.z);
}

set_ambient_uniform :: (renderer : *Lit_Color_Renderer, v: float32) {
    glUniform1f(renderer.ambient_uniform_location, v);
}

init :: (using renderer : *Lit_Color_Renderer) { 
    vertex_shader_loaded, vertex_shader_source := load_asset("data/shaders/generated/lit_color.vert");
    assert(vertex_shader_loaded, "Failed to load vertex shader asset: data/shaders/generated/lit_color.vert");
    fragment_shader_loaded, fragment_shader_source := load_asset("data/shaders/generated/lit_color.frag");
    assert(fragment_shader_loaded, "Failed to load fragment shader asset: data/shaders/generated/lit_color.frag");

    init(renderer, vertex_shader_source, fragment_shader_source, max_num_elements_in_each_buffer);
    init_buffers_no_data(renderer);


    angle_uniform_location = glGetUniformLocation(shader_program_gl_handle, "angle");
    camera_position_uniform_location = glGetUniformLocation(shader_program_gl_handle, "camera_position");
    light_direction_uniform_location = glGetUniformLocation(shader_program_gl_handle, "light_direction");
    ambient_uniform_location = glGetUniformLocation(shader_program_gl_handle, "ambient");

}


deinit :: (using renderer : *Lit_Color_Renderer) {
    deinit(*psr);

    glDeleteBuffers(1, *positions_buffer_gl_handle);
    glDeleteBuffers(1, *normals_buffer_gl_handle);
    glDeleteBuffers(1, *colors_buffer_gl_handle);
}



init_buffers_no_data :: (using apcr : *Lit_Color_Renderer) { // todo change renderer name

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

    generate_buffer_for_vertex_attribute(*normals_buffer_gl_handle, Vector3, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, normals_buffer_gl_handle, "normal", 3, GL_FLOAT, GL_FALSE, 0, null);

    generate_buffer_for_vertex_attribute(*colors_buffer_gl_handle, Vector3, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, colors_buffer_gl_handle, "color", 3, GL_FLOAT, GL_FALSE, 0, null);



	glBindBuffer (GL_ARRAY_BUFFER, 0);
}


buffer_object :: (using renderer : *Lit_Color_Renderer, renderable : *$T/interface Lit_Color_Renderable) -> success: bool {


    object_index, success := buffer_object(renderer, 
            renderable.indices, 

            renderable.positions,
            renderable.normals,
            renderable.colors
    );

    if success {
        renderable.object_index = object_index;

    };
    return success;
}

// todo ability to specify the transform matrix upon buffering?
buffer_object :: (
        using renderer: *Lit_Color_Renderer,
        indices : [..] u32,
        positions : [..] Vector3,
        normals : [..] Vector3,
        colors : [..] Vector3

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


    
    glBindBuffer(GL_ARRAY_BUFFER, normals_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, index * size_of(Vector3), normals.count * size_of(Vector3), normals.data);


    
    glBindBuffer(GL_ARRAY_BUFFER, colors_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, index * size_of(Vector3), colors.count * size_of(Vector3), colors.data);




    glBindVertexArray(0);

    return index, true;
}

/*

So this function is kinda sketchy right now, you can only rebuffer an object if it takes up the exact same size, 
if you're rebuffering things and using up more space then you did before you'll start having undefined behavior in rendering and things 
will go off the rails.

*/
rebuffer_object :: (using renderer : *Lit_Color_Renderer, renderable : $T/interface Lit_Color_Renderable) {

    glBindVertexArray(vertex_attribute_array_gl_handle);

    glBindBuffer(GL_ARRAY_BUFFER, positions_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, renderable.object_index * size_of(Vector3), renderable.positions.count * size_of(Vector3), renderable.positions.data);

    glBindBuffer(GL_ARRAY_BUFFER, normals_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, renderable.object_index * size_of(Vector3), renderable.normals.count * size_of(Vector3), renderable.normals.data);

    glBindBuffer(GL_ARRAY_BUFFER, colors_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, renderable.object_index * size_of(Vector3), renderable.colors.count * size_of(Vector3), renderable.colors.data);


    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);
}

render :: (using renderer : *Lit_Color_Renderer, primitive_mode: GLenum = GL_TRIANGLES) {

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

