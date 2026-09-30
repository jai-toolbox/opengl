enable_wireframe_mode :: () { glPolygonMode(GL_FRONT_AND_BACK, GL_LINE); }
disable_wireframe_mode :: () { glPolygonMode(GL_FRONT_AND_BACK, GL_FILL); }

gl_set_depth_writes_enabled :: glDepthMask;
gl_set_depth_test_pass_condition :: glDepthFunc;

gl_discard_fragments_that_fail_depth_test :: (enabled: bool) {
    if enabled then glEnable(GL_DEPTH_TEST);
    else glDisable(GL_DEPTH_TEST);
}

gl_enable_blending :: () { glEnable(GL_BLEND); }
gl_disable_blending :: () { glDisable(GL_BLEND); }

gl_set_blend_function :: (source_factor: GLenum, destination_factor: GLenum) {
    glBlendFunc(source_factor, destination_factor);
}

gl_set_separate_blend_function :: (
    source_rgb_factor: GLenum,
    destination_rgb_factor: GLenum,
    source_alpha_factor: GLenum,
    destination_alpha_factor: GLenum,
) {
    glBlendFuncSeparate(
        source_rgb_factor,
        destination_rgb_factor,
        source_alpha_factor,
        destination_alpha_factor,
    );
}

gl_clear_depth_buffer :: () { glClear(GL_DEPTH_BUFFER_BIT); }

gl_set_active_shader_program :: (program: GLuint) { glUseProgram(program); }
gl_clear_active_shader_program :: () { glUseProgram(0); }
gl_delete_shader_program :: (program: GLuint) { glDeleteProgram(program); }

gl_set_active_texture_unit :: (texture_unit: GLenum) {
    glActiveTexture(texture_unit);
}

gl_bind_texture_to_binding_target_of_active_texture_unit :: (target: GLenum, texture: GLuint) {
    glBindTexture(target, texture);
}

gl_define_texture_2d_image_for_active_texture_unit :: glTexImage2D;
gl_set_integer_parameter_for_texture_bound_to_binding_target_of_active_texture_unit :: glTexParameteri;

gl_define_1d_image_for_texture_bound_to_binding_target_of_active_texture_unit :: (
    binding_target: GLenum,
    mipmap_level: GLint,
    internal_format: GLint,
    width: GLsizei,
    border: GLint,
    pixel_format: GLenum,
    pixel_data_type: GLenum,
    pixels: *void,
) {
    glTexImage1D(
        binding_target,
        mipmap_level,
        internal_format,
        width,
        border,
        pixel_format,
        pixel_data_type,
        pixels,
    );
}

gl_define_3d_image_for_texture_bound_to_binding_target_of_active_texture_unit :: (
    binding_target: GLenum,
    mipmap_level: GLint,
    internal_format: GLint,
    width: GLsizei,
    height: GLsizei,
    depth: GLsizei,
    border: GLint,
    pixel_format: GLenum,
    pixel_data_type: GLenum,
    pixels: *void,
) {
    glTexImage3D(
        binding_target,
        mipmap_level,
        internal_format,
        width,
        height,
        depth,
        border,
        pixel_format,
        pixel_data_type,
        pixels,
    );
}

gl_update_3d_subimage_of_texture_bound_to_binding_target_of_active_texture_unit :: (
    binding_target: GLenum,
    mipmap_level: GLint,
    x_offset: GLint,
    y_offset: GLint,
    z_offset: GLint,
    width: GLsizei,
    height: GLsizei,
    depth: GLsizei,
    pixel_format: GLenum,
    pixel_data_type: GLenum,
    pixels: *void,
) {
    glTexSubImage3D(
        binding_target,
        mipmap_level,
        x_offset,
        y_offset,
        z_offset,
        width,
        height,
        depth,
        pixel_format,
        pixel_data_type,
        pixels,
    );
}

gl_set_float_parameter_for_texture_bound_to_binding_target_of_active_texture_unit :: (
    binding_target: GLenum,
    parameter_name: GLenum,
    parameter_value: GLfloat,
) {
    glTexParameterf(binding_target, parameter_name, parameter_value);
}

gl_set_float_vector_parameter_for_texture_bound_to_binding_target_of_active_texture_unit :: (
    binding_target: GLenum,
    parameter_name: GLenum,
    parameter_values: *GLfloat,
) {
    glTexParameterfv(binding_target, parameter_name, parameter_values);
}

gl_get_float_values_for_state_parameter :: (
    parameter_name: GLenum,
    values: *GLfloat,
) {
    glGetFloatv(parameter_name, values);
}

gl_set_integer_pixel_storage_parameter :: (
    parameter_name: GLenum,
    parameter_value: GLint,
) {
    glPixelStorei(parameter_name, parameter_value);
}

gl_create_texture :: () -> GLuint {
    texture: GLuint;
    glGenTextures(1, *texture);
    return texture;
}

gl_create_textures :: (textures: [] GLuint) {
    if textures.count == 0 return;
    glGenTextures(cast(GLsizei) textures.count, textures.data);
}

