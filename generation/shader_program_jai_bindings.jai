// Typed Jai bindings for the Jai -> GLSL + .program -> OpenGL renderer flow.
// Before writing .program, extract native vertex types, uniform types and field
// paths from Jai GPU rendering pipeline stage interfaces. shader_program.jai
// serializes this information in the descriptor's jai_bindings field.
// After reading .program, the renderer generator uses the helpers here to emit
// typed uniform setters and adapters from native vertex structs to attribute
// arrays. Renderer generation reads the saved descriptor and GLSL; it does not
// generate a renderer directly from the original Jai shader procedures.
SR :: #import "tbx/software_rasterizer";
Shader_Parser :: #import "tbx/parser";

GL_Uniform_Group :: struct {
    shader_name, jai_type_name, host_type_name: string;
    declarations: string;
}

generated_uniform_identifier :: (uniform: GL_Vertex_Uniform_Configuration) -> string {
    if uniform.identifier.count > 0 return uniform.identifier;
    return uniform.var_name_in_shader;
}

shader_metadata_from_typed_gpu_rendering_pipeline_stages :: (
    name: string, vertex: SR.GLSL_GPU_Rendering_Pipeline_Stage_Result, fragment: SR.GLSL_GPU_Rendering_Pipeline_Stage_Result,
    vertex_source_expression: string, fragment_source_expression: string,
    vertex_type: Type = void, program : Shader_Program_Metadata = .{}
) -> Shader_Metadata {
    native: *Type_Info;
    if vertex_type != void native=cast(*Type_Info)vertex_type;
    shader:=shader_metadata_from_gpu_rendering_pipeline_stage_type_info(name,vertex,fragment,vertex_source_expression,fragment_source_expression,native,program);
    return shader;
}

shader_metadata_from_gpu_rendering_pipeline_stage_type_info :: (
    name: string, vertex: SR.GLSL_GPU_Rendering_Pipeline_Stage_Result, fragment: SR.GLSL_GPU_Rendering_Pipeline_Stage_Result,
    vertex_source_expression: string, fragment_source_expression: string,
    vertex_info: *Type_Info, program : Shader_Program_Metadata = .{}
) -> Shader_Metadata {
    assert(vertex.success && fragment.success,"Invalid GPU rendering pipeline stages for renderer %: % / %",name,vertex.error,fragment.error);
    assert(vertex.gpu_rendering_pipeline_stage_interface.gpu_rendering_pipeline_stage == .VERTEX && fragment.gpu_rendering_pipeline_stage_interface.gpu_rendering_pipeline_stage == .FRAGMENT,
        "Renderer % requires vertex and fragment GPU rendering pipeline stages in that order",name);
    shader: Shader_Metadata;
    shader.name = name;
    shader.vertex_shader_supplies_geometry = program.vertex_shader_supplies_geometry;
    shader.vertex_count = program.vertex_count;
    shader.num_elements_in_each_buffer = program.num_elements_in_each_buffer;
    shader.per_object_transforms = program.per_object_transforms;
    shader.immediate_mode_support = program.immediate_mode_support;
    shader.num_elements_in_each_immediate_buffer = program.num_elements_in_each_immediate_buffer;
    shader.primitive_mode = program.primitive_mode;
    if vertex_info != null shader.native_vertex_type_name = (cast(*Type_Info_Struct) vertex_info).name;
    shader.vertex_source_expression = vertex_source_expression;
    shader.fragment_source_expression = fragment_source_expression;
    if vertex.gpu_rendering_pipeline_stage_interface.attributes.count > 0 {
        info := cast(*Type_Info_Struct) vertex_info;
        assert(info.type == .STRUCT,"Renderer % needs a native vertex struct",name);
        for attribute: vertex.gpu_rendering_pipeline_stage_interface.attributes {
            if program.per_object_transforms && attribute.shader_name == "local_to_world_index" continue;
            gl_type, ok := SR.glsl_type_name(attribute.value_type);
            assert(ok && gl_type != "mat4" && attribute.value_type.kind == .NAMED,
                "Unsupported native vertex attribute %.%",name,attribute.field);
            native_type := glsl_type_to_jai_type(gl_type);
            assert(native_type != void,"Unknown attribute type %",gl_type);
            member_type, offset, found := native_gpu_rendering_pipeline_stage_attribute_member_info(vertex_info,attribute.field);
            assert(found,"Vertex field %.% is missing",name,attribute.field);
            assert(member_type == cast(*Type_Info) native_type,
                "Vertex field %.% disagrees with the shader's %",name,attribute.field,gl_type);
            config := glsl_variable_to_vertex_attribute_configuration(.{type_name=gl_type,name=attribute.shader_name});
            config.native_field_path = attribute.field;
            array_add(*shader.attribute_configs,config);
        }
    } else assert(vertex_info == null,"Builtin-only GPU rendering pipeline stage must not have a vertex buffer");
    add_typed_uniform_group(*shader,vertex.gpu_rendering_pipeline_stage_interface);
    add_typed_uniform_group(*shader,fragment.gpu_rendering_pipeline_stage_interface);
    return shader;
}

