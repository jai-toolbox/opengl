// Offscreen HDR color target with a depth attachment.
// The caller controls draw state, viewport and presentation.
Render_Target :: struct {
    framebuffer, color_texture, depth_buffer : GLuint;
    width, height : s32;
}

init_render_target :: (r : *Render_Target) {
    free_render_target(r);
    r.framebuffer = gl_create_framebuffer();
    r.color_texture = gl_create_texture();
    r.depth_buffer = gl_create_renderbuffer();
}

free_render_target :: (r : *Render_Target) {
    gl_delete_framebuffer(r.framebuffer);
    gl_delete_texture(r.color_texture);
    gl_delete_renderbuffer(r.depth_buffer);
    r.* = .{};
}

resize_render_target :: (r : *Render_Target, width : s32, height : s32) {
    if width == r.width && height == r.height return;
    r.width = width; r.height = height;
    gl_set_active_texture_unit(GL_TEXTURE0);
    gl_bind_texture_to_binding_target_of_active_texture_unit(GL_TEXTURE_2D, r.color_texture);
    gl_define_texture_2d_image_for_active_texture_unit(GL_TEXTURE_2D, 0, GL_RGBA32F, xx width, xx height, 0, GL_RGBA, GL_FLOAT, null);
    gl_set_integer_parameter_for_texture_bound_to_binding_target_of_active_texture_unit(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    gl_set_integer_parameter_for_texture_bound_to_binding_target_of_active_texture_unit(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    gl_set_integer_parameter_for_texture_bound_to_binding_target_of_active_texture_unit(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    gl_set_integer_parameter_for_texture_bound_to_binding_target_of_active_texture_unit(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    gl_bind_framebuffer_to_binding_target(GL_FRAMEBUFFER, r.framebuffer);
    gl_attach_2d_texture_image_to_framebuffer_bound_to_binding_target(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, r.color_texture, 0);
    gl_bind_renderbuffer(r.depth_buffer);
    gl_allocate_storage_for_bound_renderbuffer(GL_DEPTH_COMPONENT24, xx width, xx height);
    gl_attach_renderbuffer_to_framebuffer_bound_to_binding_target(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, r.depth_buffer);
    gl_bind_renderbuffer(0);
    assert(gl_get_status_of_framebuffer_bound_to_binding_target(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE);
    gl_bind_framebuffer_to_binding_target(GL_FRAMEBUFFER, 0);
}

clear_render_target :: (r : *Render_Target, color : Vector4) {
    gl_bind_framebuffer_to_binding_target(GL_FRAMEBUFFER, r.framebuffer);
    gl_set_framebuffer_srgb(false);
    gl_set_color_buffer_clear_value(color.x, color.y, color.z, color.w);
    gl_clear_color_buffer();
    gl_bind_framebuffer_to_binding_target(GL_FRAMEBUFFER, 0);
}
