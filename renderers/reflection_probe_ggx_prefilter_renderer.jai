// auto-generated renderer for shader: Reflection_Probe_Ggx_Prefilter
// do not edit manually.


Reflection_Probe_Ggx_Prefilter_Renderer :: struct {
    using #as psr : Per_Shader_Renderer;





}


init :: (using renderer : *Reflection_Probe_Ggx_Prefilter_Renderer) {
    vertex_shader_source := #run read_entire_file(tprint("%../shaders/out/fullscreen_quad.vert", #filepath));
    fragment_shader_source := #run read_entire_file(tprint("%../shaders/out/reflection_probe_ggx_prefilter.frag", #filepath));

    init(renderer, vertex_shader_source, fragment_shader_source, max_num_elements_in_each_buffer);



}


deinit :: (using renderer : *Reflection_Probe_Ggx_Prefilter_Renderer) {
    deinit(*psr);

}