// Follow physical using-field paths in native types, reporting their type and
// accumulated byte offset for callers that inspect the original vertex layout.
native_gpu_rendering_pipeline_stage_attribute_member :: (vertex_type: Type, path: string) -> (*Type_Info, s64, bool) {
    info, offset, found := native_gpu_rendering_pipeline_stage_attribute_member_info(cast(*Type_Info) vertex_type, path);
    return info, offset, found;
}

native_gpu_rendering_pipeline_stage_attribute_member_info :: (vertex_info: *Type_Info, path: string) -> (*Type_Info, s64, bool) {
    current := vertex_info;
    offset: s64;
    start: int;
    while start < path.count {
        end := start;
        while end < path.count && path[end] != #char "." end += 1;
        if current.type != .STRUCT return null,0,false;
        structure := cast(*Type_Info_Struct) current;
        found := false;
        for member: structure.members {
            if member.name != slice(path,start,end-start) continue;
            current = member.type;
            offset += member.offset_in_bytes;
            found = true;
            break;
        }
        if !found return null,0,false;
        start = end+1;
    }
    return current,offset,true;
}

typed_uniform_struct :: (host: SR.GLSL_GPU_Rendering_Pipeline_Stage_Interface, name: string) -> *Shader_Parser.Semantic_Struct {
    // Sampler CPU storage can be present in imported declarations. It remains
    // opaque to the GPU interface and must never generate a GLuint struct.
    if name == "Shader_Sampler_2D" || name == "Shader_Sampler_3D" return null;
    for *structure: host.structs if structure.name == name return structure;
    return null;
}

typed_uniform_has_sampler :: (host: SR.GLSL_GPU_Rendering_Pipeline_Stage_Interface, type: Shader_Parser.Resolved_Type) -> bool {
    if type.kind == .ARRAY return typed_uniform_has_sampler(host,type.pointee.*);
    if type.name == "Shader_Sampler_2D" || type.name == "Shader_Sampler_3D" return true;
    structure := typed_uniform_struct(host,type.name);
    if structure != null for field: structure.fields if typed_uniform_has_sampler(host,field.value_type) return true;
    return false;
}

// Preserve native uniform structs when possible. CPU sampler views become GL
// texture handles in generated binding structs, recursively through arrays and
// nested structs. Texture units are assigned by uniform declaration order.
typed_uniform_host_type :: (host: SR.GLSL_GPU_Rendering_Pipeline_Stage_Interface, type: Shader_Parser.Resolved_Type, prefix: string) -> string {
    if type.kind == .ARRAY return tprint("[%] %",type.array_count,typed_uniform_host_type(host,type.pointee.*,prefix));
    if type.name == "Shader_Sampler_2D" || type.name == "Shader_Sampler_3D" return "GLuint";
    if typed_uniform_has_sampler(host,type) return tprint("%_%_Bindings",prefix,type.name);
    return type.name;
}

