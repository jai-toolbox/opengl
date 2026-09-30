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

so deinit exists but also unbuffer object exists, the difference is that deinit takes in a renderable and frees its CPU-side arrays and resets its transform slot, whereas unbuffer_object only frees the GPU-side virtual allocation, leaving the CPU data intact for potential re-buffering later.

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
    gl_set_uniform_1f_on_active_shader_program(renderer.angle_uniform_location, v);
}

set_camera_position_uniform :: (renderer : *Lit_Color_Renderer, v: Vector3) {
    gl_set_uniform_3f_on_active_shader_program(renderer.camera_position_uniform_location, v.x, v.y, v.z);
}

set_light_direction_uniform :: (renderer : *Lit_Color_Renderer, v: Vector3) {
    gl_set_uniform_3f_on_active_shader_program(renderer.light_direction_uniform_location, v.x, v.y, v.z);
}

set_ambient_uniform :: (renderer : *Lit_Color_Renderer, v: float32) {
    gl_set_uniform_1f_on_active_shader_program(renderer.ambient_uniform_location, v);
}

init :: (using renderer : *Lit_Color_Renderer) {
    vertex_shader_source := #run read_entire_file(tprint("%../shaders/generated/lit_color.vert", #filepath));
    fragment_shader_source := #run read_entire_file(tprint("%../shaders/generated/lit_color.frag", #filepath));

    init(renderer, vertex_shader_source, fragment_shader_source, max_num_elements_in_each_buffer);
    init_buffers_no_data(renderer);


    angle_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "angle");
    camera_position_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "camera_position");
    light_direction_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "light_direction");
    ambient_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "ambient");

}


deinit :: (using renderer : *Lit_Color_Renderer) {
    deinit(*psr);

    gl_delete_buffer(positions_buffer_gl_handle);
    gl_delete_buffer(normals_buffer_gl_handle);
    gl_delete_buffer(colors_buffer_gl_handle);
}



init_buffers_no_data :: (using apcr : *Lit_Color_Renderer) { // todo change renderer name

    vertex_attribute_array_gl_handle = gl_create_vertex_array();
    gl_bind_vertex_array(vertex_attribute_array_gl_handle);



    index_buffer_gl_handle = gl_create_buffer();
    gl_bind_buffer_to_binding_target(GL_ELEMENT_ARRAY_BUFFER, index_buffer_gl_handle);
    // NOTE: it's probably wrong to use  max_num_elements_in_each_buffer because as noted before the number of indices
    // could be larger than this value if we try and render all objects, but we won't care about that until it's a problem.
    gl_allocate_storage_for_buffer_bound_to_binding_target(GL_ELEMENT_ARRAY_BUFFER, size_of(u32) * max_num_elements_in_each_buffer, null, GL_DYNAMIC_DRAW);
    index_buffer_capacity_in_indices = cast(int) max_num_elements_in_each_buffer;
    // note: we don't have to init the vertex attribute for indices because they used in the shader program for rendering, they're just used during glDrawElements.

    generate_buffer_for_vertex_attribute(*positions_buffer_gl_handle, Vector3, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, positions_buffer_gl_handle, "position", 3, GL_FLOAT, GL_FALSE, 0, null);

    generate_buffer_for_vertex_attribute(*normals_buffer_gl_handle, Vector3, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, normals_buffer_gl_handle, "normal", 3, GL_FLOAT, GL_FALSE, 0, null);

    generate_buffer_for_vertex_attribute(*colors_buffer_gl_handle, Vector3, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, colors_buffer_gl_handle, "color", 3, GL_FLOAT, GL_FALSE, 0, null);



	gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, 0);
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
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, index * size_of(Vector3), positions.count * size_of(Vector3), positions.data);



    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, normals_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, index * size_of(Vector3), normals.count * size_of(Vector3), normals.data);



    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, colors_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, index * size_of(Vector3), colors.count * size_of(Vector3), colors.data);




    gl_bind_vertex_array(0);

    return index, true;
}

/*

so this function is kinda sketchy right now, you can only rebuffer an object if it takes up the exact same size,
if you're rebuffering things and using up more space then you did before you'll start having undefined behavior in rendering and things
will go off the rails.

*/
rebuffer_object :: (using renderer : *Lit_Color_Renderer, renderable : $T/interface Lit_Color_Renderable) {

    gl_bind_vertex_array(vertex_attribute_array_gl_handle);

    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, positions_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, renderable.object_index * size_of(Vector3), renderable.positions.count * size_of(Vector3), renderable.positions.data);

    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, normals_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, renderable.object_index * size_of(Vector3), renderable.normals.count * size_of(Vector3), renderable.normals.data);

    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, colors_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, renderable.object_index * size_of(Vector3), renderable.colors.count * size_of(Vector3), renderable.colors.data);


    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, 0);
    gl_bind_vertex_array(0);
}

render :: (using renderer : *Lit_Color_Renderer, primitive_mode: GLenum = GL_TRIANGLES) {

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
