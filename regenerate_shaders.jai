#import "Basic";
#import "Compiler";
#import "File";
#import "Process";

// Loading this file runs the legacy GLSL include preprocessor first.
#load "shaders/compile_shaders.jai";

run_opengl_shader_generation_tool :: (source_path: string, output_name: string) {
    output_directory := tprint("%../../../.build/opengl_shader_tools/", #filepath);
    make_directory_if_it_does_not_exist(output_directory, recursive = true);

    workspace := compiler_create_workspace(output_name);
    options := get_build_options(workspace);
    copy_commonly_propagated_fields(get_build_options(), *options);
    options.output_executable_name = output_name;
    options.output_path = output_directory;
    options.intermediate_path = output_directory;

    import_path: [..] string;
    array_add(*import_path, ..options.import_path);
    array_add(*import_path, tprint("%../../", #filepath));
    options.import_path = import_path;
    set_build_options(options, workspace);

    compiler_begin_intercept(workspace);
    add_build_file(source_path, workspace);
    while true {
        message := compiler_wait_for_message();
        if message.kind == {
            case .ERROR;
                exit(1);
            case .COMPLETE;
                break;
        }
    }
    compiler_end_intercept(workspace);

    executable_path := tprint("%%", output_directory, output_name);
    #if OS == .WINDOWS executable_path = tprint("%.exe", executable_path);
    project_root := tprint("%../../../", #filepath);
    result := run_command(executable_path, working_directory = project_root);
    if result.exit_code != 0 {
        log_error("% failed with exit code %", output_name, result.exit_code);
        exit(1);
    }
}

#run {
    set_build_options_dc(.{do_output = false});
    run_opengl_shader_generation_tool(
        tprint("%tools/generate_gpu_style_shaders.jai", #filepath),
        "generate_gpu_style_shaders"
    );
    run_opengl_shader_generation_tool(
        tprint("%tools/generate_shader_renderers.jai", #filepath),
        "generate_shader_renderers"
    );
}
