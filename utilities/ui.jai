#scope_file
#import "stb_image";
UI     :: #import "tbx/ui";
#scope_export

OpenGL_UI_Image_Renderer :: struct {
    shader_program: GLuint;
    vertex_array: GLuint;
    index_buffer: GLuint;
    position_buffer: GLuint;
    texture_coordinate_buffer: GLuint;
    rgba_color_buffer: GLuint;
    texture_sampler_uniform_location: GLint = -1;
}

OpenGL_UI_Renderer :: struct {
    geometry_renderer: Absolute_Position_Color_Alpha_Renderer;
    text_renderer: Multi_Channel_Signed_Distance_Field_Text_Renderer;
    image_renderer: OpenGL_UI_Image_Renderer;
    font_atlas_texture: GLuint;
    text_screen_pixels_per_distance_range_uniform_location: GLint = -1;
    text_vertex_capacity: s64 = UI.UI_RENDER_BATCH_MAX_VERTICES;
    text_index_capacity: s64 = UI.UI_RENDER_BATCH_MAX_INDICES;
}

OPENGL_UI_IMAGE_VERTEX_SHADER :: #string END
#version 330 core
in vec3 position;
in vec2 texture_coordinate_in;
in vec4 rgba_color_in;
out vec2 texture_coordinate;
out vec4 rgba_color;
void main() {
    texture_coordinate = texture_coordinate_in;
    rgba_color = rgba_color_in;
    gl_Position = vec4(position.xy, 0.0, 1.0);
}
END

OPENGL_UI_IMAGE_FRAGMENT_SHADER :: #string END
#version 330 core
in vec2 texture_coordinate;
in vec4 rgba_color;
uniform sampler2D texture_sampler;
out vec4 fragment_color;
void main() {
    fragment_color = texture(texture_sampler, texture_coordinate) * rgba_color;
}
END

init_opengl_ui_image_renderer_attribute :: (
    shader_program: GLuint,
    vertex_array: GLuint,
    buffer: GLuint,
    name: *u8,
    component_count: GLint
) {
    gl_bind_vertex_array(vertex_array);
    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, buffer);
    location := glGetAttribLocation(shader_program, name);
    if location >= 0 {
        glEnableVertexAttribArray(cast(GLuint) location);
        glVertexAttribPointer(cast(GLuint) location, component_count, GL_FLOAT, GL_FALSE, 0, null);
    }
    gl_bind_vertex_array(0);
}

init_opengl_ui_image_renderer_buffer :: (buffer: *GLuint, element_size: s64) {
    glGenBuffers(1, buffer);
    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, buffer.*);
    glBufferData(GL_ARRAY_BUFFER, UI.UI_RENDER_BATCH_MAX_VERTICES * element_size, null, GL_STREAM_DRAW);
}

init :: (renderer: *OpenGL_UI_Image_Renderer) -> success: bool {
    shader_program, shader_ok := create_shader_program(OPENGL_UI_IMAGE_VERTEX_SHADER, OPENGL_UI_IMAGE_FRAGMENT_SHADER);
    if !shader_ok return false;
    renderer.shader_program = shader_program;
    renderer.texture_sampler_uniform_location = glGetUniformLocation(shader_program, "texture_sampler");

    glGenVertexArrays(1, *renderer.vertex_array);
    gl_bind_vertex_array(renderer.vertex_array);
    glGenBuffers(1, *renderer.index_buffer);
    gl_bind_buffer_to_binding_target(GL_ELEMENT_ARRAY_BUFFER, renderer.index_buffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, UI.UI_RENDER_BATCH_MAX_INDICES * size_of(u32), null, GL_STREAM_DRAW);

    init_opengl_ui_image_renderer_buffer(*renderer.position_buffer, size_of(Vector3));
    init_opengl_ui_image_renderer_attribute(shader_program, renderer.vertex_array, renderer.position_buffer, "position", 3);
    init_opengl_ui_image_renderer_buffer(*renderer.texture_coordinate_buffer, size_of(Vector2));
    init_opengl_ui_image_renderer_attribute(shader_program, renderer.vertex_array, renderer.texture_coordinate_buffer, "texture_coordinate_in", 2);
    init_opengl_ui_image_renderer_buffer(*renderer.rgba_color_buffer, size_of(Vector4));
    init_opengl_ui_image_renderer_attribute(shader_program, renderer.vertex_array, renderer.rgba_color_buffer, "rgba_color_in", 4);

    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, 0);
    gl_bind_vertex_array(0);
    return true;
}

