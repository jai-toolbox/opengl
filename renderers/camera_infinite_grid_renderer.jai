// auto-generated renderer for shader: Camera_Infinite_Grid
// do not edit manually.


Camera_Infinite_Grid_Renderer :: struct {
    using #as psr : Per_Shader_Renderer;


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

init :: (using renderer : *Camera_Infinite_Grid_Renderer) {
    vertex_shader_source := #run read_entire_file(tprint("%../shaders/out/infinite_grid.vert", #filepath));
    fragment_shader_source := #run read_entire_file(tprint("%../shaders/out/infinite_grid.frag", #filepath));

    init(renderer, vertex_shader_source, fragment_shader_source, max_num_elements_in_each_buffer);


    camera_to_clip_uniform_location = glGetUniformLocation(shader_program_gl_handle, "camera_to_clip");
    world_to_camera_uniform_location = glGetUniformLocation(shader_program_gl_handle, "world_to_camera");
    camera_position_uniform_location = glGetUniformLocation(shader_program_gl_handle, "camera_position");
    grid_size_uniform_location = glGetUniformLocation(shader_program_gl_handle, "grid_size");
    grid_plane_uniform_location = glGetUniformLocation(shader_program_gl_handle, "grid_plane");
    grid_clip_depth_offset_uniform_location = glGetUniformLocation(shader_program_gl_handle, "grid_clip_depth_offset");
    grid_at_far_depth_uniform_location = glGetUniformLocation(shader_program_gl_handle, "grid_at_far_depth");
    grid_pass_alpha_uniform_location = glGetUniformLocation(shader_program_gl_handle, "grid_pass_alpha");

}


deinit :: (using renderer : *Camera_Infinite_Grid_Renderer) {
    deinit(*psr);

}
