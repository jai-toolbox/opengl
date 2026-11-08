// auto-generated renderer for shader: Camera_Infinite_Grid
// do not edit manually.

Camera_Infinite_Grid_Renderer :: struct {
    shader_program_gl_handle : GLuint;
    vertex_attribute_array_gl_handle : GLuint;
    camera_to_clip_uniform_location : GLint = -1;
    world_to_camera_uniform_location : GLint = -1;
    camera_position_uniform_location : GLint = -1;
    grid_size_uniform_location : GLint = -1;
    grid_plane_uniform_location : GLint = -1;
    grid_clip_depth_offset_uniform_location : GLint = -1;
    grid_at_far_depth_uniform_location : GLint = -1;
    grid_pass_alpha_uniform_location : GLint = -1;
}


set_camera_to_clip_uniform :: (renderer : *Camera_Infinite_Grid_Renderer, v: Matrix4) {
    gl_set_uniform_matrix_4fv_on_active_shader_program(renderer.camera_to_clip_uniform_location, 1, GL_TRUE, *v.coef[0][0]);
}

set_world_to_camera_uniform :: (renderer : *Camera_Infinite_Grid_Renderer, v: Matrix4) {
    gl_set_uniform_matrix_4fv_on_active_shader_program(renderer.world_to_camera_uniform_location, 1, GL_TRUE, *v.coef[0][0]);
}

set_camera_position_uniform :: (renderer : *Camera_Infinite_Grid_Renderer, v: Vector3) {
    gl_set_uniform_3f_on_active_shader_program(renderer.camera_position_uniform_location, v.x, v.y, v.z);
}

set_grid_size_uniform :: (renderer : *Camera_Infinite_Grid_Renderer, v: float32) {
    gl_set_uniform_1f_on_active_shader_program(renderer.grid_size_uniform_location, v);
}

set_grid_plane_uniform :: (renderer : *Camera_Infinite_Grid_Renderer, v: s32) {
    gl_set_uniform_1i_on_active_shader_program(renderer.grid_plane_uniform_location, v);
}

set_grid_clip_depth_offset_uniform :: (renderer : *Camera_Infinite_Grid_Renderer, v: float32) {
    gl_set_uniform_1f_on_active_shader_program(renderer.grid_clip_depth_offset_uniform_location, v);
}

set_grid_at_far_depth_uniform :: (renderer : *Camera_Infinite_Grid_Renderer, v: bool) {
    gl_set_uniform_1i_on_active_shader_program(renderer.grid_at_far_depth_uniform_location, xx v);
}

set_grid_pass_alpha_uniform :: (renderer : *Camera_Infinite_Grid_Renderer, v: float32) {
    gl_set_uniform_1f_on_active_shader_program(renderer.grid_pass_alpha_uniform_location, v);
}
init :: (using renderer : *Camera_Infinite_Grid_Renderer) -> bool {
    success : bool;
    shader_program_gl_handle, success = create_shader_program(#run read_entire_file(tprint("%../shaders/out/infinite_grid.vert", #filepath)), #run read_entire_file(tprint("%../shaders/out/infinite_grid.frag", #filepath)));
    if !success return false;
    // OpenGL core profile requires a bound VAO even when the vertex shader uses
    // gl_VertexID and supplies every vertex itself. This VAO has no buffers.
    vertex_attribute_array_gl_handle = gl_create_vertex_array();
    camera_to_clip_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "camera_to_clip");
    world_to_camera_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "world_to_camera");
    camera_position_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "camera_position");
    grid_size_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "grid_size");
    grid_plane_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "grid_plane");
    grid_clip_depth_offset_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "grid_clip_depth_offset");
    grid_at_far_depth_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "grid_at_far_depth");
    grid_pass_alpha_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "grid_pass_alpha");

    return true;
}

deinit :: (renderer : *Camera_Infinite_Grid_Renderer) {
    gl_delete_vertex_array(renderer.vertex_attribute_array_gl_handle);
    gl_delete_shader_program(renderer.shader_program_gl_handle);
    renderer.* = .{};
}
render :: (renderer : *Camera_Infinite_Grid_Renderer, vertex_count : GLsizei = 6) {
    assert(vertex_count >= 0);
    gl_set_active_shader_program(renderer.shader_program_gl_handle);
    gl_bind_vertex_array(renderer.vertex_attribute_array_gl_handle);
    gl_draw_vertices_from_bound_vertex_array(GL_TRIANGLES, 0, vertex_count);
    gl_bind_vertex_array(0);
    gl_clear_active_shader_program();
}
