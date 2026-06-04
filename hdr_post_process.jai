HDR_Post_Process :: struct {
    scene_framebuffer: GLuint;
    scene_color_texture: GLuint;
    scene_depth_texture: GLuint;

    bloom_framebuffers: [2] GLuint;
    bloom_textures: [2] GLuint;

    fullscreen_vertex_array: GLuint;

    bright_extract_shader: GLuint;
    blur_shader: GLuint;
    tone_map_shader: GLuint;

    width: s32 = 0;
    height: s32 = 0;

    enable_bloom := true;
    bloom_threshold: float32 = 1.0;
    bloom_strength: float32 = 0.08;
    exposure: float32 = 1.0;
    output_mode: s32 = 0; // 0 = exponential tonemap, 1 = Standard linear-to-sRGB
    blur_iterations: s32 = 6;
    initialized := false;
}

init :: (using hdr: *HDR_Post_Process, initial_width: s32, initial_height: s32) {
    bright_vs_loaded, fullscreen_vs := load_asset("data/shaders/out/fullscreen_quad_texture.vert");
    assert(bright_vs_loaded, "Failed to load fullscreen quad vertex shader");

    bright_fs_loaded, bright_fs := load_asset("data/shaders/out/hdr_bright_extract.frag");
    assert(bright_fs_loaded, "Failed to load HDR bright extract shader");
    bright_program, bright_ok := create_shader_program(fullscreen_vs, bright_fs);
    assert(bright_ok, "Failed to create HDR bright extract shader program");
    bright_extract_shader = bright_program;

    blur_fs_loaded, blur_fs := load_asset("data/shaders/out/hdr_blur.frag");
    assert(blur_fs_loaded, "Failed to load HDR blur shader");
    blur_program, blur_ok := create_shader_program(fullscreen_vs, blur_fs);
    assert(blur_ok, "Failed to create HDR blur shader program");
    blur_shader = blur_program;

    tone_fs_loaded, tone_fs := load_asset("data/shaders/out/hdr_tone_map.frag");
    assert(tone_fs_loaded, "Failed to load HDR tone map shader");
    tone_program, tone_ok := create_shader_program(fullscreen_vs, tone_fs);
    assert(tone_ok, "Failed to create HDR tone map shader program");
    tone_map_shader = tone_program;

    glGenVertexArrays(1, *fullscreen_vertex_array);

    glUseProgram(bright_extract_shader);
    glUniform1i(glGetUniformLocation(bright_extract_shader, "hdr_scene_texture"), 0);
    glUseProgram(blur_shader);
    glUniform1i(glGetUniformLocation(blur_shader, "source_texture"), 0);
    glUseProgram(tone_map_shader);
    glUniform1i(glGetUniformLocation(tone_map_shader, "hdr_scene_texture"), 0);
    glUniform1i(glGetUniformLocation(tone_map_shader, "bloom_texture"), 1);
    glUseProgram(0);

    initialized = true;
    resize(hdr, initial_width, initial_height);
}

resize :: (using hdr: *HDR_Post_Process, new_width: s32, new_height: s32) {
    if !initialized return;
    if new_width == width && new_height == height return;

    width = new_width;
    height = new_height;

    delete_framebuffer_textures(hdr);

    glGenFramebuffers(1, *scene_framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, scene_framebuffer);

    scene_color_texture = create_hdr_color_texture(width, height, true);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, scene_color_texture, 0);

    scene_depth_texture = create_depth_texture(width, height);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, scene_depth_texture, 0);

    attachment: GLenum = GL_COLOR_ATTACHMENT0;
    glDrawBuffers(1, *attachment);

    if glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE {
        log_error("HDR scene framebuffer is incomplete");
    }

    for i: 0..1 {
        glGenFramebuffers(1, *bloom_framebuffers[i]);
        glBindFramebuffer(GL_FRAMEBUFFER, bloom_framebuffers[i]);
        bloom_textures[i] = create_hdr_color_texture(width, height, true);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, bloom_textures[i], 0);

        if glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE {
            log_error("HDR bloom framebuffer % is incomplete", i);
        }
    }

    glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

delete_framebuffer_textures :: (using hdr: *HDR_Post_Process) {
    if scene_framebuffer != 0 glDeleteFramebuffers(1, *scene_framebuffer);
    if scene_color_texture != 0 glDeleteTextures(1, *scene_color_texture);
    if scene_depth_texture != 0 glDeleteTextures(1, *scene_depth_texture);

    for i: 0..1 {
        if bloom_framebuffers[i] != 0 glDeleteFramebuffers(1, *bloom_framebuffers[i]);
        if bloom_textures[i] != 0 glDeleteTextures(1, *bloom_textures[i]);
        bloom_framebuffers[i] = 0;
        bloom_textures[i] = 0;
    }

    scene_framebuffer = 0;
    scene_color_texture = 0;
    scene_depth_texture = 0;
}