add_typed_uniform_group :: (shader: *Shader_Metadata, host: SR.GLSL_GPU_Rendering_Pipeline_Stage_Interface) {
    if host.uniform_type.count == 0 return;
    group_index := -1;
    for group, index : shader.uniform_groups {
        if group.shader_name != host.uniform_name continue;
        assert(group.jai_type_name == host.uniform_type, "Uniform '%' has different GPU rendering pipeline stage types", host.uniform_name);
        group_index = index;
        break;
    }
    if group_index < 0 {
        root : Shader_Parser.Resolved_Type = .{kind = .NAMED, name = host.uniform_type};
        group : GL_Uniform_Group;
        group.shader_name = host.uniform_name;
        group.jai_type_name = host.uniform_type;
        group.host_type_name = typed_uniform_host_type(host, root, shader.name);
        builder : String_Builder;
        init_string_builder(*builder);
        emitted : [..] string;
        emit_uniform_binding_structs(*builder, host, root, shader.name, *emitted);
        array_free(emitted);
        group.declarations = builder_to_string(*builder);
        group_index = shader.uniform_groups.count;
        array_add(*shader.uniform_groups, group);
    }
    for uniform : host.uniforms {
        jai_path := "ctx";
        if uniform.field.count > 0 jai_path = tprint("ctx.%", uniform.field);
        flatten_typed_uniforms(shader, host, uniform.value_type, uniform.shader_name,
            jai_path, group_index);
    }
}

emit_uniform_binding_structs :: (builder: *String_Builder, host: SR.GLSL_GPU_Rendering_Pipeline_Stage_Interface,
                               type: Shader_Parser.Resolved_Type, prefix: string, emitted: *[..] string) {
    if type.kind == .ARRAY { emit_uniform_binding_structs(builder,host,type.pointee.*,prefix,emitted); return; }
    structure := typed_uniform_struct(host,type.name);
    if structure == null || !typed_uniform_has_sampler(host,type) return;
    for emitted.* if it == type.name return;
    array_add(emitted,type.name);
    for field: structure.fields emit_uniform_binding_structs(builder,host,field.value_type,prefix,emitted);
    print_to_builder(builder,"% :: struct {\n",typed_uniform_host_type(host,type,prefix));
    for field: structure.fields print_to_builder(builder,"    %: %;\n",field.name,typed_uniform_host_type(host,field.value_type,prefix));
    append(builder,"}\n\n");
}

flatten_typed_uniforms :: (shader: *Shader_Metadata, host: SR.GLSL_GPU_Rendering_Pipeline_Stage_Interface,
                          type: Shader_Parser.Resolved_Type, shader_path: string, jai_path: string, group_index: int) {
    if type.kind == .ARRAY {
        assert(type.array_count > 0 && type.pointee != null,"Uniform arrays must have a fixed positive length");
        for i: 0..type.array_count-1 flatten_typed_uniforms(shader,host,type.pointee.*,
            tprint("%[%]",shader_path,i),tprint("%[%]",jai_path,i),group_index);
        return;
    }
    structure := typed_uniform_struct(host,type.name);
    if structure != null && type.name != "Shader_Sampler_2D" && type.name != "Shader_Sampler_3D" {
        for field: structure.fields flatten_typed_uniforms(shader,host,field.value_type,
            tprint("%.%",shader_path,SR.glsl_field_name(field.name)),tprint("%.%",jai_path,field.name),group_index);
        return;
    }
    gl_type, ok := SR.glsl_type_name(type);
    native_type := glsl_type_to_jai_type(gl_type);
    assert(ok && native_type != void,"Unsupported uniform %: %",shader_path,type.name);
    for existing : shader.uniform_configs {
        if existing.var_name_in_shader != shader_path continue;
        assert(existing.group_index == group_index && existing.value_expression == jai_path && existing.type_in_jai == native_type,
            "Uniform '%' has conflicting GPU rendering pipeline stage bindings", shader_path);
        return;
    }
    uniform: GL_Vertex_Uniform_Configuration;
    uniform.type_in_jai = native_type;
    uniform.glsl_type_name = gl_type;
    uniform.var_name_in_shader = shader_path;
    uniform.identifier = tprint("typed_%",shader.uniform_configs.count);
    uniform.value_expression = jai_path;
    uniform.group_index = group_index;
    if gl_type == "sampler2D" || gl_type == "sampler3D" {
        uniform.texture_target = cast(GLenum) (ifx gl_type == "sampler3D" then GL_TEXTURE_3D else GL_TEXTURE_2D);
        for existing: shader.uniform_configs if existing.texture_target != 0 uniform.texture_unit += 1;
    }
    array_add(*shader.uniform_configs,uniform);
}