deinit :: (renderer: *OpenGL_UI_Image_Renderer) {
    if renderer.shader_program           gl_delete_shader_program(renderer.shader_program);
    if renderer.vertex_array             gl_delete_vertex_array(renderer.vertex_array);
    if renderer.index_buffer             gl_delete_buffer(renderer.index_buffer);
    if renderer.position_buffer          gl_delete_buffer(renderer.position_buffer);
    if renderer.texture_coordinate_buffer gl_delete_buffer(renderer.texture_coordinate_buffer);
    if renderer.rgba_color_buffer        gl_delete_buffer(renderer.rgba_color_buffer);
    renderer.* = .{};
}

upload_msdf_font_atlas_to_opengl :: (
    renderer: *OpenGL_UI_Renderer,
    font: *UI.MSDF_Font,
    atlas_png_path: string
) -> success: bool {
    image_loaded, png_data := load_asset(atlas_png_path);
    if !image_loaded return false;

    width, height, source_channel_count: s32;
    stbi_set_flip_vertically_on_load(1);
    pixels := stbi_load_from_memory(png_data.data, cast(s32) png_data.count, *width, *height, *source_channel_count, 4);
    stbi_set_flip_vertically_on_load(0);
    if pixels == null return false;
    defer stbi_image_free(pixels);

    glGenTextures(1, *renderer.font_atlas_texture);
    gl_bind_texture_to_binding_target_of_active_texture_unit(GL_TEXTURE_2D, renderer.font_atlas_texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    gl_set_integer_pixel_storage_parameter(GL_UNPACK_ALIGNMENT, 4);
    gl_set_integer_pixel_storage_parameter(GL_UNPACK_ROW_LENGTH, 0);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, xx width, xx height, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixels);
    gl_bind_texture_to_binding_target_of_active_texture_unit(GL_TEXTURE_2D, 0);

    font.texture_handle = cast(UI.UI_Texture_Handle) renderer.font_atlas_texture;
    return true;
}

init :: (
    renderer: *OpenGL_UI_Renderer,
    font: *UI.MSDF_Font,
    atlas_png_path: string
) -> success: bool {
    init(*renderer.geometry_renderer);
    init(*renderer.text_renderer);
    renderer.text_screen_pixels_per_distance_range_uniform_location = glGetUniformLocation(
        renderer.text_renderer.shader_program_gl_handle, "screen_pixels_per_distance_range"
    );
    if !init(*renderer.image_renderer) {
        deinit(renderer);
        return false;
    }
    if !upload_msdf_font_atlas_to_opengl(renderer, font, atlas_png_path) {
        deinit(renderer);
        return false;
    }
    return true;
}

deinit :: (renderer: *OpenGL_UI_Renderer) {
    if renderer.font_atlas_texture gl_delete_texture(renderer.font_atlas_texture);
    deinit(*renderer.image_renderer);
    deinit(*renderer.text_renderer);
    deinit(*renderer.geometry_renderer);
    renderer.* = .{};
}

