// auto-generated renderer for shader: Camera_Per_Object_Transform_Deferred_Lighting_Geometry_Pass
// do not edit manually.


Camera_Per_Object_Transform_Deferred_Lighting_Geometry_Pass_Renderable :: struct {
    indices : [..] u32;
    object_index : u32;

    local_to_world_index : u32;

    positions: [..] Vector3;
    rgb_colors: [..] Vector3;
    normals: [..] Vector3;

}


Camera_Per_Object_Transform_Deferred_Lighting_Geometry_Pass_Geometry :: struct {
    indices : [..] u32;
    positions: [..] Vector3;
    rgb_colors: [..] Vector3;
    normals: [..] Vector3;
}

assign_geometry :: (renderable: *Camera_Per_Object_Transform_Deferred_Lighting_Geometry_Pass_Renderable, geometry: $T/interface Camera_Per_Object_Transform_Deferred_Lighting_Geometry_Pass_Geometry) {
    array_copy(*renderable.indices, geometry.indices);
    array_copy(*renderable.positions, geometry.positions);
    array_copy(*renderable.rgb_colors, geometry.rgb_colors);
    array_copy(*renderable.normals, geometry.normals);
}


deinit :: (renderable: *Camera_Per_Object_Transform_Deferred_Lighting_Geometry_Pass_Renderable, renderer: *Camera_Per_Object_Transform_Deferred_Lighting_Geometry_Pass_Renderer) {
    unbuffer_object(*renderer.psr, renderable.object_index);
    renderer.local_to_world_matrices[renderable.local_to_world_index] = Matrix4_Identity;
    array_free(renderable.indices);
    array_free(renderable.positions);
    array_free(renderable.rgb_colors);
    array_free(renderable.normals);
}


set_local_to_world_matrix :: (renderer: *Camera_Per_Object_Transform_Deferred_Lighting_Geometry_Pass_Renderer, renderable: Camera_Per_Object_Transform_Deferred_Lighting_Geometry_Pass_Renderable, matrix: Matrix4) {
    renderer.local_to_world_matrices[renderable.local_to_world_index] = matrix;
}


Camera_Per_Object_Transform_Deferred_Lighting_Geometry_Pass_Renderer :: struct {
    using #as psr : Per_Shader_Renderer;


    NUM_LOCAL_TO_WORLD_MATRICES :: 1024;
    current_local_to_world_index : u32 = 0;
    local_to_world_matrices : [NUM_LOCAL_TO_WORLD_MATRICES] Matrix4; 
    local_to_world_gl_uniform_buffer_handle : GLuint;

    local_to_world_index_buffer_gl_handle : GLuint;


    camera_to_clip_uniform_location : GLint = -1;
    world_to_camera_uniform_location : GLint = -1;

    positions_buffer_gl_handle: GLuint;
    passthrough_rgb_colors_buffer_gl_handle: GLuint;
    passthrough_normals_buffer_gl_handle: GLuint;


}


set_camera_to_clip_uniform :: (renderer : *Camera_Per_Object_Transform_Deferred_Lighting_Geometry_Pass_Renderer, v: Matrix4) {
    glUniformMatrix4fv(renderer.camera_to_clip_uniform_location, 1, GL_TRUE, *v.coef[0][0]);
}

set_world_to_camera_uniform :: (renderer : *Camera_Per_Object_Transform_Deferred_Lighting_Geometry_Pass_Renderer, v: Matrix4) {
    glUniformMatrix4fv(renderer.world_to_camera_uniform_location, 1, GL_TRUE, *v.coef[0][0]);
}

init :: (using renderer : *Camera_Per_Object_Transform_Deferred_Lighting_Geometry_Pass_Renderer) { 
    vertex_shader_source := read_entire_file("data/shaders/out/lighting/camera_per_object_transform_color_normal.vert");
    fragment_shader_source := read_entire_file("data/shaders/out/lighting/render_position_color_normal_textures.frag");

    init(renderer, vertex_shader_source, fragment_shader_source, max_num_elements_in_each_buffer);
    init_buffers_no_data(renderer);

    for 0..NUM_LOCAL_TO_WORLD_MATRICES-1
        // this might not be necessary, doing it for now
        local_to_world_matrices[it] = Matrix4_Identity;

    camera_to_clip_uniform_location = glGetUniformLocation(shader_program_gl_handle, "camera_to_clip");
    world_to_camera_uniform_location = glGetUniformLocation(shader_program_gl_handle, "world_to_camera");

}



