#import "Basic";
#import "File";
#import "String";
#import "tbx/software_rasterizer";

write_generated_shader_program_file :: (
    shader_prefix: string,
    shader_output_directory: string,
    program_directory: string
) -> bool {
    make_directory_if_it_does_not_exist(program_directory, recursive = true);

    program_path := tprint("%/%.program", program_directory, shader_prefix);
    vertex_path := tprint("%/%.vert", shader_output_directory, shader_prefix);
    fragment_path := tprint("%/%.frag", shader_output_directory, shader_prefix);

    builder: String_Builder;
    init_string_builder(*builder);
    print_to_builder(*builder, "Shader_Program_Metadata.{\n");
    print_to_builder(*builder, "    vertex_shader_path = \"%\",\n", vertex_path);
    print_to_builder(*builder, "    fragment_shader_path = \"%\"\n", fragment_path);
    print_to_builder(*builder, "}\n");

    return write_entire_file(program_path, builder_to_string(*builder));
}

generate_gpu_style_shader_program :: (
    source_path: string,
    shader_prefix: string,
    shader_output_directory: string,
    program_directory: string
) -> bool {
    return generate_gpu_style_shader_program_from_base(
        source_path,
        shader_prefix,
        shader_prefix,
        shader_output_directory,
        program_directory
    );
}

generate_gpu_style_shader_program_from_base :: (
    source_path: string,
    base_shader_prefix: string,
    output_shader_prefix: string,
    shader_output_directory: string,
    program_directory: string
) -> bool {
    result := generate_gpu_style_glsl_from_source_file(
        source_path,
        output_shader_prefix,
        shader_output_directory,
        base_shader_prefix
    );

    if !result.success {
        print("Failed to generate GPU-style GLSL shaders for %: %\n", source_path, result.error);
        return false;
    }

    if !write_generated_shader_program_file(output_shader_prefix, shader_output_directory, program_directory) {
        print("Failed to generate shader program file for %.\n", output_shader_prefix);
        return false;
    }

    return true;
}

GPU_Style_Shader_Variant :: enum {
    Directional_Shadows;
    Skeletal_Animation;
    Directional_Shadows_Skeletal_Animation;
}

GPU_Style_Shader_Generation_Request :: struct {
    source_path: string;
    shader_prefix: string;
    variants: [] GPU_Style_Shader_Variant;
}

generate_gpu_style_shader_request :: (
    request: GPU_Style_Shader_Generation_Request,
    shader_output_directory: string,
    program_directory: string
) -> bool {
    if !generate_gpu_style_shader_program(
        request.source_path,
        request.shader_prefix,
        shader_output_directory,
        program_directory
    ) return false;

    for variant: request.variants {
        if variant == .Directional_Shadows {
            if request.shader_prefix != "gpu_style_pbr" {
                print("Directional_Shadows variant is currently only implemented for gpu_style_pbr.\n");
                return false;
            }

            if !generate_gpu_style_shader_program_from_base(
                request.source_path,
                request.shader_prefix,
                "gpu_style_pbr_directional_shadow_depth",
                shader_output_directory,
                program_directory
            ) return false;

            if !generate_gpu_style_shader_program_from_base(
                request.source_path,
                request.shader_prefix,
                "gpu_style_pbr_directional_shadows",
                shader_output_directory,
                program_directory
            ) return false;
        } else if variant == .Skeletal_Animation {
            if request.shader_prefix != "gpu_style_pbr" {
                print("Skeletal_Animation variant is currently only implemented for gpu_style_pbr.\n");
                return false;
            }

            if !generate_gpu_style_shader_program_from_base(
                request.source_path,
                request.shader_prefix,
                "gpu_style_pbr_skeletal_animation",
                shader_output_directory,
                program_directory
            ) return false;
        } else if variant == .Directional_Shadows_Skeletal_Animation {
            if request.shader_prefix != "gpu_style_pbr" {
                print("Directional_Shadows_Skeletal_Animation variant is currently only implemented for gpu_style_pbr.\n");
                return false;
            }

            if !generate_gpu_style_shader_program_from_base(
                request.source_path,
                request.shader_prefix,
                "gpu_style_pbr_directional_shadow_depth_skeletal_animation",
                shader_output_directory,
                program_directory
            ) return false;

            if !generate_gpu_style_shader_program_from_base(
                request.source_path,
                request.shader_prefix,
                "gpu_style_pbr_directional_shadows_skeletal_animation",
                shader_output_directory,
                program_directory
            ) return false;
        }
    }

    return true;
}

main :: () {
    shader_output_directory :: "src/tbx/opengl/shaders/generated";
    program_directory :: "src/tbx/opengl/shaders/programs";

    pbr_variants := GPU_Style_Shader_Variant.[
        .Directional_Shadows,
        .Skeletal_Animation,
        .Directional_Shadows_Skeletal_Animation
    ];

    requests := GPU_Style_Shader_Generation_Request.[
        .{
            source_path = "src/tbx/software_rasterizer/gpu_style_shaders/vertex_color.jai",
            shader_prefix = "gpu_style_vertex_color"
        },
        .{
            source_path = "src/tbx/software_rasterizer/gpu_style_shaders/blinn_phong.jai",
            shader_prefix = "gpu_style_blinn_phong"
        },
        .{
            source_path = "src/tbx/software_rasterizer/gpu_style_shaders/pbr.jai",
            shader_prefix = "gpu_style_pbr",
            variants = pbr_variants
        },
        .{
            source_path = "src/tbx/software_rasterizer/gpu_style_shaders/pbr_lightmapped.jai",
            shader_prefix = "gpu_style_pbr_lightmapped"
        }
    ];

    for request: requests {
        if !generate_gpu_style_shader_request(request, shader_output_directory, program_directory) exit(1);
    }
}