generate_uniform_group_declarations :: (shader: Shader_Metadata) -> string {
    builder: String_Builder;
    init_string_builder(*builder);
    for group: shader.uniform_groups append(*builder,group.declarations);
    return builder_to_string(*builder);
}

generate_uniform_group_setters :: (shader: Shader_Metadata) -> string {
    builder: String_Builder;
    init_string_builder(*builder);
    for group,i: shader.uniform_groups {
        print_to_builder(*builder,"set_uniforms :: (renderer: *%, ctx: %) {\n",get_renderer_struct_name(shader),group.host_type_name);
        append(*builder,"    gl_set_active_shader_program(renderer.shader_program_gl_handle);\n");
        for uniform: shader.uniform_configs {
            if uniform.group_index != i continue;
            location := tprint("renderer.%_uniform_location",generated_uniform_identifier(uniform));
            if uniform.texture_target != 0 {
                print_to_builder(*builder,"    gl_set_active_texture_unit(GL_TEXTURE0 + %);\n",uniform.texture_unit);
                target := ifx uniform.texture_target == GL_TEXTURE_3D then "GL_TEXTURE_3D" else "GL_TEXTURE_2D";
                print_to_builder(*builder,"    gl_bind_texture_to_binding_target_of_active_texture_unit(%,%);\n",target,uniform.value_expression);
                print_to_builder(*builder,"    gl_set_uniform_1i_on_active_shader_program(%,%);\n",location,uniform.texture_unit);
            } else {
                print_to_builder(*builder,"    %\n",generate_uniform_upload_call(uniform,location,uniform.value_expression));
            }
        }
        append(*builder,"    gl_set_active_texture_unit(GL_TEXTURE0);\n    gl_clear_active_shader_program();\n}\n\n");
    }
    return builder_to_string(*builder);
}

// The same settings are accepted by .program files and native-pipeline generation.
shader_renderer_metadata_valid :: (shader : Shader_Metadata) -> (bool, string) {
    if shader.vertex_shader_supplies_geometry {
        if shader.attribute_configs.count > 0 || shader.per_object_transforms
            return false, "vertex_shader_supplies_geometry requires a vertex shader with no vertex attributes";
        if shader.immediate_mode_support
            return false, "Shader-supplied geometry cannot use immediate-mode attribute buffers";
        if shader.vertex_count == 0 || shader.vertex_count > 0x7fffffff
            return false, "Shader-supplied geometry requires vertex_count between 1 and 2147483647";
    } else if shader.vertex_count != 0 {
        return false, "vertex_count requires vertex_shader_supplies_geometry";
    }
    if shader.native_vertex_type_name.count > 0 && shader.attribute_configs.count == 0
        return false, "A native vertex buffer requires vertex attributes";
    return true, "";
}

renderer_shader_source_expression :: (shader : Shader_Metadata, vertex : bool) -> string {
    source := ifx vertex then shader.vertex_source_expression else shader.fragment_source_expression;
    if source.count > 0 return source;
    path := ifx vertex then shader.vertex_shader_path else shader.fragment_shader_path;
    return generated_renderer_compile_time_shader_read_expression(path);
}

