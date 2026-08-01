// auto-generated renderer for shader: Camera_Per_Object_Transforms_Packed_Texture
// do not edit manually.


Camera_Per_Object_Transforms_Packed_Texture_Renderable :: struct {
    indices : [..] u32;
    object_index : u32;

    local_to_world_index : u32;

    positions: [..] Vector3;
    packed_texture_index: [..] s32;
    texture_coordinates: [..] Vector2;
    packed_texture_bounding_box_index: [..] s32;

}


Camera_Per_Object_Transforms_Packed_Texture_Geometry :: struct {
    indices : [..] u32;
    positions: [..] Vector3;
    packed_texture_index: [..] s32;
    texture_coordinates: [..] Vector2;
    packed_texture_bounding_box_index: [..] s32;
}

assign_geometry_copy :: (renderable: *Camera_Per_Object_Transforms_Packed_Texture_Renderable, geometry: $T/interface Camera_Per_Object_Transforms_Packed_Texture_Geometry) {
    array_copy(*renderable.indices, geometry.indices);
    array_copy(*renderable.positions, geometry.positions);
    array_copy(*renderable.packed_texture_index, geometry.packed_texture_index);
    array_copy(*renderable.texture_coordinates, geometry.texture_coordinates);
    array_copy(*renderable.packed_texture_bounding_box_index, geometry.packed_texture_bounding_box_index);
}

assign_geometry :: (renderable: *Camera_Per_Object_Transforms_Packed_Texture_Renderable, geometry: $T/interface Camera_Per_Object_Transforms_Packed_Texture_Geometry) {
    renderable.indices = geometry.indices;
    renderable.positions = geometry.positions;
    renderable.packed_texture_index = geometry.packed_texture_index;
    renderable.texture_coordinates = geometry.texture_coordinates;
    renderable.packed_texture_bounding_box_index = geometry.packed_texture_bounding_box_index;
}


deinit :: (renderable: *Camera_Per_Object_Transforms_Packed_Texture_Renderable) {
    array_free(renderable.indices);
    array_free(renderable.positions);
    array_free(renderable.packed_texture_index);
    array_free(renderable.texture_coordinates);
    array_free(renderable.packed_texture_bounding_box_index);
}

/*

So deinit exists but also unbuffer object exists, the difference is that deinit takes in a renderable and frees its CPU-side arrays and resets its transform slot, whereas unbuffer_object only frees the GPU-side virtual allocation, leaving the CPU data intact for potential re-buffering later.

*/
deinit :: (renderable: *Camera_Per_Object_Transforms_Packed_Texture_Renderable, renderer: *Camera_Per_Object_Transforms_Packed_Texture_Renderer) {
    unbuffer_object(*renderer.psr, renderable.object_index);
    free_index(*renderer.ltw_pool, renderable.local_to_world_index);
    renderable.local_to_world_index = 0;
    renderable.object_index = 0;
    array_free(renderable.indices);
    array_free(renderable.positions);
    array_free(renderable.packed_texture_index);
    array_free(renderable.texture_coordinates);
    array_free(renderable.packed_texture_bounding_box_index);
}


unbuffer_object :: (renderer: *Camera_Per_Object_Transforms_Packed_Texture_Renderer, renderable: *Camera_Per_Object_Transforms_Packed_Texture_Renderable) {
    unbuffer_object(*renderer.psr, renderable.object_index);
    free_index(*renderer.ltw_pool, renderable.local_to_world_index);
    renderable.local_to_world_index = 0;
    renderable.object_index = 0;
}


queue_render :: (using renderer: *Camera_Per_Object_Transforms_Packed_Texture_Renderer, renderable: Camera_Per_Object_Transforms_Packed_Texture_Renderable) {
    queue_render(*renderer.psr, renderable.object_index);
}


set_local_to_world_matrix :: (renderer: *Camera_Per_Object_Transforms_Packed_Texture_Renderer, renderable: Camera_Per_Object_Transforms_Packed_Texture_Renderable, matrix: Matrix4) {
    set_matrix(*renderer.ltw_pool, renderable.local_to_world_index, matrix);
}


Camera_Per_Object_Transforms_Packed_Texture_Renderer :: struct {
    using #as psr : Per_Shader_Renderer;


    using #as ltw_pool : Local_To_World_Matrix_Pool;

    local_to_world_index_buffer_gl_handle : GLuint;


    camera_to_clip_uniform_location : GLint = -1;
    world_to_camera_uniform_location : GLint = -1;
    packed_textures_uniform_location : GLint = -1;
    packed_texture_bounding_boxes_uniform_location : GLint = -1;

    positions_buffer_gl_handle: GLuint;
    passthrough_packed_texture_indices_buffer_gl_handle: GLuint;
    passthrough_texture_coordinates_buffer_gl_handle: GLuint;
    passthrough_packed_texture_bounding_box_indices_buffer_gl_handle: GLuint;


}


