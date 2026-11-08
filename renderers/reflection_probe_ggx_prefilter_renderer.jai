// auto-generated renderer for shader: Reflection_Probe_Ggx_Prefilter
// do not edit manually.


Reflection_Probe_Ggx_Prefilter_Renderer :: struct {
    using #as psr : Per_Shader_Renderer = .{max_num_elements_in_each_buffer = 100000};





}


init :: (using renderer : *Reflection_Probe_Ggx_Prefilter_Renderer) -> bool {
    vertex_shader_source := #run read_entire_file(tprint("%../shaders/out/fullscreen_quad.vert", #filepath));
    fragment_shader_source := #run read_entire_file(tprint("%../shaders/out/reflection_probe_ggx_prefilter.frag", #filepath));

    if !init(*renderer.psr, vertex_shader_source, fragment_shader_source, max_num_elements_in_each_buffer) return false;



    return true;
}


deinit :: (using renderer : *Reflection_Probe_Ggx_Prefilter_Renderer) {
    deinit(*psr);

}
