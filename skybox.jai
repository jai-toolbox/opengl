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
    exposure_uniform_location: GLint = -1;
}

/*
upload six tightly-packed, linear RGB float faces in OpenGL cubemap order:
+X, -X, +Y, -Y, +Z, -Z. Preserve the generated float32 values on the GPU;
this preserves the generated HDR values without half-float quantization.
*/
create_cubemap_rgb32f :: (face_size: s32, face_pixels: [6] *float32) -> Cubemap {
    assert(face_size > 0, "Cubemap face size must be positive");
    for pixels: face_pixels assert(pixels != null, "Cubemap face pixels must not be null");

    result: Cubemap;
    glGenTextures(1, *result.texture_gl_handle);
    gl_bind_texture_to_binding_target_of_active_texture_unit(GL_TEXTURE_CUBE_MAP, result.texture_gl_handle);
    gl_set_integer_pixel_storage_parameter(GL_UNPACK_ALIGNMENT, 4);

    for pixels, face_index: face_pixels {
        face_target := GL_TEXTURE_CUBE_MAP_POSITIVE_X + cast(GLenum) face_index;
        glTexImage2D(
            face_target,
            0,
            GL_RGB32F,
            xx face_size,
            xx face_size,
            0,
            GL_RGB,
            GL_FLOAT,
            pixels,
        );
    }

    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);
    glGenerateMipmap(GL_TEXTURE_CUBE_MAP);
    gl_bind_texture_to_binding_target_of_active_texture_unit(GL_TEXTURE_CUBE_MAP, 0);

    return result;
}

deinit :: (cubemap: *Cubemap) {
    if cubemap.texture_gl_handle != 0 {
        gl_delete_texture(cubemap.texture_gl_handle);
        cubemap.texture_gl_handle = 0;
    }
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

    gl_set_integer_pixel_storage_parameter(GL_UNPACK_ALIGNMENT, 1);
    stbi_set_flip_vertically_on_load(0);

    glGenTextures(1, *result.texture_gl_handle);
    gl_bind_texture_to_binding_target_of_active_texture_unit(GL_TEXTURE_CUBE_MAP, result.texture_gl_handle);

    for face_path, face_index: face_paths {
        image_loaded, image_data := load_asset(face_path);
        if !image_loaded {
            log_error("Failed to load cubemap face: %", face_path);
            gl_bind_texture_to_binding_target_of_active_texture_unit(GL_TEXTURE_CUBE_MAP, 0);
            return result, false;
        }

        w, h, channels: s32;
        pixels := stbi_load_from_memory(image_data.data, xx image_data.count, *w, *h, *channels, 4);
        if pixels == null {
            log_error("Failed to decode cubemap face: %", face_path);
            gl_bind_texture_to_binding_target_of_active_texture_unit(GL_TEXTURE_CUBE_MAP, 0);
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

    gl_bind_texture_to_binding_target_of_active_texture_unit(GL_TEXTURE_CUBE_MAP, 0);
    gl_set_integer_pixel_storage_parameter(GL_UNPACK_ALIGNMENT, 4);

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
    vertex_shader_source := #run read_entire_file(tprint("%shaders/out/skybox.vert", #filepath));
    fragment_shader_source := #run read_entire_file(tprint("%shaders/out/skybox.frag", #filepath));

    shader_program_handle, success := create_shader_program(vertex_shader_source, fragment_shader_source);
    assert(success, "Failed to create skybox shader program");
    shader_program_gl_handle = shader_program_handle;

    world_to_camera_uniform_location = glGetUniformLocation(shader_program_gl_handle, "world_to_camera");
    camera_to_clip_uniform_location = glGetUniformLocation(shader_program_gl_handle, "camera_to_clip");
    skybox_cubemap_uniform_location = glGetUniformLocation(shader_program_gl_handle, "skybox_cubemap");
    exposure_uniform_location = glGetUniformLocation(shader_program_gl_handle, "exposure");

    vertices := Vector3.[
        .{-1,  1, -1}, .{-1, -1, -1}, .{ 1, -1, -1}, .{ 1, -1, -1}, .{ 1,  1, -1}, .{-1,  1, -1},
        .{-1, -1,  1}, .{-1, -1, -1}, .{-1,  1, -1}, .{-1,  1, -1}, .{-1,  1,  1}, .{-1, -1,  1},
        .{ 1, -1, -1}, .{ 1, -1,  1}, .{ 1,  1,  1}, .{ 1,  1,  1}, .{ 1,  1, -1}, .{ 1, -1, -1},
        .{-1, -1,  1}, .{-1,  1,  1}, .{ 1,  1,  1}, .{ 1,  1,  1}, .{ 1, -1,  1}, .{-1, -1,  1},
        .{-1,  1, -1}, .{ 1,  1, -1}, .{ 1,  1,  1}, .{ 1,  1,  1}, .{-1,  1,  1}, .{-1,  1, -1},
        .{-1, -1, -1}, .{-1, -1,  1}, .{ 1, -1, -1}, .{ 1, -1, -1}, .{-1, -1,  1}, .{ 1, -1,  1},
    ];

    glGenVertexArrays(1, *vertex_array_gl_handle);
    gl_bind_vertex_array(vertex_array_gl_handle);

    glGenBuffers(1, *position_buffer_gl_handle);
    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, position_buffer_gl_handle);
    glBufferData(GL_ARRAY_BUFFER, vertices.count * size_of(Vector3), vertices.data, GL_STATIC_DRAW);

    position_location := glGetAttribLocation(shader_program_gl_handle, "position");
    glEnableVertexAttribArray(xx position_location);
    glVertexAttribPointer(xx position_location, 3, GL_FLOAT, GL_FALSE, 0, null);

    gl_bind_vertex_array(0);
}

render_skybox :: (
    using renderer: *Skybox_Renderer,
    cubemap: Cubemap,
    world_to_camera: Matrix4,
    camera_to_clip: Matrix4,
    exposure: float32 = 1.0,
) {
    view_without_translation := world_to_camera;
    view_without_translation.coef[0][3] = 0;
    view_without_translation.coef[1][3] = 0;
    view_without_translation.coef[2][3] = 0;

    glDepthFunc(GL_LEQUAL);
    glDepthMask(GL_FALSE);

    gl_set_active_shader_program(shader_program_gl_handle);
    gl_set_uniform_matrix_4fv_on_active_shader_program(world_to_camera_uniform_location, 1, GL_TRUE, *view_without_translation.coef[0][0]);
    gl_set_uniform_matrix_4fv_on_active_shader_program(camera_to_clip_uniform_location, 1, GL_TRUE, *camera_to_clip.coef[0][0]);
    gl_set_uniform_1i_on_active_shader_program(skybox_cubemap_uniform_location, 2);
    gl_set_uniform_1f_on_active_shader_program(exposure_uniform_location, exposure);

    gl_set_active_texture_unit(GL_TEXTURE2);
    gl_bind_texture_to_binding_target_of_active_texture_unit(GL_TEXTURE_CUBE_MAP, cubemap.texture_gl_handle);

    gl_bind_vertex_array(vertex_array_gl_handle);
    glDrawArrays(GL_TRIANGLES, 0, 36);
    gl_bind_vertex_array(0);

    gl_clear_active_shader_program();
    glDepthMask(GL_TRUE);
    glDepthFunc(GL_LESS);
}

deinit :: (using renderer: *Skybox_Renderer) {
    gl_delete_shader_program(shader_program_gl_handle);
    gl_delete_vertex_array(vertex_array_gl_handle);
    gl_delete_buffer(position_buffer_gl_handle);
}
