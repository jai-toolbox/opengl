/*

Here we have deferred rendering, we use it like this per frame:

glUseProgram(deferred_lighting.geometry_pass_renderer.shader_program_gl_handle);
set_world_to_camera_uniform(*deferred_lighting.geometry_pass_renderer, windowed_program_3d.camera.world_to_camera);
set_camera_to_clip_uniform(*deferred_lighting.geometry_pass_renderer, windowed_program_3d.camera.camera_to_clip);
glUseProgram(0);

glUseProgram(deferred_lighting.compute_light_pass_renderer.shader_program_gl_handle);
set_aspect_ratio_uniform(*deferred_lighting.compute_light_pass_renderer, Vector2.{xx windowed_program_3d.window_width, xx windowed_program_3d.window_height});
glUseProgram(0);

for map_renderables queue_render(*deferred_lighting.geometry_pass_renderer, it.object_index);

... 

render(*deferred_lighting, windowed_program_3d.camera.position);

*/


Light :: struct {
    position : Vector3;
    color : Vector3;
}

MAX_LIGHTS :: 32;

// eventually at some point this should be automated into the generated renderer code.
set_lights_uniform :: (shader_program_gl_handle: GLuint, lights: [] Light) {
    for lights {
        position_name := tprint("lights[%].position\0", it_index);
        color_name := tprint("lights[%].color\0", it_index);

        pos_loc := glGetUniformLocation(shader_program_gl_handle, position_name.data);
        col_loc := glGetUniformLocation(shader_program_gl_handle, color_name.data);

        glUniform3f(pos_loc, it.position.x, it.position.y, it.position.z);
        glUniform3f(col_loc, it.color.x, it.color.y, it.color.z);
    }
}

set_sampler_uniforms :: (using deferred_lighting : *Deferred_Lighting) {
    glUseProgram(compute_light_pass_renderer.shader_program_gl_handle);

    set_position_texture_uniform(*compute_light_pass_renderer, 0);
    set_normal_texture_uniform  (*compute_light_pass_renderer, 1);
    set_color_texture_uniform   (*compute_light_pass_renderer, 2);

    glUseProgram(0);
}

Deferred_Lighting :: struct {
    geometry_pass_renderer : Camera_Per_Object_Transform_Deferred_Lighting_Geometry_Pass_Renderer;
    compute_light_pass_renderer : Camera_Per_Object_Transform_Deferred_Lighting_Compute_Light_Pass_Renderer;

    deferred_lighting_frame_buffer : GLuint;
    position_texture : GLuint;
    normal_texture : GLuint;
    color_texture : GLuint;
    depth_render_buffer : GLuint;

    // the fullscreen quad used in the lighting pass
    deferred_lighting_screen : Camera_Per_Object_Transform_Deferred_Lighting_Compute_Light_Pass_Renderable;

    window_width : s32;
    window_height : s32;

    lights : [MAX_LIGHTS] Light;
    num_active_lights : s32 = 0;
}

init :: (using deferred_lighting : *Deferred_Lighting, width: s32, height: s32) {
    window_width = width;
    window_height = height;

    init(*geometry_pass_renderer);
    init(*compute_light_pass_renderer);

    glGenFramebuffers(1, *deferred_lighting_frame_buffer);
    glBindFramebuffer(GL_FRAMEBUFFER, deferred_lighting_frame_buffer);

    // position texture (GL_COLOR_ATTACHMENT0)
    glGenTextures(1, *position_texture);
    glBindTexture(GL_TEXTURE_2D, position_texture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA16F, xx window_width, xx window_height, 0, GL_RGBA, GL_FLOAT, null);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, position_texture, 0);

    // normal texture (GL_COLOR_ATTACHMENT1)
    glGenTextures(1, *normal_texture);
    glBindTexture(GL_TEXTURE_2D, normal_texture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA16F, xx window_width, xx window_height, 0, GL_RGBA, GL_FLOAT, null);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT1, GL_TEXTURE_2D, normal_texture, 0);

    // color texture (GL_COLOR_ATTACHMENT2)
    glGenTextures(1, *color_texture);
    glBindTexture(GL_TEXTURE_2D, color_texture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, xx window_width, xx window_height, 0, GL_RGBA, GL_UNSIGNED_BYTE, null);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT2, GL_TEXTURE_2D, color_texture, 0);

    // tell OpenGL which color attachments we'll use for rendering
    attachments : [3] GLenum = .[GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1, GL_COLOR_ATTACHMENT2];
    glDrawBuffers(3, attachments.data);

    // depth renderbuffer
    glGenRenderbuffers(1, *depth_render_buffer);
    glBindRenderbuffer(GL_RENDERBUFFER, depth_render_buffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT, xx window_width, xx window_height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depth_render_buffer);

    // document what it means for a framebuffer to not be complete
    if glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE {
        log("Framebuffer not complete!");
    }

    glBindFramebuffer(GL_FRAMEBUFFER, 0);

    set_sampler_uniforms(deferred_lighting);

    init_deferred_lighting_screen(deferred_lighting);
}