set_camera_to_clip_uniform :: (renderer : *Camera_Per_Object_Transforms_Packed_Texture_Renderer, v: Matrix4) {
    glUniformMatrix4fv(renderer.camera_to_clip_uniform_location, 1, GL_TRUE, *v.coef[0][0]);
}

set_world_to_camera_uniform :: (renderer : *Camera_Per_Object_Transforms_Packed_Texture_Renderer, v: Matrix4) {
    glUniformMatrix4fv(renderer.world_to_camera_uniform_location, 1, GL_TRUE, *v.coef[0][0]);
}

set_packed_textures_uniform :: (renderer : *Camera_Per_Object_Transforms_Packed_Texture_Renderer, v: s32) {
    glUniform1i(renderer.packed_textures_uniform_location, v);
}

set_packed_texture_bounding_boxes_uniform :: (renderer : *Camera_Per_Object_Transforms_Packed_Texture_Renderer, v: s32) {
    glUniform1i(renderer.packed_texture_bounding_boxes_uniform_location, v);
}

init :: (using renderer : *Camera_Per_Object_Transforms_Packed_Texture_Renderer) { 
    vertex_shader_loaded, vertex_shader_source := load_asset("data/shaders/out/camera_per_object_transform_packed_texture.vert");
    assert(vertex_shader_loaded, "Failed to load vertex shader asset: data/shaders/out/camera_per_object_transform_packed_texture.vert");
    fragment_shader_loaded, fragment_shader_source := load_asset("data/shaders/out/packed_texture.frag");
    assert(fragment_shader_loaded, "Failed to load fragment shader asset: data/shaders/out/packed_texture.frag");

    init(renderer, vertex_shader_source, fragment_shader_source, max_num_elements_in_each_buffer);
    init_buffers_no_data(renderer);

    init(*renderer.ltw_pool);

    camera_to_clip_uniform_location = glGetUniformLocation(shader_program_gl_handle, "camera_to_clip");
    world_to_camera_uniform_location = glGetUniformLocation(shader_program_gl_handle, "world_to_camera");
    packed_textures_uniform_location = glGetUniformLocation(shader_program_gl_handle, "packed_textures");
    packed_texture_bounding_boxes_uniform_location = glGetUniformLocation(shader_program_gl_handle, "packed_texture_bounding_boxes");

}


deinit :: (using renderer : *Camera_Per_Object_Transforms_Packed_Texture_Renderer) {
    deinit(*ltw_pool);

    deinit(*psr);

    glDeleteBuffers(1, *positions_buffer_gl_handle);
    glDeleteBuffers(1, *passthrough_packed_texture_indices_buffer_gl_handle);
    glDeleteBuffers(1, *passthrough_texture_coordinates_buffer_gl_handle);
    glDeleteBuffers(1, *passthrough_packed_texture_bounding_box_indices_buffer_gl_handle);
    glDeleteBuffers(1, *local_to_world_index_buffer_gl_handle);
}



init_buffers_no_data :: (using apcr : *Camera_Per_Object_Transforms_Packed_Texture_Renderer) { // todo change renderer name

    glGenVertexArrays(1, *vertex_attribute_array_gl_handle);
    glBindVertexArray(vertex_attribute_array_gl_handle);


    generate_buffer_for_vertex_attribute(*local_to_world_index_buffer_gl_handle, u32, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, local_to_world_index_buffer_gl_handle, "local_to_world_index", 1, GL_UNSIGNED_INT, GL_FALSE, 0, null);



    glGenBuffers(1, *index_buffer_gl_handle);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index_buffer_gl_handle);
    // NOTE: it's probably wrong to use  max_num_elements_in_each_buffer because as noted before the number of indices
    // could be larger than this value if we try and render all objects, but we won't care about that until it's a problem.
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, size_of(u32) *  max_num_elements_in_each_buffer, null, GL_DYNAMIC_DRAW);
    // note: we don't have to init the vertex attribute for indices because they used in the shader program for rendering, they're just used during glDrawElements.

    generate_buffer_for_vertex_attribute(*positions_buffer_gl_handle, Vector3, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, positions_buffer_gl_handle, "position", 3, GL_FLOAT, GL_FALSE, 0, null);

    generate_buffer_for_vertex_attribute(*passthrough_packed_texture_indices_buffer_gl_handle, s32, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, passthrough_packed_texture_indices_buffer_gl_handle, "passthrough_packed_texture_index", 1, GL_INT, GL_FALSE, 0, null);

    generate_buffer_for_vertex_attribute(*passthrough_texture_coordinates_buffer_gl_handle, Vector2, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, passthrough_texture_coordinates_buffer_gl_handle, "passthrough_texture_coordinate", 2, GL_FLOAT, GL_FALSE, 0, null);

    generate_buffer_for_vertex_attribute(*passthrough_packed_texture_bounding_box_indices_buffer_gl_handle, s32, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, passthrough_packed_texture_bounding_box_indices_buffer_gl_handle, "passthrough_packed_texture_bounding_box_index", 1, GL_INT, GL_FALSE, 0, null);



	glBindBuffer (GL_ARRAY_BUFFER, 0);
}