upload_opengl_ui_draw_buffers :: (renderer: *OpenGL_UI_Renderer, buffers: *UI.UI_Frame_Draw_Buffers) {
    if buffers.geometry_indices.count > 0 {
        geometry := *renderer.geometry_renderer;
        gl_bind_vertex_array(geometry.immediate_vertex_attribute_array_gl_handle);
        gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, geometry.immediate_positions_buffer_gl_handle);
        glBufferSubData(GL_ARRAY_BUFFER, 0, buffers.geometry_positions.count * size_of(Vector3), buffers.geometry_positions.data);
        gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, geometry.immediate_passthrough_rgba_colors_buffer_gl_handle);
        glBufferSubData(GL_ARRAY_BUFFER, 0, buffers.geometry_rgba_colors.count * size_of(Vector4), buffers.geometry_rgba_colors.data);
        gl_bind_buffer_to_binding_target(GL_ELEMENT_ARRAY_BUFFER, geometry.immediate_index_buffer_gl_handle);
        glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, 0, buffers.geometry_indices.count * size_of(u32), buffers.geometry_indices.data);
    }

    if buffers.image_indices.count > 0 {
        image := *renderer.image_renderer;
        gl_bind_vertex_array(image.vertex_array);
        gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, image.position_buffer);
        glBufferSubData(GL_ARRAY_BUFFER, 0, buffers.image_positions.count * size_of(Vector3), buffers.image_positions.data);
        gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, image.texture_coordinate_buffer);
        glBufferSubData(GL_ARRAY_BUFFER, 0, buffers.image_texture_coordinates.count * size_of(Vector2), buffers.image_texture_coordinates.data);
        gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, image.rgba_color_buffer);
        glBufferSubData(GL_ARRAY_BUFFER, 0, buffers.image_rgba_colors.count * size_of(Vector4), buffers.image_rgba_colors.data);
        gl_bind_buffer_to_binding_target(GL_ELEMENT_ARRAY_BUFFER, image.index_buffer);
        glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, 0, buffers.image_indices.count * size_of(u32), buffers.image_indices.data);
    }

    if buffers.text_indices.count > 0 {
        text := *renderer.text_renderer;
        gl_bind_vertex_array(text.immediate_vertex_attribute_array_gl_handle);

        if buffers.text_positions.count > renderer.text_vertex_capacity {
            while renderer.text_vertex_capacity < buffers.text_positions.count renderer.text_vertex_capacity *= 2;
            gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, text.immediate_positions_buffer_gl_handle);
            glBufferData(GL_ARRAY_BUFFER, renderer.text_vertex_capacity * size_of(Vector3), null, GL_STREAM_DRAW);
            gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, text.immediate_passthrough_texture_coordinates_buffer_gl_handle);
            glBufferData(GL_ARRAY_BUFFER, renderer.text_vertex_capacity * size_of(Vector2), null, GL_STREAM_DRAW);
            gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, text.immediate_passthrough_rgba_colors_buffer_gl_handle);
            glBufferData(GL_ARRAY_BUFFER, renderer.text_vertex_capacity * size_of(Vector4), null, GL_STREAM_DRAW);
        }
        if buffers.text_indices.count > renderer.text_index_capacity {
            while renderer.text_index_capacity < buffers.text_indices.count renderer.text_index_capacity *= 2;
            gl_bind_buffer_to_binding_target(GL_ELEMENT_ARRAY_BUFFER, text.immediate_index_buffer_gl_handle);
            glBufferData(GL_ELEMENT_ARRAY_BUFFER, renderer.text_index_capacity * size_of(u32), null, GL_STREAM_DRAW);
        }

        gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, text.immediate_positions_buffer_gl_handle);
        glBufferSubData(GL_ARRAY_BUFFER, 0, buffers.text_positions.count * size_of(Vector3), buffers.text_positions.data);
        gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, text.immediate_passthrough_texture_coordinates_buffer_gl_handle);
        glBufferSubData(GL_ARRAY_BUFFER, 0, buffers.text_texture_coordinates.count * size_of(Vector2), buffers.text_texture_coordinates.data);
        gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, text.immediate_passthrough_rgba_colors_buffer_gl_handle);
        glBufferSubData(GL_ARRAY_BUFFER, 0, buffers.text_rgba_colors.count * size_of(Vector4), buffers.text_rgba_colors.data);
        gl_bind_buffer_to_binding_target(GL_ELEMENT_ARRAY_BUFFER, text.immediate_index_buffer_gl_handle);
        glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, 0, buffers.text_indices.count * size_of(u32), buffers.text_indices.data);
    }
}