gl_delete_texture :: (texture: GLuint) {
    glDeleteTextures(1, *texture);
}

gl_delete_textures :: (textures: [] GLuint) {
    if textures.count == 0 return;
    glDeleteTextures(cast(GLsizei) textures.count, textures.data);
}

gl_create_framebuffer :: () -> GLuint {
    framebuffer: GLuint;
    glGenFramebuffers(1, *framebuffer);
    return framebuffer;
}

gl_delete_framebuffer :: (framebuffer: GLuint) {
    glDeleteFramebuffers(1, *framebuffer);
}

gl_create_renderbuffer :: () -> GLuint {
    renderbuffer: GLuint;
    glGenRenderbuffers(1, *renderbuffer);
    return renderbuffer;
}

gl_delete_renderbuffer :: (renderbuffer: GLuint) {
    glDeleteRenderbuffers(1, *renderbuffer);
}

gl_create_vertex_array :: () -> GLuint {
    vertex_array: GLuint;
    glGenVertexArrays(1, *vertex_array);
    return vertex_array;
}

gl_delete_vertex_array :: (vertex_array: GLuint) {
    glDeleteVertexArrays(1, *vertex_array);
}

gl_create_buffer :: () -> GLuint {
    buffer: GLuint;
    glGenBuffers(1, *buffer);
    return buffer;
}

gl_delete_buffer :: (buffer: GLuint) {
    glDeleteBuffers(1, *buffer);
}

gl_allocate_storage_for_buffer_bound_to_binding_target :: (
    binding_target: GLenum,
    byte_count: GLsizeiptr,
    initial_data: *void,
    usage: GLenum,
) {
    glBufferData(binding_target, byte_count, initial_data, usage);
}

gl_bind_framebuffer_to_binding_target :: (
    binding_target: GLenum,
    framebuffer: GLuint,
) {
    glBindFramebuffer(binding_target, framebuffer);
}

gl_bind_renderbuffer :: (renderbuffer: GLuint) {
    glBindRenderbuffer(GL_RENDERBUFFER, renderbuffer);
}

gl_allocate_storage_for_bound_renderbuffer :: (
    internal_format: GLenum,
    width: GLsizei,
    height: GLsizei,
) {
    glRenderbufferStorage(GL_RENDERBUFFER, internal_format, width, height);
}

gl_attach_renderbuffer_to_framebuffer_bound_to_binding_target :: (
    framebuffer_binding_target: GLenum,
    attachment: GLenum,
    renderbuffer: GLuint,
) {
    glFramebufferRenderbuffer(
        framebuffer_binding_target,
        attachment,
        GL_RENDERBUFFER,
        renderbuffer,
    );
}

gl_attach_2d_texture_image_to_framebuffer_bound_to_binding_target :: (
    framebuffer_binding_target: GLenum,
    attachment: GLenum,
    texture_image_target: GLenum,
    texture: GLuint,
    mipmap_level: GLint,
) {
    glFramebufferTexture2D(
        framebuffer_binding_target,
        attachment,
        texture_image_target,
        texture,
        mipmap_level,
    );
}

gl_get_status_of_framebuffer_bound_to_binding_target :: (
    binding_target: GLenum,
) -> GLenum {
    return glCheckFramebufferStatus(binding_target);
}

gl_set_draw_buffer_for_bound_draw_framebuffer :: (draw_buffer: GLenum) {
    glDrawBuffer(draw_buffer);
}

gl_set_read_buffer_for_bound_read_framebuffer :: (read_buffer: GLenum) {
    glReadBuffer(read_buffer);
}

gl_set_viewport_rectangle :: (
    x: GLint,
    y: GLint,
    width: GLsizei,
    height: GLsizei,
) {
    glViewport(x, y, width, height);
}

gl_set_color_buffer_clear_value :: (
    red: GLfloat,
    green: GLfloat,
    blue: GLfloat,
    alpha: GLfloat,
) {
    glClearColor(red, green, blue, alpha);
}

