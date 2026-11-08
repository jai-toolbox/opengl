#scope_file
Tbx_File :: #import "tbx/file";
#scope_export

// Optional host bindings supplement GLSL reflection with information that GLSL
// cannot retain: native Jai types, using-field paths and CPU sampler replacements.
Shader_Program_Jai_Bindings :: struct {
    vertex_type: string;
    attributes: [..] Shader_Program_Attribute_Binding;
    uniform_groups: [..] GL_Uniform_Group;
    uniforms: [..] Shader_Program_Uniform_Binding;
}

Shader_Program_Attribute_Binding :: struct {
    shader_name, field: string;
}

Shader_Program_Uniform_Binding :: struct {
    type_name, shader_name, value_expression: string;
    group_index: u32;
}

Generated_Shader_Renderer :: struct {
    success: bool;
    error, source, path: string;
}

shader_program_resolve_path :: (program_path: string, program: Shader_Program_Metadata, path: string) -> string {
    if program.paths_relative_to_program
        return Tbx_File.resolve_path_against_base(Tbx_File.directory_for_path(program_path), path);
    // Existing module descriptors use project-root paths. Resolve these from
    // the module too, so generation does not depend on the caller's directory.
    for prefix: string.["modules/tbx/opengl/", "src/tbx/opengl/", "data/shaders/"] {
        if !starts_with(path, prefix) continue;
        base := tprint("%..", #filepath);
        if prefix == "data/shaders/" base = tprint("%../shaders", #filepath);
        return Tbx_File.resolve_path_against_base(base, advance(path, prefix.count));
    }
    return path;
}

write_shader_program_renderer :: (source: string, path: string) -> Generated_Shader_Renderer {
    directory := Tbx_File.directory_for_path(path);
    if directory.count > 0 && !make_directory_if_it_does_not_exist(directory, recursive = true)
        return .{error = tprint("Could not create renderer output directory %", directory)};
    if !write_entire_file(path, source) return .{error = tprint("Could not write renderer %", path)};
    return .{success = true, source = source, path = path};
}

shader_program_renderer_source :: (metadata: Shader_Metadata, program_path: string, program: Shader_Program_Metadata, vertex_source: string, fragment_source: string) -> string {
    shader := metadata;
    if !program.embed_shader_sources {
        if program.paths_relative_to_program || program.renderer_path.count > 0 {
            vertex_path, vertex_ok := get_absolute_path(shader_program_resolve_path(program_path, program, metadata.vertex_shader_path));
            fragment_path, fragment_ok := get_absolute_path(shader_program_resolve_path(program_path, program, metadata.fragment_shader_path));
            assert(vertex_ok && fragment_ok);
            shader.vertex_source_expression = tprint("#run read_entire_file(\"%\")", Tbx_File.escape_string(vertex_path));
            shader.fragment_source_expression = tprint("#run read_entire_file(\"%\")", Tbx_File.escape_string(fragment_path));
        }
        return generate_shader_renderer_code(shader);
    }
    shader.vertex_source_expression = tprint("%_Vertex_Source", shader.name);
    shader.fragment_source_expression = tprint("%_Fragment_Source", shader.name);
    return tprint("%\n%\n%", generate_shader_renderer_code(shader),
        pipeline_shader_source_constant(shader.vertex_source_expression, vertex_source),
        pipeline_shader_source_constant(shader.fragment_source_expression, fragment_source));
}

pipeline_shader_source_constant :: (name: string, source: string) -> string {
    delimiter := tprint("END_%", name);
    while contains(source, delimiter) delimiter = tprint("%_", delimiter);
    return tprint("% :: #string %\n%\n%\n", name, delimiter, source, delimiter);
}

shader_program_from_typed_metadata :: (shader: Shader_Metadata, options: Shader_Program_Metadata) -> Shader_Program_Metadata {
    program := options;
    program.name = shader.name;
    program.jai_bindings = .{};
    program.jai_bindings.vertex_type = shader.native_vertex_type_name;
    for attribute: shader.attribute_configs
        array_add(*program.jai_bindings.attributes, .{attribute.var_name_in_shader, attribute.native_field_path});
    for group: shader.uniform_groups array_add(*program.jai_bindings.uniform_groups, group);
    for uniform: shader.uniform_configs {
        assert(uniform.group_index >= 0);
        array_add(*program.jai_bindings.uniforms, .{uniform.glsl_type_name, uniform.var_name_in_shader,
            uniform.value_expression, cast(u32) uniform.group_index});
    }
    return program;
}

shader_program_metadata_source :: (program: Shader_Program_Metadata) -> string {
    builder: String_Builder;
    init_string_builder(*builder);
    append(*builder, "Shader_Program_Metadata.{\n");
    print_to_builder(*builder, "    name = \"%\",\n", Tbx_File.escape_string(program.name));
    print_to_builder(*builder, "    vertex_shader_path = \"%\",\n", Tbx_File.escape_string(program.vertex_shader_path));
    print_to_builder(*builder, "    fragment_shader_path = \"%\",\n", Tbx_File.escape_string(program.fragment_shader_path));
    if program.renderer_path.count > 0
        print_to_builder(*builder, "    renderer_path = \"%\",\n", Tbx_File.escape_string(program.renderer_path));
    if program.paths_relative_to_program append(*builder, "    paths_relative_to_program = true,\n");
    if program.embed_shader_sources append(*builder, "    embed_shader_sources = true,\n");
    if program.per_object_transforms append(*builder, "    per_object_transforms = true,\n");
    if program.immediate_mode_support append(*builder, "    immediate_mode_support = true,\n");
    if program.num_elements_in_each_buffer != 100000
        print_to_builder(*builder, "    num_elements_in_each_buffer = %,\n", program.num_elements_in_each_buffer);
    if program.num_elements_in_each_immediate_buffer != 65536
        print_to_builder(*builder, "    num_elements_in_each_immediate_buffer = %,\n", program.num_elements_in_each_immediate_buffer);
    if program.primitive_mode != GL_TRIANGLES
        print_to_builder(*builder, "    primitive_mode = %,\n", gl_primitive_mode_to_string(program.primitive_mode));
    if program.vertex_shader_supplies_geometry append(*builder, "    vertex_shader_supplies_geometry = true,\n");
    if program.vertex_count != 0 print_to_builder(*builder, "    vertex_count = %,\n", program.vertex_count);
    bindings := program.jai_bindings;
    if bindings.vertex_type.count > 0 || bindings.uniform_groups.count > 0 {
        append(*builder, "    jai_bindings = .{\n");
        if bindings.vertex_type.count > 0
            print_to_builder(*builder, "        vertex_type = \"%\",\n", Tbx_File.escape_string(bindings.vertex_type));
        if bindings.attributes.count > 0 {
            append(*builder, "        attributes = .[\n");
            for attribute: bindings.attributes print_to_builder(*builder, "            .{shader_name = \"%\", field = \"%\"},\n",
                Tbx_File.escape_string(attribute.shader_name), Tbx_File.escape_string(attribute.field));
            append(*builder, "        ],\n");
        }
        if bindings.uniform_groups.count > 0 {
            append(*builder, "        uniform_groups = .[\n");
            for group: bindings.uniform_groups {
                print_to_builder(*builder, "            .{shader_name = \"%\", jai_type_name = \"%\", host_type_name = \"%\"",
                    Tbx_File.escape_string(group.shader_name), Tbx_File.escape_string(group.jai_type_name), Tbx_File.escape_string(group.host_type_name));
                if group.declarations.count > 0 print_to_builder(*builder, ", declarations = \"%\"", Tbx_File.escape_string(group.declarations));
                append(*builder, "},\n");
            }
            append(*builder, "        ],\n        uniforms = .[\n");
            for uniform: bindings.uniforms print_to_builder(*builder,
                "            .{type_name = \"%\", shader_name = \"%\", value_expression = \"%\", group_index = %},\n",
                Tbx_File.escape_string(uniform.type_name), Tbx_File.escape_string(uniform.shader_name),
                Tbx_File.escape_string(uniform.value_expression), uniform.group_index);
            append(*builder, "        ],\n");
        }
        append(*builder, "    },\n");
    }
    append(*builder, "}\n");
    return builder_to_string(*builder);
}

shader_program_field :: (node: *Shader_Parser.Node, name: string) -> *Shader_Parser.Node {
    if node == null || node.kind != .STRUCT_LITERAL_EXPR return null;
    for field: node.args if field.name == name return field.rhs;
    return null;
}

shader_program_metadata_field_value :: (node: *Shader_Parser.Node, name: string) -> (string, bool) {
    field := shader_program_field(node, name);
    if field == null return "", false;
    if field.kind == .IDENTIFIER_EXPR return field.name, true;
    if field.kind == .INT_LITERAL_EXPR return field.literal, true;
    if field.kind != .STRING_LITERAL_EXPR return "", false;
    literal := field.literal;
    if literal.count < 2 || literal[0] != #char "\"" || literal[literal.count-1] != #char "\"" return "", false;
    builder: String_Builder;
    init_string_builder(*builder);
    i := 1;
    while i < literal.count-1 {
        c := literal[i];
        if c == #char "\\" {
            i += 1;
            if i >= literal.count-1 return "", false;
            c = literal[i];
            if c == #char "n" append(*builder, "\n");
            else if c == #char "r" append(*builder, "\r");
            else if c == #char "t" append(*builder, "\t");
            else if c == #char "\\" || c == #char "\"" append(*builder, slice(literal, i, 1));
            else return "", false;
        } else append(*builder, slice(literal, i, 1));
        i += 1;
    }
    return builder_to_string(*builder), true;
}

shader_program_binding_array :: (node: *Shader_Parser.Node, name: string) -> ([] *Shader_Parser.Node, bool) {
    field := shader_program_field(node, name);
    if field == null return .[], true;
    if field.kind != .ARRAY_LITERAL_EXPR return .[], false;
    for entry: field.args if entry.kind != .STRUCT_LITERAL_EXPR return .[], false;
    return field.args, true;
}

read_shader_program_jai_bindings :: (root: *Shader_Parser.Node) -> (Shader_Program_Jai_Bindings, bool) {
    node := shader_program_field(root, "jai_bindings");
    if node == null return .{}, true;
    if node.kind != .STRUCT_LITERAL_EXPR return .{}, false;
    result: Shader_Program_Jai_Bindings;
    result.vertex_type = shader_program_metadata_field_value(node, "vertex_type");
    entries, ok := shader_program_binding_array(node, "attributes");
    if !ok return .{}, false;
    for entry: entries {
        binding: Shader_Program_Attribute_Binding;
        binding.shader_name = shader_program_metadata_field_value(entry, "shader_name");
        binding.field = shader_program_metadata_field_value(entry, "field");
        if binding.shader_name.count == 0 || binding.field.count == 0 return .{}, false;
        array_add(*result.attributes, binding);
    }
    entries, ok = shader_program_binding_array(node, "uniform_groups");
    if !ok return .{}, false;
    for entry: entries {
        group: GL_Uniform_Group;
        group.shader_name = shader_program_metadata_field_value(entry, "shader_name");
        group.jai_type_name = shader_program_metadata_field_value(entry, "jai_type_name");
        group.host_type_name = shader_program_metadata_field_value(entry, "host_type_name");
        group.declarations = shader_program_metadata_field_value(entry, "declarations");
        if group.jai_type_name.count == 0 || group.host_type_name.count == 0 return .{}, false;
        array_add(*result.uniform_groups, group);
    }
    entries, ok = shader_program_binding_array(node, "uniforms");
    if !ok return .{}, false;
    for entry: entries {
        binding: Shader_Program_Uniform_Binding;
        binding.type_name = shader_program_metadata_field_value(entry, "type_name");
        binding.shader_name = shader_program_metadata_field_value(entry, "shader_name");
        binding.value_expression = shader_program_metadata_field_value(entry, "value_expression");
        group_value, found := shader_program_metadata_field_value(entry, "group_index");
        binding.group_index, ok = shader_program_parse_u32(group_value);
        if !found || !ok || binding.group_index >= result.uniform_groups.count
            || binding.type_name.count == 0 || binding.shader_name.count == 0 || binding.value_expression.count == 0 return .{}, false;
        array_add(*result.uniforms, binding);
    }
    if result.vertex_type.count == 0 && result.attributes.count > 0 return .{}, false;
    return result, true;
}

// Attributes still come from GLSL reflection. Host bindings add the native
// overload and replace flat uniform setters with typed context setters.
apply_shader_program_jai_bindings :: (shader: *Shader_Metadata, bindings: Shader_Program_Jai_Bindings) -> (bool, string) {
    shader.native_vertex_type_name = bindings.vertex_type;
    if bindings.vertex_type.count > 0 {
        if bindings.attributes.count != shader.attribute_configs.count
            return false, "Jai vertex bindings must cover every GLSL attribute";
        for *attribute: shader.attribute_configs {
            found := false;
            for binding: bindings.attributes if binding.shader_name == attribute.var_name_in_shader {
                if found return false, tprint("Duplicate Jai binding for attribute %", binding.shader_name);
                attribute.native_field_path = binding.field;
                found = true;
            }
            if !found return false, tprint("Missing Jai binding for attribute %", attribute.var_name_in_shader);
        }
    }
    if bindings.uniform_groups.count == 0 return true, "";
    array_reset(*shader.uniform_configs);
    for group: bindings.uniform_groups array_add(*shader.uniform_groups, group);
    texture_unit: s32;
    for binding: bindings.uniforms {
        uniform := glsl_variable_to_uniform_configuration(.{type_name = binding.type_name, name = binding.shader_name});
        if uniform.type_in_jai == void return false, tprint("Unsupported uniform type %", binding.type_name);
        for existing: shader.uniform_configs if existing.var_name_in_shader == binding.shader_name
            return false, tprint("Duplicate uniform binding %", binding.shader_name);
        uniform.identifier = tprint("typed_%", shader.uniform_configs.count);
        uniform.value_expression = binding.value_expression;
        uniform.group_index = binding.group_index;
        if binding.type_name == "sampler2D" || binding.type_name == "sampler3D" {
            uniform.texture_target = cast(GLenum) (ifx binding.type_name == "sampler3D" then GL_TEXTURE_3D else GL_TEXTURE_2D);
            uniform.texture_unit = texture_unit;
            texture_unit += 1;
        }
        array_add(*shader.uniform_configs, uniform);
    }
    return true, "";
}