render_opengl_ui_command_list :: (
    renderer: *OpenGL_UI_Renderer,
    ui_context: *UI.UI_Context,
    buffers: *UI.UI_Frame_Draw_Buffers
) {
    if buffers.commands.count == 0 return;
    upload_opengl_ui_draw_buffers(renderer, buffers);

    active_type := UI.UI_Draw_Cmd_Type.SCISSOR_POP;
    active_type_is_set := false;
    active_text_font: *UI.MSDF_Font;
    active_text_size: float32;
    active_image_texture: GLuint;

    for command: buffers.commands {
        if command.type == {
            case .GEOMETRY;
                if command.index_count == 0 continue;
                if !active_type_is_set || active_type != .GEOMETRY {
                    geometry := *renderer.geometry_renderer;
                    gl_set_active_shader_program(geometry.shader_program_gl_handle);
                    set_aspect_ratio_uniform(geometry, .{1.0, 1.0});
                    gl_bind_vertex_array(geometry.immediate_vertex_attribute_array_gl_handle);
                    gl_bind_buffer_to_binding_target(GL_ELEMENT_ARRAY_BUFFER, geometry.immediate_index_buffer_gl_handle);
                    active_type = .GEOMETRY;
                    active_type_is_set = true;
                }
                glDrawElements(GL_TRIANGLES, cast(GLsizei) command.index_count, GL_UNSIGNED_INT, cast(*void) (command.index_offset * size_of(u32)));

            case .TEXT;
                if command.index_count == 0 continue;
                font := ifx command.font != null then command.font else ui_context.font;
                if !active_type_is_set || active_type != .TEXT || active_text_font != font || active_text_size != command.font_size {
                    text := *renderer.text_renderer;
                    gl_set_active_shader_program(text.shader_program_gl_handle);
                    gl_bind_vertex_array(text.immediate_vertex_attribute_array_gl_handle);
                    gl_bind_buffer_to_binding_target(GL_ELEMENT_ARRAY_BUFFER, text.immediate_index_buffer_gl_handle);
                    gl_set_active_texture_unit(GL_TEXTURE0);
                    gl_bind_texture_to_binding_target_of_active_texture_unit(GL_TEXTURE_2D, cast(GLuint) font.texture_handle);
                    set_texture_sampler_uniform(text, 0);
                    set_aspect_ratio_uniform(text, .{1.0, 1.0});
                    gl_set_uniform_1f_on_active_shader_program(
                        renderer.text_screen_pixels_per_distance_range_uniform_location,
                        UI.msdf_screen_pixels_per_distance_range(font, command.font_size)
                    );
                    active_type = .TEXT;
                    active_type_is_set = true;
                    active_text_font = font;
                    active_text_size = command.font_size;
                }
                glDrawElements(GL_TRIANGLES, cast(GLsizei) command.index_count, GL_UNSIGNED_INT, cast(*void) (command.index_offset * size_of(u32)));

            case .IMAGE;
                if command.index_count == 0 continue;
                texture := cast(GLuint) command.texture_handle;
                if !active_type_is_set || active_type != .IMAGE || active_image_texture != texture {
                    image := *renderer.image_renderer;
                    gl_set_active_shader_program(image.shader_program);
                    gl_bind_vertex_array(image.vertex_array);
                    gl_bind_buffer_to_binding_target(GL_ELEMENT_ARRAY_BUFFER, image.index_buffer);
                    gl_set_active_texture_unit(GL_TEXTURE0);
                    gl_bind_texture_to_binding_target_of_active_texture_unit(GL_TEXTURE_2D, texture);
                    gl_set_uniform_1i_on_active_shader_program(image.texture_sampler_uniform_location, 0);
                    active_type = .IMAGE;
                    active_type_is_set = true;
                    active_image_texture = texture;
                }
                glDrawElements(GL_TRIANGLES, cast(GLsizei) command.index_count, GL_UNSIGNED_INT, cast(*void) (command.index_offset * size_of(u32)));

            case .SCISSOR_PUSH;
                glEnable(GL_SCISSOR_TEST);
                gl_y := ui_context.window_h - (command.scissor_rect.y + command.scissor_rect.h);
                glScissor(
                    cast(GLint) command.scissor_rect.x,
                    cast(GLint) gl_y,
                    cast(GLsizei) max(command.scissor_rect.w, 0),
                    cast(GLsizei) max(command.scissor_rect.h, 0)
                );

            case .SCISSOR_POP;
                glDisable(GL_SCISSOR_TEST);
        }
    }
}

render_ui_draw_data_with_opengl :: (renderer: *OpenGL_UI_Renderer, ui_context: *UI.UI_Context) {
    depth_test_was_enabled := glIsEnabled(GL_DEPTH_TEST);
    depth_write_was_enabled: GLboolean;
    glGetBooleanv(GL_DEPTH_WRITEMASK, *depth_write_was_enabled);

    glDisable(GL_DEPTH_TEST);
    glDepthMask(GL_FALSE);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    render_opengl_ui_command_list(renderer, ui_context, *ui_context.draw_buffers);
    if ui_context.overlay_draw_buffers.commands.count > 0 {
        glDisable(GL_SCISSOR_TEST);
        render_opengl_ui_command_list(renderer, ui_context, *ui_context.overlay_draw_buffers);
    }

    glDisable(GL_SCISSOR_TEST);
    gl_bind_vertex_array(0);
    gl_clear_active_shader_program();
    if depth_test_was_enabled glEnable(GL_DEPTH_TEST);
    else glDisable(GL_DEPTH_TEST);
    glDepthMask(depth_write_was_enabled);
}