gl_clear_color_and_depth_buffers :: () {
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

gl_generate_mipmap_levels_for_texture_bound_to_binding_target_of_active_texture_unit :: (
    binding_target: GLenum,
) {
    glGenerateMipmap(binding_target);
}

gl_read_pixels_from_bound_read_framebuffer :: (
    x: GLint,
    y: GLint,
    width: GLsizei,
    height: GLsizei,
    pixel_format: GLenum,
    pixel_data_type: GLenum,
    destination: *void,
) {
    glReadPixels(
        x, y, width, height,
        pixel_format, pixel_data_type, destination,
    );
}

gl_set_pixel_readback_row_alignment :: (alignment: GLint) {
    glPixelStorei(GL_PACK_ALIGNMENT, alignment);
}

gl_get_uniform_location_in_shader_program :: (
    shader_program: GLuint,
    uniform_name: *GLchar,
) -> GLint {
    return glGetUniformLocation(shader_program, uniform_name);
}
gl_bind_vertex_array :: (vertex_array: GLuint) {
    glBindVertexArray(vertex_array);
}

gl_bind_buffer_to_binding_target :: (binding_target: GLenum, buffer: GLuint) {
    glBindBuffer(binding_target, buffer);
}

gl_update_subdata_in_buffer_bound_to_binding_target :: (
    binding_target: GLenum,
    byte_offset: GLintptr,
    byte_count: GLsizeiptr,
    data: *void,
) {
    glBufferSubData(binding_target, byte_offset, byte_count, data);
}

gl_get_vertex_attribute_location_in_shader_program :: (
    shader_program: GLuint,
    attribute_name: *GLchar,
) -> GLint {
    return glGetAttribLocation(shader_program, attribute_name);
}

gl_enable_vertex_attribute_array :: (attribute_index: GLuint) {
    glEnableVertexAttribArray(attribute_index);
}

gl_define_vertex_attribute_pointer :: (
    attribute_index: GLuint,
    component_count: GLint,
    component_type: GLenum,
    normalized: GLboolean,
    byte_stride: GLsizei,
    pointer: *void,
) {
    glVertexAttribPointer(
        attribute_index,
        component_count,
        component_type,
        normalized,
        byte_stride,
        pointer,
    );
}

gl_define_integer_vertex_attribute_pointer :: (
    attribute_index: GLuint,
    component_count: GLint,
    component_type: GLenum,
    byte_stride: GLsizei,
    pointer: *void,
) {
    glVertexAttribIPointer(
        attribute_index,
        component_count,
        component_type,
        byte_stride,
        pointer,
    );
}

gl_draw_vertices_from_bound_vertex_array :: (
    primitive_mode: GLenum,
    first_vertex: GLint,
    vertex_count: GLsizei,
) {
    glDrawArrays(primitive_mode, first_vertex, vertex_count);
}

gl_draw_indexed_vertices_from_bound_vertex_array :: (
    primitive_mode: GLenum,
    index_count: GLsizei,
    index_type: GLenum,
    indices: *void,
) {
    glDrawElements(primitive_mode, index_count, index_type, indices);
}

GL_Framebuffer_State :: struct {
    draw_framebuffer: GLuint;
    read_framebuffer: GLuint;
    viewport: [4] GLint;
    draw_buffer: GLenum;
    read_buffer: GLenum;
}

gl_capture_framebuffer_state :: () -> GL_Framebuffer_State {
    result: GL_Framebuffer_State;
    integer_value: GLint;

    glGetIntegerv(GL_DRAW_FRAMEBUFFER_BINDING, *integer_value);
    result.draw_framebuffer = cast(GLuint) integer_value;
    glGetIntegerv(GL_READ_FRAMEBUFFER_BINDING, *integer_value);
    result.read_framebuffer = cast(GLuint) integer_value;
    glGetIntegerv(GL_VIEWPORT, result.viewport.data);
    glGetIntegerv(GL_DRAW_BUFFER, *integer_value);
    result.draw_buffer = cast(GLenum) integer_value;
    glGetIntegerv(GL_READ_BUFFER, *integer_value);
    result.read_buffer = cast(GLenum) integer_value;

    return result;
}

gl_restore_framebuffer_state :: (state: GL_Framebuffer_State) {
    gl_bind_framebuffer_to_binding_target(GL_DRAW_FRAMEBUFFER, state.draw_framebuffer);
    gl_set_draw_buffer_for_bound_draw_framebuffer(state.draw_buffer);
    gl_bind_framebuffer_to_binding_target(GL_READ_FRAMEBUFFER, state.read_framebuffer);
    gl_set_read_buffer_for_bound_read_framebuffer(state.read_buffer);
    gl_set_viewport_rectangle(
        state.viewport[0],
        state.viewport[1],
        cast(GLsizei) state.viewport[2],
        cast(GLsizei) state.viewport[3],
    );
}

gl_set_uniform_1f_on_active_shader_program :: (location: GLint, value: GLfloat) {
    glUniform1f(location, value);
}

gl_set_uniform_1i_on_active_shader_program :: (location: GLint, value: GLint) {
    glUniform1i(location, value);
}

gl_set_uniform_1ui_on_active_shader_program :: (location: GLint, value: GLuint) {
    glUniform1ui(location, value);
}

gl_set_uniform_2f_on_active_shader_program :: (location: GLint, x: GLfloat, y: GLfloat) {
    glUniform2f(location, x, y);
}

gl_set_uniform_3f_on_active_shader_program :: (location: GLint, x: GLfloat, y: GLfloat, z: GLfloat) {
    glUniform3f(location, x, y, z);
}

gl_set_uniform_4f_on_active_shader_program :: (location: GLint, x: GLfloat, y: GLfloat, z: GLfloat, w: GLfloat) {
    glUniform4f(location, x, y, z, w);
}

gl_set_uniform_matrix_3fv_on_active_shader_program :: (location: GLint, count: GLsizei, transpose: GLboolean, values: *GLfloat) {
    glUniformMatrix3fv(location, count, transpose, values);
}

gl_set_uniform_matrix_4fv_on_active_shader_program :: (location: GLint, count: GLsizei, transpose: GLboolean, values: *GLfloat) {
    glUniformMatrix4fv(location, count, transpose, values);
}