buffer_object :: (using renderer : *Camera_Per_Object_Transforms_Packed_Texture_Renderer, renderable : *$T/interface Camera_Per_Object_Transforms_Packed_Texture_Renderable) -> success: bool {


    object_index, local_to_world_index, success := buffer_object(renderer, 
            renderable.indices, 

            renderable.positions,
            renderable.packed_texture_index,
            renderable.texture_coordinates,
            renderable.packed_texture_bounding_box_index
    );

    if success {
        renderable.object_index = object_index;
        renderable.local_to_world_index = local_to_world_index;

    };
    return success;
}

// todo ability to specify the transform matrix upon buffering?
buffer_object :: (
        using renderer: *Camera_Per_Object_Transforms_Packed_Texture_Renderer,
        indices : [..] u32,
        positions : [..] Vector3,
        packed_texture_index : [..] s32,
        texture_coordinates : [..] Vector2,
        packed_texture_bounding_box_index : [..] s32

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


    
    glBindBuffer(GL_ARRAY_BUFFER, passthrough_packed_texture_indices_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, index * size_of(s32), packed_texture_index.count * size_of(s32), packed_texture_index.data);


    
    glBindBuffer(GL_ARRAY_BUFFER, passthrough_texture_coordinates_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, index * size_of(Vector2), texture_coordinates.count * size_of(Vector2), texture_coordinates.data);


    
    glBindBuffer(GL_ARRAY_BUFFER, passthrough_packed_texture_bounding_box_indices_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, index * size_of(s32), packed_texture_bounding_box_index.count * size_of(s32), packed_texture_bounding_box_index.data);


    ltw_index_we_used, ltw_success := alloc_index(*ltw_pool);
    if !ltw_success {
        virtual_free(*first_fit_virtual_allocator, index);
        return 0, 0, false;
    }

    local_to_world_indices: [..] u32;
    for 0..positions.count-1 array_add(*local_to_world_indices, ltw_index_we_used);

    glBindBuffer(GL_ARRAY_BUFFER, local_to_world_index_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, index * size_of(u32), local_to_world_indices.count * size_of(u32), local_to_world_indices.data);

    array_free(local_to_world_indices);


    glBindVertexArray(0);

    return index, ltw_index_we_used, true;
}

/*

So this function is kinda sketchy right now, you can only rebuffer an object if it takes up the exact same size, 
if you're rebuffering things and using up more space then you did before you'll start having undefined behavior in rendering and things 
will go off the rails.

*/
rebuffer_object :: (using renderer : *Camera_Per_Object_Transforms_Packed_Texture_Renderer, renderable : $T/interface Camera_Per_Object_Transforms_Packed_Texture_Renderable) {

    glBindVertexArray(vertex_attribute_array_gl_handle);

    glBindBuffer(GL_ARRAY_BUFFER, positions_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, renderable.object_index * size_of(Vector3), renderable.positions.count * size_of(Vector3), renderable.positions.data);

    glBindBuffer(GL_ARRAY_BUFFER, passthrough_packed_texture_indices_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, renderable.object_index * size_of(s32), renderable.packed_texture_index.count * size_of(s32), renderable.packed_texture_index.data);

    glBindBuffer(GL_ARRAY_BUFFER, passthrough_texture_coordinates_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, renderable.object_index * size_of(Vector2), renderable.texture_coordinates.count * size_of(Vector2), renderable.texture_coordinates.data);

    glBindBuffer(GL_ARRAY_BUFFER, passthrough_packed_texture_bounding_box_indices_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, renderable.object_index * size_of(s32), renderable.packed_texture_bounding_box_index.count * size_of(s32), renderable.packed_texture_bounding_box_index.data);


    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);
}

render :: (using renderer : *Camera_Per_Object_Transforms_Packed_Texture_Renderer, primitive_mode: GLenum = GL_TRIANGLES) {

    // todo think about if we should be using temporary storage.

    glUseProgram(shader_program_gl_handle);


    upload_to_gpu(*ltw_pool);



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

