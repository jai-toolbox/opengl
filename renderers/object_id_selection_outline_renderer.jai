// auto-generated renderer for shader: Object_Id_Selection_Outline
// do not edit manually.


Object_Id_Selection_Outline_Renderer :: struct {
    using #as psr : Per_Shader_Renderer;


    using #as ltw_pool : Local_To_World_Matrix_Pool;

    local_to_world_index_buffer_gl_handle : GLuint;


    selected_depth_texture_uniform_location : GLint = -1;
    scene_depth_texture_uniform_location : GLint = -1;
    rgba_color_uniform_location : GLint = -1;
    occluded_alpha_uniform_location : GLint = -1;
    depth_epsilon_uniform_location : GLint = -1;
    thickness_px_uniform_location : GLint = -1;



}


set_selected_depth_texture_uniform :: (renderer : *Object_Id_Selection_Outline_Renderer, v: s32) {
    gl_set_uniform_1i_on_active_shader_program(renderer.selected_depth_texture_uniform_location, v);
}

set_scene_depth_texture_uniform :: (renderer : *Object_Id_Selection_Outline_Renderer, v: s32) {
    gl_set_uniform_1i_on_active_shader_program(renderer.scene_depth_texture_uniform_location, v);
}

set_rgba_color_uniform :: (renderer : *Object_Id_Selection_Outline_Renderer, v: Vector4) {
    gl_set_uniform_4f_on_active_shader_program(renderer.rgba_color_uniform_location, v.x, v.y, v.z, v.w);
}

set_occluded_alpha_uniform :: (renderer : *Object_Id_Selection_Outline_Renderer, v: float32) {
    gl_set_uniform_1f_on_active_shader_program(renderer.occluded_alpha_uniform_location, v);
}

set_depth_epsilon_uniform :: (renderer : *Object_Id_Selection_Outline_Renderer, v: float32) {
    gl_set_uniform_1f_on_active_shader_program(renderer.depth_epsilon_uniform_location, v);
}

set_thickness_px_uniform :: (renderer : *Object_Id_Selection_Outline_Renderer, v: u32) {
    gl_set_uniform_1ui_on_active_shader_program(renderer.thickness_px_uniform_location, v);
}

init :: (using renderer : *Object_Id_Selection_Outline_Renderer) {
    vertex_shader_source := #run read_entire_file(tprint("%../shaders/out/fullscreen_quad.vert", #filepath));
    fragment_shader_source := #run read_entire_file(tprint("%../shaders/out/object_id_selection_outline.frag", #filepath));

    init(renderer, vertex_shader_source, fragment_shader_source, max_num_elements_in_each_buffer);

    init(*renderer.ltw_pool);

    selected_depth_texture_uniform_location = glGetUniformLocation(shader_program_gl_handle, "selected_depth_texture");
    scene_depth_texture_uniform_location = glGetUniformLocation(shader_program_gl_handle, "scene_depth_texture");
    rgba_color_uniform_location = glGetUniformLocation(shader_program_gl_handle, "rgba_color");
    occluded_alpha_uniform_location = glGetUniformLocation(shader_program_gl_handle, "occluded_alpha");
    depth_epsilon_uniform_location = glGetUniformLocation(shader_program_gl_handle, "depth_epsilon");
    thickness_px_uniform_location = glGetUniformLocation(shader_program_gl_handle, "thickness_px");

}


deinit :: (using renderer : *Object_Id_Selection_Outline_Renderer) {
    deinit(*ltw_pool);

    deinit(*psr);

    glDeleteBuffers(1, *local_to_world_index_buffer_gl_handle);
}
