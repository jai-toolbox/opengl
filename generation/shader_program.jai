#scope_file
Tbx_File :: #import "tbx/file";
#scope_export

Shader_Program_Jai_Bindings :: VGR.Shader_Programs.Shader_Program_Jai_Bindings;
Shader_Program_Attribute_Binding :: VGR.Shader_Programs.Shader_Program_Attribute_Binding;
Shader_Program_Uniform_Binding :: VGR.Shader_Programs.Shader_Program_Uniform_Binding;
shader_program_from_typed_metadata :: VGR.Shader_Programs.shader_program_from_typed_metadata;
shader_program_metadata_source :: VGR.Shader_Programs.shader_program_metadata_source;

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
                // Native bindings retain vector structs instead of legacy bone arrays.
                if attribute.data_type_of_component == GL_UNSIGNED_INT && attribute.components_per_vertex == 4 attribute.type_in_jai = Shader_UInt4;
                if attribute.data_type_of_component == GL_FLOAT && attribute.components_per_vertex == 4 attribute.type_in_jai = Vector4;
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
        if binding.type_name == "sampler1D" || binding.type_name == "sampler2D" || binding.type_name == "sampler3D" || binding.type_name == "sampler2DArray" {
            uniform.texture_target = cast(GLenum) (ifx binding.type_name == "sampler3D" then GL_TEXTURE_3D else GL_TEXTURE_2D);
            if binding.type_name == "sampler1D" uniform.texture_target = GL_TEXTURE_1D;
            if binding.type_name == "sampler2DArray" uniform.texture_target = GL_TEXTURE_2D_ARRAY;
            uniform.texture_unit = texture_unit;
            texture_unit += 1;
        }
        array_add(*shader.uniform_configs, uniform);
    }
    return true, "";
}
