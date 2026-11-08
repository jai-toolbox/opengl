#scope_file
Tbx_File :: #import "tbx/file";
#scope_export

Generated_Rendering_Pipeline :: struct {
    success : bool;
    error : string;
    vertex_source, fragment_source : string;
    program_source, renderer_source : string;
    vertex_path, fragment_path, program_path, renderer_path : string;
}

Rendering_Pipeline_Generation_Options :: struct {
    // Also prefixes generated Jai symbols, so this must be a valid Jai identifier.
    generated_file_name_prefix : string;
    library: VGR.GLSL_Library_Options;
    renderer : Shader_Program_Metadata;
}

// Coordinate shared Jai-to-GLSL and .program generation, then read the saved
// descriptor to generate the OpenGL renderer. Descriptor data and serialization
// belong to virtual_gpu_rendering; CPU adapters belong to software_rasterizer.
generate_rendering_pipeline :: (
    pipeline: $Pipeline/VGR.Virtual_GPU_Rendering_Pipeline,
    target_directory: string,
    options: Rendering_Pipeline_Generation_Options
) -> Generated_Rendering_Pipeline {
    
    // first we validate if the shader would work, can this be better?
    
    signature := VGR.analyze_rendering_pipeline(pipeline);
    if !signature.success return .{error=signature.error};
    
    prepared := VGR.prepare_virtual_pipeline_glsl_source(pipeline, options.library);
    
    return generate_rendering_pipeline(pipeline, prepared, target_directory, options);
    
}

generate_rendering_pipeline :: (
    pipeline: $Pipeline/VGR.Virtual_GPU_Rendering_Pipeline,
    prepared: VGR.Analyzed_Jai_Source_For_GLSL,
    target_directory: string, 
    options: Rendering_Pipeline_Generation_Options
) -> Generated_Rendering_Pipeline {
    
    if !VGR.pipeline_generation_identifier_valid(options.generated_file_name_prefix) return .{error = "Generated file name prefix must be a Jai identifier"};
    
    signature:=VGR.analyze_rendering_pipeline(pipeline);
    if !signature.success return .{error=signature.error};
    gpu_rendering_pipeline_stages:=VGR.generate_glsl_gpu_rendering_pipeline_stages(pipeline,prepared,options.library);
    if !gpu_rendering_pipeline_stages.success return .{error=gpu_rendering_pipeline_stages.error};
    vertex:=gpu_rendering_pipeline_stages.vertex; fragment:=gpu_rendering_pipeline_stages.fragment;
    vertex_info: *Type_Info;
    if vertex.gpu_rendering_pipeline_stage_interface.attributes.count > 0 vertex_info=signature.vertex.input_type;
    shader := shader_metadata_from_gpu_rendering_pipeline_stage_type_info(options.generated_file_name_prefix, vertex, fragment, "", "", vertex_info, options.renderer);
    if vertex.gpu_rendering_pipeline_stage_interface.attributes.count == 0 && !shader.vertex_shader_supplies_geometry
        return .{error = "A vertex shader without attributes requires renderer.vertex_shader_supplies_geometry and renderer.vertex_count"};
    valid, renderer_error := shader_renderer_metadata_valid(shader);
    if !valid return .{error = renderer_error};
    program := shader_program_from_typed_metadata(shader, options.renderer);
    stem := to_lower_copy(options.generated_file_name_prefix);
    
    result: Generated_Rendering_Pipeline;
    result.vertex_source = vertex.source; result.fragment_source = fragment.source;
    result.vertex_path = Tbx_File.resolve_path_against_base(target_directory, tprint("%.vert", stem));
    result.fragment_path = Tbx_File.resolve_path_against_base(target_directory, tprint("%.frag", stem));
    result.program_path = Tbx_File.resolve_path_against_base(target_directory, tprint("%.program", stem));
    result.renderer_path = Tbx_File.resolve_path_against_base(target_directory, tprint("%_renderer.jai", stem));
    program.vertex_shader_path = tprint("%.vert", stem);
    program.fragment_shader_path = tprint("%.frag", stem);
    program.renderer_path = tprint("%_renderer.jai", stem);
    program.paths_relative_to_program = true;
    program.embed_shader_sources = true;
    result.program_source = shader_program_metadata_source(program);
    if !make_directory_if_it_does_not_exist(target_directory,recursive=true) return .{error=tprint("Could not create pipeline output directory %",target_directory)};
    if !write_entire_file(result.vertex_path, result.vertex_source) ||
       !write_entire_file(result.fragment_path, result.fragment_source) ||
       !write_entire_file(result.program_path, result.program_source) return .{error = "Could not write generated pipeline files"};
    // Read the written descriptor, just like the standalone .program visitor.
    renderer := create_code_to_render_stuff_with_shader_from_program(result.program_path);
    if !renderer.success return .{error = renderer.error};
    result.renderer_source = renderer.source;
    result.success=true;
    return result;
}

