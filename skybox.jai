#import "Basic";
#import "GL";
#import "Math";
#import "stb_image";

#import "tbx/assets";

Cubemap :: struct {
    texture_gl_handle: GLuint;
}

Skybox_Renderer :: struct {
    shader_program_gl_handle: GLuint;
    vertex_array_gl_handle: GLuint;
    position_buffer_gl_handle: GLuint;

    world_to_camera_uniform_location: GLint = -1;
    camera_to_clip_uniform_location: GLint = -1;
    skybox_cubemap_uniform_location: GLint = -1;
}

load_cubemap :: (
    positive_x: string,
    negative_x: string,
    positive_y: string,
    negative_y: string,
    positive_z: string,
    negative_z: string
) -> Cubemap, bool {
    result: Cubemap;

    face_paths := string.[
        positive_x,
        negative_x,
        positive_y,
        negative_y,
        positive_z,
        negative_z,
    ];

    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    stbi_set_flip_vertically_on_load(0);

    glGenTextures(1, *result.texture_gl_handle);
    glBindTexture(GL_TEXTURE_CUBE_MAP, result.texture_gl_handle);

    for face_path, face_index: face_paths {
        image_loaded, image_data := load_asset(face_path);
        if !image_loaded {
            log_error("Failed to load cubemap face: %", face_path);
            glBindTexture(GL_TEXTURE_CUBE_MAP, 0);
            return result, false;
        }

        w, h, channels: s32;
        pixels := stbi_load_from_memory(image_data.data, xx image_data.count, *w, *h, *channels, 4);
        if pixels == null {
            log_error("Failed to decode cubemap face: %", face_path);
            glBindTexture(GL_TEXTURE_CUBE_MAP, 0);
            return result, false;
        }

        face_target := GL_TEXTURE_CUBE_MAP_POSITIVE_X + cast(GLenum) face_index;
        glTexImage2D(face_target, 0, GL_RGBA8, xx w, xx h, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixels);
        stbi_image_free(pixels);
    }

    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);
    glGenerateMipmap(GL_TEXTURE_CUBE_MAP);

    glBindTexture(GL_TEXTURE_CUBE_MAP, 0);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 4);

    return result, true;
}

load_nature_cubemap :: () -> Cubemap, bool {
    cubemap, success := load_cubemap(
        "data/cubemaps/nature/posx.jpg",
        "data/cubemaps/nature/negx.jpg",
        "data/cubemaps/nature/posy.jpg",
        "data/cubemaps/nature/negy.jpg",
        "data/cubemaps/nature/posz.jpg",
        "data/cubemaps/nature/negz.jpg"
    );
    return cubemap, success;
}

init :: (using renderer: *Skybox_Renderer) {
    vertex_shader_loaded, vertex_shader_source := load_asset("data/shaders/out/skybox.vert");
    assert(vertex_shader_loaded, "Failed to load skybox vertex shader");
    fragment_shader_loaded, fragment_shader_source := load_asset("data/shaders/out/skybox.frag");
    assert(fragment_shader_loaded, "Failed to load skybox fragment shader");

    shader_program_handle, success := create_shader_program(vertex_shader_source, fragment_shader_source);
    assert(success, "Failed to create skybox shader program");
    shader_program_gl_handle = shader_program_handle;

    world_to_camera_uniform_location = glGetUniformLocation(shader_program_gl_handle, "world_to_camera");
    camera_to_clip_uniform_location = glGetUniformLocation(shader_program_gl_handle, "camera_to_clip");
    skybox_cubemap_uniform_location = glGetUniformLocation(shader_program_gl_handle, "skybox_cubemap");

    vertices := Vector3.[
        .{-1,  1, -1}, .{-1, -1, -1}, .{ 1, -1, -1}, .{ 1, -1, -1}, .{ 1,  1, -1}, .{-1,  1, -1},
        .{-1, -1,  1}, .{-1, -1, -1}, .{-1,  1, -1}, .{-1,  1, -1}, .{-1,  1,  1}, .{-1, -1,  1},
        .{ 1, -1, -1}, .{ 1, -1,  1}, .{ 1,  1,  1}, .{ 1,  1,  1}, .{ 1,  1, -1}, .{ 1, -1, -1},
        .{-1, -1,  1}, .{-1,  1,  1}, .{ 1,  1,  1}, .{ 1,  1,  1}, .{ 1, -1,  1}, .{-1, -1,  1},
        .{-1,  1, -1}, .{ 1,  1, -1}, .{ 1,  1,  1}, .{ 1,  1,  1}, .{-1,  1,  1}, .{-1,  1, -1},
        .{-1, -1, -1}, .{-1, -1,  1}, .{ 1, -1, -1}, .{ 1, -1, -1}, .{-1, -1,  1}, .{ 1, -1,  1},
    ];

    glGenVertexArrays(1, *vertex_array_gl_handle);
    glBindVertexArray(vertex_array_gl_handle);

    glGenBuffers(1, *position_buffer_gl_handle);
    glBindBuffer(GL_ARRAY_BUFFER, position_buffer_gl_handle);
    glBufferData(GL_ARRAY_BUFFER, vertices.count * size_of(Vector3), vertices.data, GL_STATIC_DRAW);

    position_location := glGetAttribLocation(shader_program_gl_handle, "position");
    glEnableVertexAttribArray(xx position_location);
    glVertexAttribPointer(xx position_location, 3, GL_FLOAT, GL_FALSE, 0, null);

    glBindVertexArray(0);
}

render_skybox :: (using renderer: *Skybox_Renderer, cubemap: Cubemap, world_to_camera: Matrix4, camera_to_clip: Matrix4) {
    view_without_translation := world_to_camera;
    view_without_translation.coef[0][3] = 0;
    view_without_translation.coef[1][3] = 0;
    view_without_translation.coef[2][3] = 0;

    glDepthFunc(GL_LEQUAL);
    glDepthMask(GL_FALSE);

    glUseProgram(shader_program_gl_handle);
    glUniformMatrix4fv(world_to_camera_uniform_location, 1, GL_TRUE, *view_without_translation.coef[0][0]);
    glUniformMatrix4fv(camera_to_clip_uniform_location, 1, GL_TRUE, *camera_to_clip.coef[0][0]);
    glUniform1i(skybox_cubemap_uniform_location, 2);

    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_CUBE_MAP, cubemap.texture_gl_handle);

    glBindVertexArray(vertex_array_gl_handle);
    glDrawArrays(GL_TRIANGLES, 0, 36);
    glBindVertexArray(0);

    glUseProgram(0);
    glDepthMask(GL_TRUE);
    glDepthFunc(GL_LESS);
}

deinit :: (using renderer: *Skybox_Renderer) {
    glDeleteProgram(shader_program_gl_handle);
    glDeleteVertexArrays(1, *vertex_array_gl_handle);
    glDeleteBuffers(1, *position_buffer_gl_handle);
}
