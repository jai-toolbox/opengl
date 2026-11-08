/*
Load a mesh and its atlas once, then animate by changing two UV offsets. Camera
movement only updates triangle order for transparent meshes. This renderer
does not import any authored effect shader or require a bake context.
*/
#scope_module
#import "Basic";
#import "Math";
#import "GL";
#import "File";
#import "tbx/opengl";
#import "tbx/effect_geometry";
using #import "tbx/virtual_gpu_rendering/shaders/animated_mesh";
GPU :: struct { #insert #run animated_mesh_generated_renderer_source(); }

animated_mesh_generated_renderer_source :: () -> string {
    mesh, mesh_ok := read_entire_file(tprint("%../generated/animated_mesh/mesh/animated_mesh_renderer.jai", #filepath));
    display, display_ok := read_entire_file(tprint("%../generated/animated_mesh/display/animated_mesh_display_renderer.jai", #filepath));
    assert(mesh_ok && display_ok, "Generate animated-mesh renderers before compiling playback");
    return tprint("%\n%", mesh, display);
}
#scope_export

Animated_Mesh_Renderer :: struct {
    mesh: GPU.Animated_Mesh_Renderer;
    display: GPU.Animated_Mesh_Display_Renderer;
    texture: GLuint;
    object: u32;
    buffered: bool;
    sorted_revision: u64;
    sorted_eye: Vector3;
    sort_valid: bool;
}

init_animated_mesh_renderer :: (renderer: *Animated_Mesh_Renderer, asset: *Effect_Asset) -> bool {
    deinit_animated_mesh_renderer(renderer);
    if asset.image.width <= 0 || asset.image.height <= 0 ||
        asset.image.pixels.count != cast(s64) asset.image.width*asset.image.height return false;
    limit: GLint;
    gl_get_integer_state_parameter(GL_MAX_TEXTURE_SIZE, *limit);
    if asset.image.width > limit || asset.image.height > limit return false;
    success := false;
    defer if !success deinit_animated_mesh_renderer(renderer);
    renderer.mesh.max_num_elements_in_each_buffer = cast(u32) max(asset.mesh.vertices.count, 3);
    if !GPU.init(*renderer.mesh) || !GPU.init(*renderer.display) return false;
    vertices: [..] Animated_Mesh_Vertex; defer array_free(vertices);
    array_resize(*vertices, asset.mesh.vertices.count);
    for v, i: asset.mesh.vertices vertices[i] = .{position = v.world_position, normal = v.normal, uv = v.quad_uv, spacing = v.slice_spacing};
    if vertices.count > 0 {
        object, ok := GPU.buffer_object(*renderer.mesh, vertices, asset.mesh.indices);
        if !ok return false;
        renderer.object = object; renderer.buffered = true;
    }
    renderer.texture = gl_create_texture();
    gl_set_active_texture_unit(GL_TEXTURE0);
    gl_bind_texture_to_binding_target_of_active_texture_unit(GL_TEXTURE_2D, renderer.texture);
    gl_define_texture_2d_image_for_active_texture_unit(GL_TEXTURE_2D, 0, GL_RGBA32F,
        xx asset.image.width, xx asset.image.height, 0, GL_RGBA, GL_FLOAT, asset.image.pixels.data);
    allocated_width: GLint;
    gl_get_integer_parameter_for_texture_level_bound_to_binding_target_of_active_texture_unit(GL_TEXTURE_2D, 0, GL_TEXTURE_WIDTH, *allocated_width);
    if allocated_width != asset.image.width return false;
    gl_set_integer_parameter_for_texture_bound_to_binding_target_of_active_texture_unit(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    gl_set_integer_parameter_for_texture_bound_to_binding_target_of_active_texture_unit(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    gl_set_integer_parameter_for_texture_bound_to_binding_target_of_active_texture_unit(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    gl_set_integer_parameter_for_texture_bound_to_binding_target_of_active_texture_unit(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    success = true;
    return true;
}

deinit_animated_mesh_renderer :: (renderer: *Animated_Mesh_Renderer) {
    GPU.deinit(*renderer.mesh);
    GPU.deinit(*renderer.display);
    gl_delete_texture(renderer.texture);
    renderer.* = .{};
}

draw_animated_mesh :: (renderer: *Animated_Mesh_Renderer, asset: *Effect_Asset, seconds: float32,
                       world_to_clip: Matrix4, eye: Vector3, direction: Vector3,
                       orthographic: bool = false, emission: float32 = 1) {
    if !renderer.buffered return;
    if !renderer.sort_valid || renderer.sorted_revision != asset.mesh.revision || renderer.sorted_eye != eye {
        sort_effect_mesh(*asset.mesh, eye);
        assert(GPU.update_object_indices(*renderer.mesh, renderer.object, asset.mesh.indices));
        renderer.sorted_revision = asset.mesh.revision; renderer.sorted_eye = eye; renderer.sort_valid = true;
    }
    frame := effect_animation_frame(*asset.animation, seconds);
    gl_discard_fragments_that_fail_depth_test(false);
    gl_set_depth_writes_enabled(GL_FALSE);
    gl_set_face_culling_enabled(false);
    gl_set_framebuffer_srgb(false);
    gl_enable_blending();
    gl_set_blend_equation(GL_FUNC_ADD);
    gl_set_separate_blend_function(GL_ONE, GL_ONE_MINUS_SRC_ALPHA, GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    GPU.set_uniforms(*renderer.mesh, .{world_to_clip = world_to_clip, image = renderer.texture,
        first_offset = frame.first_offset, second_offset = frame.second_offset, frame_mix = frame.blend,
        eye = eye, direction = direction, orthographic = orthographic,
        volume = asset.mode == .VOLUME_SLICES, blend_axis_stacks = asset.blend_axis_stacks, emission = emission});
    GPU.queue_render(*renderer.mesh, renderer.object);
    GPU.render(*renderer.mesh);
}

draw_animated_mesh_display :: (renderer: *Animated_Mesh_Renderer, texture: GLuint,
                              exposure: float32 = 0, tone_map: bool = true) {
    gl_discard_fragments_that_fail_depth_test(false); gl_disable_blending();
    gl_set_framebuffer_srgb(false);
    GPU.set_uniforms(*renderer.display, .{image = texture, exposure = exposure, tone_map = tone_map});
    GPU.render(*renderer.display);
}
