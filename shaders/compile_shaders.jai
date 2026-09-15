#import "Basic";
#import "File";
#import "File_Utilities";
#import "String";
#import "Compiler";

Compile_Data :: struct {
    src_dir: string;
    out_dir: string;
}

process_shader :: (file_path: string, current_dir: string, included_files: *[..] string) -> string, bool {
    contents, success := read_entire_file(file_path);
    if !success {
        print("Error: Could not read file: %\n", file_path);
        return "", false;
    }

    builder: String_Builder;
    init_string_builder(*builder);

    remaining := contents;
    while remaining.count > 0 {
        line: string;
        line, remaining = consume_line(remaining);

        trimmed := trim(line);
        if begins_with(trimmed, "#include") {
            quote_start := find_index_from_left(trimmed, #char "\"");
            if quote_start < 0 {
                append(*builder, line);
                append(*builder, "\n");
                continue;
            }
            quote_end := find_index_from_left(trimmed, #char "\"", quote_start + 1);
            if quote_end < 0 {
                append(*builder, line);
                append(*builder, "\n");
                continue;
            }

            include_path := slice(trimmed, quote_start + 1, quote_end - quote_start - 1);
            full_include_path := tprint("%/%", current_dir, include_path);

            already_included := false;
            for included_files.* {
                if it == full_include_path {
                    already_included = true;
                    break;
                }
            }

            if already_included continue;

            if !file_exists(full_include_path) {
                print("Error: Included file not found: %\n", full_include_path);
                return "", false;
            }

            array_add(included_files, copy_string(full_include_path));

            include_dir := path_strip_filename(full_include_path);
            included_content, inc_success := process_shader(full_include_path, include_dir, included_files);
            if !inc_success {
                return "", false;
            }

            append(*builder, tprint("// Begin include: %\n", include_path));
            append(*builder, included_content);
            append(*builder, tprint("// End include: %\n", include_path));
        } else {
            append(*builder, line);
            append(*builder, "\n");
        }
    }

    result := builder_to_string(*builder);
    return result, true;
}

consume_line :: (s: string) -> (line: string, rest: string) {
    for i: 0..s.count-1 {
        if s[i] == #char "\n" {
            line: string;
            line.data = s.data;
            line.count = i;
            rest: string;
            rest.data = s.data + i + 1;
            rest.count = s.count - i - 1;
            return line, rest;
        }
    }
    return s, "";
}

is_shader_file :: (filename: string) -> bool {
    return ends_with(filename, ".glsl") || ends_with(filename, ".frag") || ends_with(filename, ".vert");
}

shader_visitor :: (info: *File_Visit_Info, data: *Compile_Data) {
    if !is_shader_file(info.full_name) return;

    src_path := info.full_name;
    relative := advance(src_path, data.src_dir.count);
    if relative.count > 0 && relative[0] == #char "/" {
        relative = advance(relative, 1);
    }

    out_path := tprint("%/%", data.out_dir, relative);

    out_subdir := path_strip_filename(out_path);
    make_directory_if_it_does_not_exist(out_subdir, recursive = true);

    included_files: [..] string;
    src_file_dir := path_strip_filename(src_path);
    processed, success := process_shader(src_path, src_file_dir, *included_files);
    if !success {
        print("Error: Failed to process: %\n", relative);
        return;
    }

    write_success := write_entire_file(out_path, processed);
    if !write_success {
        print("Error: Could not write: %\n", relative);
    }
}

compile_shaders :: (src_dir: string, out_dir: string) {
    data: Compile_Data;
    data.src_dir = src_dir;
    data.out_dir = out_dir;

    make_directory_if_it_does_not_exist(out_dir, recursive = true);

    visit_files(src_dir, recursive = true, *data, shader_visitor, visit_directories = false);
}

#run {
    set_build_options_dc(.{do_output = false});

    src_dir := tprint("%/src", #filepath);
    out_dir := tprint("%/out", #filepath);

    compile_shaders(src_dir, out_dir);
}