generate_shader_supplied_geometry_renderer_struct :: (shader : Shader_Metadata) -> string {
    return tprint("% :: struct {\n    shader_program_gl_handle : GLuint;\n    vertex_attribute_array_gl_handle : GLuint;\n%}\n\n",
        get_renderer_struct_name(shader), generate_code_for_cached_uniform_location_attributes(shader));
}

generate_shader_supplied_geometry_renderer_init :: (shader : Shader_Metadata) -> string {
    return tprint(#string END
init :: (using renderer : *%1) -> bool {
    success : bool;
    shader_program_gl_handle, success = create_shader_program(%2, %3);
    if !success return false;
    // OpenGL core profile requires a bound VAO even when the vertex shader uses
    // gl_VertexID and supplies every vertex itself. This VAO has no buffers.
    vertex_attribute_array_gl_handle = gl_create_vertex_array();
%4
    return true;
}

END, get_renderer_struct_name(shader), renderer_shader_source_expression(shader, true),
        renderer_shader_source_expression(shader, false), generate_code_for_caching_uniform_locations(shader));
}

generate_shader_supplied_geometry_render :: (shader : Shader_Metadata) -> string {
    return tprint(#string END
render :: (renderer : *%1, vertex_count : GLsizei = %3) {
    assert(vertex_count >= 0);
    gl_set_active_shader_program(renderer.shader_program_gl_handle);
    gl_bind_vertex_array(renderer.vertex_attribute_array_gl_handle);
    gl_draw_vertices_from_bound_vertex_array(%2, 0, vertex_count);
    gl_bind_vertex_array(0);
    gl_clear_active_shader_program();
}

END, get_renderer_struct_name(shader), gl_primitive_mode_to_string(shader.primitive_mode), shader.vertex_count);
}

generate_code_for_object_index_operations :: (shader : Shader_Metadata) -> string {
    name := get_renderer_struct_name(shader);
    result := tprint(#string END
// Indices are relative to this buffered object's first vertex.
update_object_indices :: (renderer : *%1, object_index : u32, indices : [] u32) -> bool {
    return update_object_indices(*renderer.psr, object_index, indices);
}

update_object_indices :: (renderer : *%1, renderable : $T/interface %2, indices : [] u32) -> bool {
    return update_object_indices(renderer, renderable.object_index, indices);
}

queue_render :: (renderer : *%1, object_index : u32) {
    queue_render(*renderer.psr, object_index);
}

END, name, get_renderable_struct_name(shader));
    if !shader.per_object_transforms result = tprint("%\nunbuffer_object :: (renderer : *%, object_index : u32) {\n    unbuffer_object(*renderer.psr, object_index);\n}\n\n", result, name);
    return result;
}

// Adapt native vertex structs to the existing retained renderer's attribute arrays.
// This runs only when buffering geometry; index updates do not touch these arrays.
generate_native_vertex_buffer_object :: (shader : Shader_Metadata) -> string {
    if shader.native_vertex_type_name.count == 0 return "";
    builder : String_Builder;
    init_string_builder(*builder);
    print_to_builder(*builder, "buffer_object :: (renderer : *%, vertices : [] %, indices : [] u32) -> (object_index : u32, success : bool) {\n",
        get_renderer_struct_name(shader), shader.native_vertex_type_name);
    for attribute : shader.attribute_configs {
        print_to_builder(*builder, "    % : [..] %;\n    defer array_free(%);\n",
            attribute.argument_name_in_buffer_object, attribute.type_in_jai, attribute.argument_name_in_buffer_object);
    }
    append(*builder, "    for vertex : vertices {\n");
    for attribute : shader.attribute_configs {
        print_to_builder(*builder, "        array_add(*%, vertex.%);\n", attribute.argument_name_in_buffer_object, attribute.native_field_path);
    }
    append(*builder, "    }\n    buffered_index, buffered := buffer_object(renderer, indices");
    for attribute : shader.attribute_configs print_to_builder(*builder, ", %", attribute.argument_name_in_buffer_object);
    append(*builder, ");\n    return buffered_index, buffered;\n}\n\n");
    return builder_to_string(*builder);
}