create_hdr_color_texture :: (width: s32, height: s32, linear_filter: bool) -> GLuint {
    result: GLuint;
    glGenTextures(1, *result);
    glBindTexture(GL_TEXTURE_2D, result);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA16F, xx width, xx height, 0, GL_RGBA, GL_FLOAT, null);
    filter: GLint = xx GL_NEAREST;
    if linear_filter filter = xx GL_LINEAR;
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, filter);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, filter);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    return result;
}

create_depth_texture :: (width: s32, height: s32) -> GLuint {
    result: GLuint;
    glGenTextures(1, *result);
    glBindTexture(GL_TEXTURE_2D, result);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT24, xx width, xx height, 0, GL_DEPTH_COMPONENT, GL_FLOAT, null);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    return result;
}

begin_hdr_scene :: (using hdr: *HDR_Post_Process, clear_color: Vector4) {
    glBindFramebuffer(GL_FRAMEBUFFER, scene_framebuffer);
    glViewport(0, 0, xx width, xx height);
    glClearColor(clear_color.x, clear_color.y, clear_color.z, clear_color.w);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

render_hdr_to_default :: (using hdr: *HDR_Post_Process) {
    glDisable(GL_DEPTH_TEST);
    glDepthMask(GL_FALSE);

    if enable_bloom {
        render_bloom(hdr);
    }

    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glViewport(0, 0, xx width, xx height);
    glClear(GL_COLOR_BUFFER_BIT);

    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, scene_color_texture);
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, bloom_textures[0]);

    glUseProgram(tone_map_shader);
    glUniform1i(glGetUniformLocation(tone_map_shader, "enable_bloom"), xx enable_bloom);
    glUniform1f(glGetUniformLocation(tone_map_shader, "bloom_strength"), bloom_strength);
    glUniform1f(glGetUniformLocation(tone_map_shader, "exposure"), exposure);
    glUniform1i(glGetUniformLocation(tone_map_shader, "output_mode"), output_mode);
    draw_fullscreen_quad(hdr);

    glUseProgram(0);
    glDepthMask(GL_TRUE);
    glEnable(GL_DEPTH_TEST);
}

render_bloom :: (using hdr: *HDR_Post_Process) {
    glBindFramebuffer(GL_FRAMEBUFFER, bloom_framebuffers[0]);
    glClear(GL_COLOR_BUFFER_BIT);

    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, scene_color_texture);

    glUseProgram(bright_extract_shader);
    glUniform1f(glGetUniformLocation(bright_extract_shader, "bloom_threshold"), bloom_threshold);
    draw_fullscreen_quad(hdr);

    horizontal := true;
    for 0..blur_iterations - 1 {
        target_index := ifx horizontal then 1 else 0;
        source_index := ifx horizontal then 0 else 1;

        glBindFramebuffer(GL_FRAMEBUFFER, bloom_framebuffers[target_index]);
        glClear(GL_COLOR_BUFFER_BIT);
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, bloom_textures[source_index]);

        glUseProgram(blur_shader);
        if horizontal {
            glUniform2f(glGetUniformLocation(blur_shader, "texel_step"), 1.0 / cast(float32) width, 0.0);
        } else {
            glUniform2f(glGetUniformLocation(blur_shader, "texel_step"), 0.0, 1.0 / cast(float32) height);
        }
        draw_fullscreen_quad(hdr);

        horizontal = !horizontal;
    }

    if (blur_iterations % 2) != 0 {
        glBindFramebuffer(GL_READ_FRAMEBUFFER, bloom_framebuffers[1]);
        glBindFramebuffer(GL_DRAW_FRAMEBUFFER, bloom_framebuffers[0]);
        glBlitFramebuffer(0, 0, width, height, 0, 0, width, height, GL_COLOR_BUFFER_BIT, GL_LINEAR);
    }
}

draw_fullscreen_quad :: (using hdr: *HDR_Post_Process) {
    glBindVertexArray(fullscreen_vertex_array);
    glDrawArrays(GL_TRIANGLES, 0, 6);
    glBindVertexArray(0);
}

deinit :: (using hdr: *HDR_Post_Process) {
    delete_framebuffer_textures(hdr);
    if fullscreen_vertex_array != 0 glDeleteVertexArrays(1, *fullscreen_vertex_array);
    if bright_extract_shader != 0 glDeleteProgram(bright_extract_shader);
    if blur_shader != 0 glDeleteProgram(blur_shader);
    if tone_map_shader != 0 glDeleteProgram(tone_map_shader);
}