init_buffers_no_data :: (using apcr : *Camera_Per_Object_Transform_Deferred_Lighting_Geometry_Pass_Renderer) { // todo change renderer name

    glGenVertexArrays(1, *vertex_attribute_array_gl_handle);
    glBindVertexArray(vertex_attribute_array_gl_handle);


    glGenBuffers(1, *local_to_world_gl_uniform_buffer_handle);
    glBindBuffer(GL_UNIFORM_BUFFER, local_to_world_gl_uniform_buffer_handle);
    glBufferData(GL_UNIFORM_BUFFER, local_to_world_matrices.count * size_of(Matrix4), local_to_world_matrices.data, GL_DYNAMIC_DRAW);
    glBindBufferBase(GL_UNIFORM_BUFFER, 0, local_to_world_gl_uniform_buffer_handle);

    generate_buffer_for_vertex_attribute(*local_to_world_index_buffer_gl_handle, u32, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, local_to_world_index_buffer_gl_handle, .LOCAL_TO_WORLD_INDEX);



    glGenBuffers(1, *index_buffer_gl_handle);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index_buffer_gl_handle);
    // NOTE: it's probably wrong to use  max_num_elements_in_each_buffer because as noted before the number of indices
    // could be larger than this value if we try and render all objects, but we won't care about that until it's a problem.
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, size_of(u32) *  max_num_elements_in_each_buffer, null, GL_DYNAMIC_DRAW);
    // note: we don't have to init the vertex attribute for indices because they used in the shader program for rendering, they're just used during glDrawElements.

    generate_buffer_for_vertex_attribute(*positions_buffer_gl_handle, Vector3, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, positions_buffer_gl_handle, .POSITION);

    generate_buffer_for_vertex_attribute(*passthrough_rgb_colors_buffer_gl_handle, Vector3, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, passthrough_rgb_colors_buffer_gl_handle, .PASSTHROUGH_RGB_COLOR);

    generate_buffer_for_vertex_attribute(*passthrough_normals_buffer_gl_handle, Vector3, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, passthrough_normals_buffer_gl_handle, .PASSTHROUGH_NORMAL);



	glBindBuffer (GL_ARRAY_BUFFER, 0);
}


buffer_object :: (using renderer : *Camera_Per_Object_Transform_Deferred_Lighting_Geometry_Pass_Renderer, renderable : *$T/interface Camera_Per_Object_Transform_Deferred_Lighting_Geometry_Pass_Renderable) -> success: bool {


    object_index, local_to_world_index, success := buffer_object(renderer, 
            renderable.indices, 

            renderable.positions,
            renderable.rgb_colors,
            renderable.normals
    );

    if success {
        renderable.object_index = object_index;
        renderable.local_to_world_index = local_to_world_index;

    };
    return success;
}

// todo ability to specify the transform matrix upon buffering?
buffer_object :: (
        using renderer: *Camera_Per_Object_Transform_Deferred_Lighting_Geometry_Pass_Renderer,
        indices : [..] u32,
        positions : [..] Vector3,
        rgb_colors : [..] Vector3,
        normals : [..] Vector3

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


    
    glBindBuffer(GL_ARRAY_BUFFER, passthrough_normals_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, index * size_of(Vector3), normals.count * size_of(Vector3), normals.data);


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
render :: (using renderer : *Camera_Per_Object_Transform_Deferred_Lighting_Geometry_Pass_Renderer) {

    // todo think about if we should be using temporary storage.

    glUseProgram(shader_program_gl_handle);

    glBindBuffer(GL_UNIFORM_BUFFER, local_to_world_gl_uniform_buffer_handle);
    glBufferSubData(GL_UNIFORM_BUFFER, 0, size_of(Matrix4) * current_local_to_world_index, local_to_world_matrices.data);


    glBindVertexArray(vertex_attribute_array_gl_handle);
    // todo: reserve so we don't get a ton of reallocations in this for loop
    geom_indices_to_render : [..] u32; 
    // array_reserve(*geom_indices_to_render, ???); // needs some running count whenever we buffer an obj.
    for object_indices_to_render_this_frame {
        geom_indices , success := table_find(*buffered_object_index_to_global_indices, it);
        if !success log("couldn't find the global indices of object with id: ", it);
        for geom_indices 
            array_add(*geom_indices_to_render, it);
    }


    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index_buffer_gl_handle);
    // here we're just overwriting the buffer on each draw call, if there's less data written than last iteration it's fine
    // as we will only access the smaller portion
    glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, 0, geom_indices_to_render.count * size_of(u32), geom_indices_to_render.data);

    glDrawElements(GL_TRIANGLES, xx geom_indices_to_render.count, GL_UNSIGNED_INT, cast (*void) 0);

    // the rendering the same objects test as last frame test is a worthwhile optimization that should occur.

    array_reset(*object_indices_to_render_this_frame);

    glBindVertexArray(0);
    glUseProgram(0);
}

