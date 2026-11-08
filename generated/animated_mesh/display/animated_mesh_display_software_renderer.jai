// Generated concrete software adapter. Bind vertex_shader and fragment_shader
// from the native pipeline value when constructing the renderer.
Animated_Mesh_Display_Software_Renderer :: struct {
    vertex_shader: (input: Fullscreen_Vertex_Input, output: *Fullscreen_Vertex_Output);
    fragment_shader: (ctx: Animated_Mesh_Display_Uniforms, input: Fullscreen_Fragment_Input, output: *GLSL_Fragment_Color_Output);
}

evaluate_vertex_shader :: (renderer: *Animated_Mesh_Display_Software_Renderer, input: Fullscreen_Vertex_Input) -> Fullscreen_Vertex_Output {
    output: Fullscreen_Vertex_Output;
    renderer.vertex_shader(input, *output);
    return output;
}

evaluate_fragment_shader :: (renderer: *Animated_Mesh_Display_Software_Renderer, input: Fullscreen_Fragment_Input, ctx: Animated_Mesh_Display_Uniforms = .{}) -> GLSL_Fragment_Color_Output {
    output: GLSL_Fragment_Color_Output;
    renderer.fragment_shader(ctx, input, *output);
    return output;
}

Animated_Mesh_Display_interpolate_fragment :: (a: Fullscreen_Vertex_Output, b: Fullscreen_Vertex_Output, c: Fullscreen_Vertex_Output,
                         w0: float32, w1: float32, w2: float32) -> Fullscreen_Fragment_Input {
    result: Fullscreen_Fragment_Input;
    result.uv = a.uv * w0 + b.uv * w1 + c.uv * w2;

    return result;
}

render :: (renderer: *Animated_Mesh_Display_Software_Renderer, target: *Software_Render_Target,
           vertices: [] Fullscreen_Vertex_Input, indices: [] u32, fragment_context: Animated_Mesh_Display_Uniforms = .{}) {
    assert(indices.count % 3 == 0);
    assert(target.pixels.count >= target.width * target.height && target.depth.count >= target.width * target.height);
    for triangle: 0..indices.count / 3 - 1 {
        outputs: [3] Fullscreen_Vertex_Output;
        for corner: 0..2 {
            index := indices[triangle * 3 + corner];
            assert(index < vertices.count, "Vertex index is outside the supplied vertex buffer");
            input := vertices[index];
            input.gpu.vertex_index = cast(s32) index;
            input.gpu.instance_index = 0;
            outputs[corner] = evaluate_vertex_shader(renderer, input);
        }
        p0_clip := outputs[0].gpu.position;
        p1_clip := outputs[1].gpu.position;
        p2_clip := outputs[2].gpu.position;
        if virtual_gpu_triangle_is_trivially_clipped(p0_clip, p1_clip, p2_clip) continue;
        p0 := virtual_gpu_clip_position_to_screen(p0_clip, target.width, target.height);
        p1 := virtual_gpu_clip_position_to_screen(p1_clip, target.width, target.height);
        p2 := virtual_gpu_clip_position_to_screen(p2_clip, target.width, target.height);
        area := virtual_gpu_edge2(p0.x, p0.y, p1.x, p1.y, p2.x, p2.y);
        if abs(area) < 0.00001 continue;
        min_x := max(fast_floor_s32(min(p0.x, min(p1.x, p2.x))), 0);
        max_x := min(fast_ceil_s32(max(p0.x, max(p1.x, p2.x))), target.width - 1);
        min_y := max(fast_floor_s32(min(p0.y, min(p1.y, p2.y))), 0);
        max_y := min(fast_ceil_s32(max(p0.y, max(p1.y, p2.y))), target.height - 1);
        if min_x > max_x || min_y > max_y continue;
        for y: min_y..max_y for x: min_x..max_x {
            px := cast(float32) x + 0.5; py := cast(float32) y + 0.5;
            w0 := virtual_gpu_edge2(p1.x, p1.y, p2.x, p2.y, px, py) / area;
            w1 := virtual_gpu_edge2(p2.x, p2.y, p0.x, p0.y, px, py) / area;
            w2 := 1.0 - w0 - w1;
            if w0 < 0 || w1 < 0 || w2 < 0 continue;
            depth := p0.z * w0 + p1.z * w1 + p2.z * w2;
            if depth < 0 || depth > 1 continue;
            inv_w := w0 / p0_clip.w + w1 / p1_clip.w + w2 / p2_clip.w;
            input := Animated_Mesh_Display_interpolate_fragment(outputs[0], outputs[1], outputs[2],
                w0 / p0_clip.w / inv_w, w1 / p1_clip.w / inv_w, w2 / p2_clip.w / inv_w);
            input.gpu.fragment_coord = .{px, cast(float32) target.height - py, depth, inv_w};
            input.gpu.front_facing = area > 0;
            input.gpu.point_coord = .{};
            output := evaluate_fragment_shader(renderer, input, fragment_context);

            z := cast(u32) (depth * DEPTH_SCALE);
            pixel := y * target.width + x;
            if z >= target.depth[pixel] continue;
            color := output.color;
            target.pixels[pixel] = framebuffer_pack_from_normalized_rgba(color);
            target.depth[pixel] = z;
        }
    }
}
