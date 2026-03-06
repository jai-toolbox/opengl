Camera_Infinite_Grid :: struct {
    renderer: Camera_Infinite_Grid_Renderer;
    empty_vao: GLuint;
}

init :: (using grid: *Camera_Infinite_Grid) {
    init(*renderer); // we literally just use the renderer to auto compile the shader program, we don't touch anything else.

    // we need an empty vao because the vertex shader generates
    // all geometry internally using gl_vertexid. opengl still
    // requires a vao to be bound for draw calls.
    glGenVertexArrays(1, *empty_vao);

    // enable blending the grid shader outputs alpha for 
    // anti-aliased lines and distance-based opacity falloff.
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
}

deinit :: (using grid: *Camera_Infinite_Grid) {
    glDeleteVertexArrays(1, *empty_vao);
    // TODO: deinit renderer if needed
}

render :: (using grid: *Camera_Infinite_Grid, 
           camera_to_clip: Matrix4, 
           world_to_camera: Matrix4, 
           camera_position: Vector3,
           grid_size: float32 = 100.0) {

    glUseProgram(renderer.shader_program_gl_handle);

    // the grid uses alpha blending, so make sure it's on.
    // we do this here too in case something else turned it off.
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    set_camera_to_clip_uniform(*renderer, camera_to_clip);
    set_world_to_camera_uniform(*renderer, world_to_camera);
    set_camera_position_uniform(*renderer, camera_position);
    set_grid_size_uniform(*renderer, grid_size);

    // bind the empty vao and draw 6 vertices (two triangles).
    // the vertex shader uses gl_vertexid to index into hardcoded
    // positions and indices, no vertex buffers needed.
    glBindVertexArray(empty_vao);
    glDrawArrays(GL_TRIANGLES, 0, 6);
    glBindVertexArray(0);

    // restore blending state so we don't surprise other renderers
    glDisable(GL_BLEND);

    glUseProgram(0);
}