opengl_ui_render_target_deinit :: (backend_user_data: *void, target: *UI.UI_Render_Target) {
    framebuffer := cast(GLuint) target.backend_framebuffer_handle;
    color_texture := cast(GLuint) target.texture_handle;
    depth_buffer := cast(GLuint) target.backend_depth_buffer_handle;
    if framebuffer gl_delete_framebuffer(framebuffer);
    if color_texture gl_delete_texture(color_texture);
    if depth_buffer gl_delete_renderbuffer(depth_buffer);
    target.texture_handle = UI.UI_TEXTURE_HANDLE_NONE;
    target.backend_framebuffer_handle = 0;
    target.backend_depth_buffer_handle = 0;
    target.width = 0;
    target.height = 0;
    target.active = false;
}

opengl_ui_render_target_ensure_size :: (
    backend_user_data: *void,
    target: *UI.UI_Render_Target,
    width: s32,
    height: s32
) -> success: bool {
    if width <= 0 || height <= 0 return false;
    if target.backend_framebuffer_handle != 0 && target.width == width && target.height == height return true;
    opengl_ui_render_target_deinit(backend_user_data, target);

    color_texture, depth_buffer, framebuffer: GLuint;
    glGenTextures(1, *color_texture);
    gl_bind_texture_to_binding_target_of_active_texture_unit(GL_TEXTURE_2D, color_texture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, xx width, xx height, 0, GL_RGBA, GL_UNSIGNED_BYTE, null);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    glGenRenderbuffers(1, *depth_buffer);
    gl_bind_renderbuffer(depth_buffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24, xx width, xx height);

    glGenFramebuffers(1, *framebuffer);
    gl_bind_framebuffer_to_binding_target(GL_FRAMEBUFFER, framebuffer);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, color_texture, 0);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depth_buffer);
    complete := glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE;
    gl_bind_framebuffer_to_binding_target(GL_FRAMEBUFFER, 0);
    if !complete {
        opengl_ui_render_target_deinit(backend_user_data, target);
        return false;
    }

    target.texture_handle = cast(UI.UI_Texture_Handle) color_texture;
    target.backend_depth_buffer_handle = cast(u64) depth_buffer;
    target.backend_framebuffer_handle = cast(u64) framebuffer;
    target.width = width;
    target.height = height;
    return true;
}

opengl_ui_render_target_begin :: (backend_user_data: *void, target: *UI.UI_Render_Target) -> success: bool {
    if target.backend_framebuffer_handle == 0 return false;
    previous_framebuffer: GLint;
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, *previous_framebuffer);
    glGetIntegerv(GL_VIEWPORT, target.backend_previous_viewport.data);
    target.backend_previous_framebuffer_handle = cast(u64) previous_framebuffer;
    gl_bind_framebuffer_to_binding_target(GL_FRAMEBUFFER, cast(GLuint) target.backend_framebuffer_handle);
    glViewport(0, 0, xx target.width, xx target.height);
    target.active = true;
    return true;
}

opengl_ui_render_target_end :: (backend_user_data: *void, target: *UI.UI_Render_Target) {
    if !target.active return;
    gl_bind_framebuffer_to_binding_target(GL_FRAMEBUFFER, cast(GLuint) target.backend_previous_framebuffer_handle);
    glViewport(
        target.backend_previous_viewport[0],
        target.backend_previous_viewport[1],
        xx target.backend_previous_viewport[2],
        xx target.backend_previous_viewport[3]
    );
    target.active = false;
}

attach_opengl_render_target_backend_to_ui_context :: (renderer: *OpenGL_UI_Renderer) {
    UI.ui_set_render_target_backend(
        renderer,
        opengl_ui_render_target_deinit,
        opengl_ui_render_target_ensure_size,
        opengl_ui_render_target_begin,
        opengl_ui_render_target_end
    );
}
