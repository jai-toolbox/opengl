Camera_Infinite_Grid :: struct {
    renderer: Camera_Infinite_Grid_Renderer;
    empty_vao: GLuint;
}

Grid_Plane :: enum s32 {
    XZ :: 0;  // horizontal ground plane (Y = 0)
    XY :: 1;  // vertical front/back wall (Z = 0)
    YZ :: 2;  // vertical side wall (X = 0)
}

// Render the perspective grid repeatedly over a small clip-depth interval.
// A coplanar surface consequently produces a stable, soft ghost of the grid
// instead of whichever fragments happen to win an equal-depth test.
GRID_DEPTH_PASS_COUNT       :: 4;
GRID_CLIP_DEPTH_OFFSET_BACK ::  0.00025;
GRID_CLIP_DEPTH_OFFSET_FRONT :: -0.00020;

init :: (using grid: *Camera_Infinite_Grid) {
    init(*renderer); // we literally just use the renderer to auto compile the shader program, we don't touch anything else.

    // we need an empty vao because the vertex shader generates
    // all geometry internally using gl_vertexid. opengl still
    // requires a vao to be bound for draw calls.
    empty_vao = gl_create_vertex_array();
}

deinit :: (using grid: *Camera_Infinite_Grid) {
    gl_delete_vertex_array(empty_vao);
    deinit(*renderer);
}

render :: (using grid: *Camera_Infinite_Grid, 
           camera_to_clip: Matrix4, 
           world_to_camera: Matrix4, 
           camera_position: Vector3,
           plane: Grid_Plane = .XZ,
           grid_size: float32 = 100.0,
           place_at_far_depth := false) {

    gl_set_active_shader_program(renderer.shader_program_gl_handle);

    // The grid is an overlay over the completed scene depth. LEQUAL lets the
    // far-plane orthographic grid appear over cleared depth while all scene
    // geometry remains in front of it.
    gl_discard_fragments_that_fail_depth_test(true);
    gl_set_depth_test_pass_condition(GL_LEQUAL);
    gl_set_depth_writes_enabled(GL_FALSE);
    gl_enable_blending();
    gl_set_blend_function(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    set_camera_to_clip_uniform(*renderer, camera_to_clip);
    set_world_to_camera_uniform(*renderer, world_to_camera);
    set_camera_position_uniform(*renderer, camera_position);
    set_grid_size_uniform(*renderer, grid_size);
    set_grid_plane_uniform(*renderer, cast(s32) plane);
    set_grid_at_far_depth_uniform(*renderer, place_at_far_depth);

    // bind the empty vao and draw 6 vertices (two triangles).
    // the vertex shader uses gl_vertexid to index into hardcoded
    // positions and indices, no vertex buffers needed.
    gl_bind_vertex_array(empty_vao);

    if place_at_far_depth {
        set_grid_clip_depth_offset_uniform(*renderer, 0.0);
        set_grid_pass_alpha_uniform(*renderer, 1.0);
        gl_draw_vertices_from_bound_vertex_array(GL_TRIANGLES, 0, 6);
    } else {
        for pass_index: 0..GRID_DEPTH_PASS_COUNT - 1 {
            // Four iterations begin at t={0,.25,.5,.75}. Leaving the final
            // endpoint unused keeps the last pass from being pulled fully in
            // front of coplanar scene geometry.
            factor := cast(float32) pass_index / cast(float32) GRID_DEPTH_PASS_COUNT;
            depth_offset := GRID_CLIP_DEPTH_OFFSET_BACK
                + (GRID_CLIP_DEPTH_OFFSET_FRONT - GRID_CLIP_DEPTH_OFFSET_BACK) * factor;
            pass_alpha := 1.0 / cast(float32) (1 << pass_index);
            set_grid_clip_depth_offset_uniform(*renderer, depth_offset);
            set_grid_pass_alpha_uniform(*renderer, pass_alpha);
            gl_draw_vertices_from_bound_vertex_array(GL_TRIANGLES, 0, 6);
        }
    }

    gl_bind_vertex_array(0);
    gl_clear_active_shader_program();

    // Restore the standard scene-rendering state expected by later passes.
    gl_set_depth_writes_enabled(GL_TRUE);
    gl_set_depth_test_pass_condition(GL_LESS);
    gl_disable_blending();
}