init_deferred_lighting_screen :: (using deferred_lighting: *Deferred_Lighting) {
    // a fullscreen quad in ndc (normalized device coordinates)
    // two triangles covering [-1, 1] x [-1, 1]
    array_add(*deferred_lighting_screen.positions,
        .{-1.0, -1.0, 0.0},
        .{ 1.0, -1.0, 0.0},
        .{ 1.0,  1.0, 0.0},
        .{-1.0,  1.0, 0.0}
    );

    // texture coordinates flipped vertically 
    array_add(*deferred_lighting_screen.texture_coordinates,
        .{0.0, 0.0},
        .{1.0, 0.0},
        .{1.0, 1.0},
        .{0.0, 1.0}
    );

    array_add(*deferred_lighting_screen.indices, 0, 1, 2, 0, 2, 3);

    success := buffer_object(*compute_light_pass_renderer, *deferred_lighting_screen);
    if !success log("Failed to buffer deferred lighting screen quad");
}

render :: (using deferred_lighting: *Deferred_Lighting, camera_position: Vector3) {
    render_geometry_pass(deferred_lighting);
    render_lighting_pass(deferred_lighting, camera_position);
    copy_depth_information_into_default_framebuffer(deferred_lighting);
}

render_geometry_pass :: (using deferred_lighting: *Deferred_Lighting) {
    glBindFramebuffer(GL_FRAMEBUFFER, deferred_lighting_frame_buffer);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    render(*geometry_pass_renderer);

    glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

render_lighting_pass :: (using deferred_lighting: *Deferred_Lighting, camera_position: Vector3) {
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    // this is usually know as the g-buffer, or geometry buffer
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, position_texture);
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, normal_texture);
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, color_texture);

    shader := compute_light_pass_renderer.shader_program_gl_handle;
    glUseProgram(shader);

    cam_loc := glGetUniformLocation(shader, "camera_position");
    glUniform3f(cam_loc, camera_position.x, camera_position.y, camera_position.z);

    set_lights_uniform(shader, array_view(lights, 0, num_active_lights));

    glUseProgram(0);

    queue_render(*compute_light_pass_renderer.psr, deferred_lighting_screen.object_index);
    render(*compute_light_pass_renderer);
}

copy_depth_information_into_default_framebuffer :: (using deferred_lighting: *Deferred_Lighting) {
    glBindFramebuffer(GL_READ_FRAMEBUFFER, deferred_lighting_frame_buffer);
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);

    glBlitFramebuffer(
        0, 0, xx window_width, xx window_height,
        0, 0, xx window_width, xx window_height,
        GL_DEPTH_BUFFER_BIT, GL_NEAREST
    );

    glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

deinit :: (using deferred_lighting: *Deferred_Lighting) {
    glDeleteFramebuffers(1, *deferred_lighting_frame_buffer);
    glDeleteTextures(1, *position_texture);
    glDeleteTextures(1, *normal_texture);
    glDeleteTextures(1, *color_texture);
    glDeleteRenderbuffers(1, *depth_render_buffer);

    deinit(*deferred_lighting_screen, *compute_light_pass_renderer);
}

add_light :: (using deferred_lighting: *Deferred_Lighting, position: Vector3, color: Vector3) -> light_index: s32, success: bool {
    if num_active_lights >= MAX_LIGHTS {
        log("Cannot add light: maximum of % lights reached", MAX_LIGHTS);
        return 0, false;
    }

    lights[num_active_lights] = .{position = position, color = color};
    index := num_active_lights;
    num_active_lights += 1;
    return index, true;
}

set_light_position :: (using deferred_lighting: *Deferred_Lighting, light_index: s32, position: Vector3) {
    lights[light_index].position = position;
}

set_light_color :: (using deferred_lighting: *Deferred_Lighting, light_index: s32, color: Vector3) {
    lights[light_index].color = color;
}
