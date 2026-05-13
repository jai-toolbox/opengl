// auto-generated renderer for shader: Object_Id_Selection_Outline
// do not edit manually.


Object_Id_Selection_Outline_Renderer :: struct {
    using #as psr : Per_Shader_Renderer;


    using #as ltw_pool : Local_To_World_Matrix_Pool;

    local_to_world_index_buffer_gl_handle : GLuint;


    object_id_texture_uniform_location : GLint = -1;
    selected_object_id_uniform_location : GLint = -1;
    rgba_color_uniform_location : GLint = -1;
    thickness_px_uniform_location : GLint = -1;



}


set_object_id_texture_uniform :: (renderer : *Object_Id_Selection_Outline_Renderer, v: s32) {
    glUniform1i(renderer.object_id_texture_uniform_location, v);
}

set_selected_object_id_uniform :: (renderer : *Object_Id_Selection_Outline_Renderer, v: u32) {
    glUniform1ui(renderer.selected_object_id_uniform_location, v);
}

set_rgba_color_uniform :: (renderer : *Object_Id_Selection_Outline_Renderer, v: Vector4) {
    glUniform4f(renderer.rgba_color_uniform_location, v.x, v.y, v.z, v.w);
}

set_thickness_px_uniform :: (renderer : *Object_Id_Selection_Outline_Renderer, v: u32) {
    glUniform1ui(renderer.thickness_px_uniform_location, v);
}

init :: (using renderer : *Object_Id_Selection_Outline_Renderer) { 
    vertex_shader_loaded, vertex_shader_source := load_asset("data/shaders/out/fullscreen_quad.vert");
    assert(vertex_shader_loaded, "Failed to load vertex shader asset: data/shaders/out/fullscreen_quad.vert");
    fragment_shader_loaded, fragment_shader_source := load_asset("data/shaders/out/object_id_selection_outline.frag");
    assert(fragment_shader_loaded, "Failed to load fragment shader asset: data/shaders/out/object_id_selection_outline.frag");

    init(renderer, vertex_shader_source, fragment_shader_source, max_num_elements_in_each_buffer);

    init(*renderer.ltw_pool);

    object_id_texture_uniform_location = glGetUniformLocation(shader_program_gl_handle, "object_id_texture");
    selected_object_id_uniform_location = glGetUniformLocation(shader_program_gl_handle, "selected_object_id");
    rgba_color_uniform_location = glGetUniformLocation(shader_program_gl_handle, "rgba_color");
    thickness_px_uniform_location = glGetUniformLocation(shader_program_gl_handle, "thickness_px");

}


deinit :: (using renderer : *Object_Id_Selection_Outline_Renderer) {
    deinit(*ltw_pool);

    deinit(*psr);

    glDeleteBuffers(1, *local_to_world_index_buffer_gl_handle);
}

