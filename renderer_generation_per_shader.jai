#import "String";
#import "File";
#import "File_Utilities";
#import "tbx/section_logger";
#import "tbx/text";

// WARNING: This is a temporary renderer-generator assumption, not a general
// GLSL truth. Today every ivec4/uvec4 vertex attribute in the generated
// renderer path is used for skeletal bone indices, so four components maps to
// four bone influences. If another shader adds an unrelated ivec4/uvec4
// attribute, this hardcode will produce the wrong Jai buffer type until vector
// array types are represented generically.
BONE_INFLUENCES_PER_VERTEX :: 4;

Shader_Metadata :: struct { // call this Shader_Metadata?

    name : string;

    attribute_configs : [..] GL_Vertex_Attribute_Configuration;
    uniform_configs   : [..] GL_Vertex_Uniform_Configuration;

    per_object_transforms : bool;

    num_elements_in_each_buffer : u32;


    /*
     By default our shaders are in "retained mode", this is when you submit geometry to the GPU 
     and then we have a handle to that geometry. When we want to draw it, we use the handle to do so.
     The geometry persists on the GPU across frames until explicitly removed.

     On the other hand there is value to being able to render things on a per-frame basis without 
     the overhead of managing handles and GPU-side allocations. This is "immediate mode" geometry 
     is uploaded and drawn in one shot, with no expectation that it persists beyond the current frame.
     This is useful for debug visualization, gizmos, overlays, or any transient geometry that changes 
     every frame and would otherwise require constant re-buffering through the retained path.

     When immediate_mode_support is true, the renderer will allocate a separate set of GL buffers 
     dedicated to immediate draws, so that immediate and retained rendering can be freely interleaved 
     without interfering with each other.
    */
    immediate_mode_support : bool = false;
    num_elements_in_each_immediate_buffer: u32 = 65536;

    vertex_shader_path   : string;
    fragment_shader_path : string;


    primitive_mode : GLenum = GL_TRIANGLES;

}

Shader_Program_Metadata :: struct {
    name : string;

    per_object_transforms : bool;
    immediate_mode_support : bool = false;
    num_elements_in_each_buffer : u32 = 100000;
    num_elements_in_each_immediate_buffer: u32 = 65536;

    vertex_shader_path   : string;
    fragment_shader_path : string;

    primitive_mode : GLenum = GL_TRIANGLES;
}

gl_primitive_mode_to_string :: (mode: GLenum) -> string {
    if mode == {
        case GL_TRIANGLES;      return "GL_TRIANGLES";
        case GL_LINES;          return "GL_LINES";
        case GL_LINE_STRIP;     return "GL_LINE_STRIP";
        case GL_LINE_LOOP;      return "GL_LINE_LOOP";
        case GL_POINTS;         return "GL_POINTS";
        case GL_TRIANGLE_STRIP; return "GL_TRIANGLE_STRIP";
        case GL_TRIANGLE_FAN;   return "GL_TRIANGLE_FAN";
        case GL_PATCHES;        return "GL_PATCHES";
        case;                   return "GL_TRIANGLES"; // fallback
    }
}

gl_primitive_mode_from_string :: (value: string) -> GLenum {
    trimmed := trim(value);

    if trimmed == "GL_TRIANGLES" return GL_TRIANGLES;
    if trimmed == "GL_LINES" return GL_LINES;
    if trimmed == "GL_LINE_STRIP" return GL_LINE_STRIP;
    if trimmed == "GL_LINE_LOOP" return GL_LINE_LOOP;
    if trimmed == "GL_POINTS" return GL_POINTS;
    if trimmed == "GL_TRIANGLE_STRIP" return GL_TRIANGLE_STRIP;
    if trimmed == "GL_TRIANGLE_FAN" return GL_TRIANGLE_FAN;
    if trimmed == "GL_PATCHES" return GL_PATCHES;

    log("Unknown shader program primitive_mode '%'; using GL_TRIANGLES.", trimmed);
    return GL_TRIANGLES;
}

gl_enum_to_string :: (value: GLenum) -> string {
    if value == {
        case GL_FLOAT;        return "GL_FLOAT";
        case GL_INT;          return "GL_INT";
        case GL_UNSIGNED_INT; return "GL_UNSIGNED_INT";
        case;                 return tprint("cast(GLenum) %", cast(u32) value);
    }
}

gl_bool_to_string :: (value: GLboolean) -> string {
    if value == GL_TRUE return "GL_TRUE";
    return "GL_FALSE";
}

pointer_offset_to_string :: (value: *void) -> string {
    if value == null return "null";
    return tprint("cast(*void) %", cast(u64) value);
}

get_renderer_struct_name :: (shader : Shader_Metadata) -> string {
    return tprint("%1_Renderer", shader.name);
}

get_renderable_struct_name :: (shader : Shader_Metadata) -> string {
    return tprint("%1_Renderable", shader.name);
}

GLSL_Shader_Variable :: struct {
    type_name : string;
    name : string;
}

glsl_split_by_newline :: (s: string) -> (line: string, remainder: string) {
    for i: 0..s.count-1 {
        if s[i] == #char "\n" {
            return slice(s, 0, i), advance(s, i + 1);
        }
    }

    return s, "";
}

glsl_remove_line_comment :: (line: string) -> string {
    comment := find_index_from_left(line, "//");
    if comment < 0 return line;
    return slice(line, 0, comment);
}

glsl_remove_layout_prefix :: (line: string) -> string {
    working := trim(line);
    if !starts_with(working, "layout") return working;

    for i: 0..working.count-1 {
        if working[i] == #char ")" {
            return trim(advance(working, i + 1));
        }
    }

    return working;
}

glsl_next_token :: (line: *string) -> (token: string, ok: bool) {
    line.* = trim(line.*);
    if line.*.count == 0 return "", false;

    end := line.*.count;
    for i: 0..line.*.count-1 {
        c := line.*[i];
        if c == #char " " || c == #char "\t" || c == #char "\r" || c == #char "\n" {
            end = i;
            break;
        }
    }

    result := slice(line.*, 0, end);
    if end >= line.*.count {
        line.* = "";
    } else {
        line.* = advance(line.*, end + 1);
    }

    return result, true;
}

glsl_clean_identifier_token :: (token: string) -> string {
    end := token.count;
    for i: 0..token.count-1 {
        c := token[i];
        if c == #char ";" || c == #char "," || c == #char "[" || c == #char "=" || c == #char "{" {
            end = i;
            break;
        }
    }

    return slice(token, 0, end);
}

glsl_parse_declaration_line :: (line: string, qualifier: string) -> (variable: GLSL_Shader_Variable, ok: bool) {
    working := glsl_remove_layout_prefix(glsl_remove_line_comment(line));
    first, ok_first := glsl_next_token(*working);
    if !ok_first || first != qualifier return .{}, false;

    type_name, ok_type := glsl_next_token(*working);
    if !ok_type return .{}, false;

    raw_name, ok_name := glsl_next_token(*working);
    if !ok_name return .{}, false;

    name := glsl_clean_identifier_token(raw_name);
    if name.count == 0 return .{}, false;
    if name == "{" return .{}, false;

    return .{ type_name = type_name, name = name }, true;
}

glsl_variable_list_contains_name :: (variables: [] GLSL_Shader_Variable, name: string) -> bool {
    for variables {
        if it.name == name return true;
    }

    return false;
}

glsl_collect_declarations :: (source: string, qualifier: string) -> [..] GLSL_Shader_Variable {
    variables: [..] GLSL_Shader_Variable;

    remainder := source;
    brace_depth := 0;
    while remainder.count > 0 {
        line: string;
        line, remainder = glsl_split_by_newline(remainder);

        if brace_depth == 0 {
            variable, ok := glsl_parse_declaration_line(line, qualifier);
            if ok && !glsl_variable_list_contains_name(variables, variable.name) {
                array_add(*variables, variable);
            }
        }

        for i: 0..line.count-1 {
            if line[i] == #char "{" brace_depth += 1;
            if line[i] == #char "}" && brace_depth > 0 brace_depth -= 1;
        }
    }

    return variables;
}

glsl_type_to_jai_type :: (type_name: string) -> Type {
    if type_name == "float" return float32;
    if type_name == "int" return s32;
    if type_name == "uint" return u32;
    if type_name == "bool" return bool;
    if type_name == "sampler1D" return s32;
    if type_name == "sampler2D" return s32;
    if type_name == "sampler2DArray" return s32;
    if type_name == "usampler2D" return s32;
    if type_name == "samplerCube" return s32;
    if type_name == "vec2" return Vector2;
    if type_name == "vec3" return Vector3;
    if type_name == "vec4" return Vector4;

    // BIG WARNING: This is deliberately incorrect as a general GLSL mapping.
    // ivec4/uvec4 should not inherently mean "bone influence array"; it only
    // works for the current shaders because the only ivec4/uvec4 vertex
    // attributes we generate are bone_transform_indices. The first shader that
    // uses ivec4/uvec4 for anything else must replace this with a real fixed
    // vector/array type mapping.
    if type_name == "ivec4" return [BONE_INFLUENCES_PER_VERTEX] u32;
    if type_name == "uvec4" return [BONE_INFLUENCES_PER_VERTEX] u32;

    if type_name == "mat3" return Matrix3;
    if type_name == "mat4" return Matrix4;

    return void;
}

glsl_components_per_vertex :: (type_name: string) -> GLint {
    if type_name == "vec2" return 2;
    if type_name == "vec3" return 3;
    if type_name == "vec4" return 4;
    if type_name == "ivec4" return 4;
    if type_name == "uvec4" return 4;
    if type_name == "mat3" return 9;
    if type_name == "mat4" return 16;

    return 1;
}

glsl_component_type :: (type_name: string) -> GLenum {
    if type_name == "int" return GL_INT;
    if type_name == "uint" return GL_UNSIGNED_INT;
    if type_name == "ivec4" return GL_INT;
    if type_name == "uvec4" return GL_UNSIGNED_INT;

    return GL_FLOAT;
}

legacy_shader_program_path :: (program: Shader_Program_Metadata) -> bool {
    return starts_with(program.vertex_shader_path, "data/shaders/out/")
        || starts_with(program.fragment_shader_path, "data/shaders/out/");
}

legacy_shader_uniform_is_allowed :: (name: string) -> bool {
    if name == "world_to_camera" return true;
    if name == "camera_to_clip" return true;
    if name == "transform" return true;
    if name == "rgb_color" return true;
    if name == "rgba_color" return true;
    if name == "grid_size" return true;
    if name == "grid_plane" return true;
    if name == "point_size" return true;
    if name == "border_thickness" return true;
    if name == "aspect_ratio" return true;
    if name == "packed_textures" return true;
    if name == "packed_texture_bounding_boxes" return true;
    if name == "object_id_texture" return true;
    if name == "selected_object_id" return true;
    if name == "thickness_px" return true;
    if name == "position_texture" return true;
    if name == "color_texture" return true;
    if name == "normal_texture" return true;
    if name == "texture_sampler" return true;
    if name == "camera_position" return true;
    if name == "num_active_lights" return true;
    if name == "default_base_color" return true;
    if name == "default_metallic" return true;
    if name == "default_roughness" return true;
    if name == "default_ambient_occlusion" return true;
    if name == "reflection_cubemap" return true;
    if name == "use_reflection_cubemap" return true;
    if name == "reflection_strength" return true;

    return false;
}

glsl_strip_passthrough_prefix :: (name: string) -> string {
    prefix := "passthrough_";
    if starts_with(name, prefix) return advance(name, prefix.count);
    return name;
}

glsl_argument_name_for_vertex_attribute :: (name: string) -> string {
    base_name := glsl_strip_passthrough_prefix(name);

    if starts_with(base_name, "packed_texture_index") return base_name;
    if starts_with(base_name, "packed_texture_bounding_box_index") return base_name;
    if starts_with(base_name, "texture_coordinate_") {
        suffix := advance(base_name, "texture_coordinate".count);
        return tprint("texture_coordinates%", suffix);
    }

    return pluralize_identifier(base_name);
}

glsl_plural_name_for_vertex_attribute :: (name: string) -> string {
    if starts_with(name, "passthrough_texture_coordinate_") {
        suffix := advance(name, "passthrough_texture_coordinate".count);
        return tprint("passthrough_texture_coordinates%", suffix);
    }

    if starts_with(name, "passthrough_packed_texture_bounding_box_index_") {
        suffix := advance(name, "passthrough_packed_texture_bounding_box_index".count);
        return tprint("passthrough_packed_texture_bounding_box_indices%", suffix);
    }

    if starts_with(name, "passthrough_packed_texture_index_") {
        suffix := advance(name, "passthrough_packed_texture_index".count);
        return tprint("passthrough_packed_texture_indices%", suffix);
    }

    index_for := find_index_from_left(name, "_index_for_");
    if index_for >= 0 {
        prefix := slice(name, 0, index_for);
        suffix := advance(name, index_for + "_index".count);
        return tprint("%_indices%", prefix, suffix);
    }

    return pluralize_identifier(name);
}

glsl_variable_to_vertex_attribute_configuration :: (variable: GLSL_Shader_Variable) -> GL_Vertex_Attribute_Configuration {
    type_in_jai := glsl_type_to_jai_type(variable.type_name);
    components := glsl_components_per_vertex(variable.type_name);

    if variable.name == "passthrough_tangent" {
        type_in_jai = Vector4;
        components = 4;
    }

    // BIG WARNING: Name-based shader metadata inference. This is intentionally
    // narrow and only correct for skeletal animation shaders where bone_weights
    // has exactly BONE_INFLUENCES_PER_VERTEX components. If a shader uses the
    // same name for different data, or supports a different influence count,
    // this must become a real declaration/annotation-driven rule.
    if variable.name == "bone_weights" type_in_jai = [BONE_INFLUENCES_PER_VERTEX] float32;

    return .{
        type_in_jai = type_in_jai,
        var_name_in_shader = variable.name,
        plural_name = glsl_plural_name_for_vertex_attribute(variable.name),
        argument_name_in_buffer_object = glsl_argument_name_for_vertex_attribute(variable.name),
        constant_across_object = false,
        components_per_vertex = components,
        data_type_of_component = glsl_component_type(variable.type_name),
        normalize = GL_FALSE,
        stride = 0,
        pointer_offset_to_start_of_data = null,
        passthrough = starts_with(variable.name, "passthrough_"),
    };
}

glsl_variable_to_uniform_configuration :: (variable: GLSL_Shader_Variable) -> GL_Vertex_Uniform_Configuration {
    return .{
        type_in_jai = glsl_type_to_jai_type(variable.type_name),
        var_name_in_shader = variable.name,
    };
}

shader_program_add_attribute_config_if_missing :: (attributes: *[..] GL_Vertex_Attribute_Configuration, attribute: GL_Vertex_Attribute_Configuration) {
    for attributes.* {
        if it.var_name_in_shader == attribute.var_name_in_shader return;
    }

    array_add(attributes, attribute);
}

shader_program_add_uniform_config_if_missing :: (uniforms: *[..] GL_Vertex_Uniform_Configuration, uniform: GL_Vertex_Uniform_Configuration) {
    for uniforms.* {
        if it.var_name_in_shader == uniform.var_name_in_shader return;
    }

    array_add(uniforms, uniform);
}

legacy_attribute_rank :: (program: Shader_Program_Metadata, name: string) -> s32 {
    if name == "position" return 10;
    if name == "normal" return 20;
    if name == "passthrough_rgb_color" return 30;
    if name == "bone_transform_indices" return 40;
    if name == "bone_weights" return 50;
    if name == "passthrough_rgba_color" return 60;
    if name == "passthrough_normal" return 70;
    if name == "passthrough_tangent" return 80;
    if name == "passthrough_object_id" return 90;

    if program.name == "Camera_Per_Object_Transforms_Packed_Texture" {
        if name == "passthrough_packed_texture_index" return 100;
        if name == "passthrough_texture_coordinate" return 110;
        if name == "passthrough_packed_texture_bounding_box_index" return 120;
    }

    if program.name == "Camera_Per_Object_Transform_Packed_Texture_2_Channel" {
        if name == "passthrough_texture_coordinate_0" return 100;
        if name == "passthrough_packed_texture_index_0" return 110;
        if name == "passthrough_packed_texture_bounding_box_index_0" return 120;
        if name == "passthrough_texture_coordinate_1" return 130;
        if name == "passthrough_packed_texture_index_1" return 140;
        if name == "passthrough_packed_texture_bounding_box_index_1" return 150;
    }

    if name == "passthrough_texture_coordinate" return 100;
    if name == "passthrough_texture_coordinate_0" return 101;
    if name == "passthrough_texture_coordinate_1" return 102;
    if name == "passthrough_base_color_factor" return 110;
    if name == "passthrough_material_parameters" return 120;
    if name == "passthrough_glass_parameters" return 130;
    if name == "passthrough_volume_parameters" return 140;
    if name == "passthrough_alpha_parameters" return 150;
    if name == "passthrough_packed_texture_index" return 160;
    if name == "passthrough_packed_texture_bounding_box_index" return 170;
    if name == "passthrough_packed_texture_index_0" return 180;
    if name == "passthrough_packed_texture_bounding_box_index_0" return 190;
    if name == "passthrough_packed_texture_index_1" return 200;
    if name == "passthrough_packed_texture_bounding_box_index_1" return 210;
    if name == "passthrough_packed_texture_index_for_base_color" return 220;
    if name == "passthrough_packed_texture_bounding_box_index_for_base_color" return 230;
    if name == "passthrough_packed_texture_index_for_normal" return 240;
    if name == "passthrough_packed_texture_bounding_box_index_for_normal" return 250;
    if name == "passthrough_packed_texture_index_for_metallic_roughness" return 260;
    if name == "passthrough_packed_texture_bounding_box_index_for_metallic_roughness" return 270;
    if name == "passthrough_packed_texture_index_for_ambient_occlusion" return 280;
    if name == "passthrough_packed_texture_bounding_box_index_for_ambient_occlusion" return 290;

    return 10000;
}

legacy_uniform_rank :: (program: Shader_Program_Metadata, name: string) -> s32 {
    if program.name == "Camera_Per_Object_Transform_Normal_Border" {
        if name == "camera_to_clip" return 10;
        if name == "world_to_camera" return 20;
        if name == "border_thickness" return 30;
        if name == "rgb_color" return 40;
    }

    if program.name == "Object_Id_Selection_Outline" {
        if name == "object_id_texture" return 10;
        if name == "selected_object_id" return 20;
        if name == "rgba_color" return 30;
        if name == "thickness_px" return 40;
    }

    if name == "camera_to_clip" return 10;
    if name == "world_to_camera" return 20;
    if name == "transform" return 30;
    if name == "camera_position" return 40;
    if name == "packed_textures" return 50;
    if name == "packed_texture_bounding_boxes" return 60;
    if name == "num_active_lights" return 70;
    if name == "default_base_color" return 80;
    if name == "default_metallic" return 90;
    if name == "default_roughness" return 100;
    if name == "default_ambient_occlusion" return 110;
    if name == "reflection_cubemap" return 120;
    if name == "use_reflection_cubemap" return 130;
    if name == "reflection_strength" return 140;
    if name == "aspect_ratio" return 150;
    if name == "position_texture" return 160;
    if name == "color_texture" return 170;
    if name == "normal_texture" return 180;
    if name == "texture_sampler" return 190;
    if name == "rgba_color" return 200;
    if name == "rgb_color" return 210;
    if name == "object_id_texture" return 220;
    if name == "selected_object_id" return 230;
    if name == "thickness_px" return 240;
    if name == "point_size" return 250;
    if name == "border_thickness" return 260;
    if name == "grid_size" return 270;
    if name == "grid_plane" return 280;

    return 10000;
}

sort_legacy_attribute_configs :: (program: Shader_Program_Metadata, attributes: *[..] GL_Vertex_Attribute_Configuration) {
    for i: 1..attributes.count-1 {
        j := i;
        while j > 0 && legacy_attribute_rank(program, attributes.*[j].var_name_in_shader) < legacy_attribute_rank(program, attributes.*[j - 1].var_name_in_shader) {
            tmp := attributes.*[j - 1];
            attributes.*[j - 1] = attributes.*[j];
            attributes.*[j] = tmp;
            j -= 1;
        }
    }
}

sort_legacy_uniform_configs :: (program: Shader_Program_Metadata, uniforms: *[..] GL_Vertex_Uniform_Configuration) {
    for i: 1..uniforms.count-1 {
        j := i;
        while j > 0 && legacy_uniform_rank(program, uniforms.*[j].var_name_in_shader) < legacy_uniform_rank(program, uniforms.*[j - 1].var_name_in_shader) {
            tmp := uniforms.*[j - 1];
            uniforms.*[j - 1] = uniforms.*[j];
            uniforms.*[j] = tmp;
            j -= 1;
        }
    }
}

legacy_add_pbr_extra_attributes :: (program: Shader_Program_Metadata, attributes: *[..] GL_Vertex_Attribute_Configuration) {
    if program.name != "Camera_Per_Object_Transform_Pbr_Packed_Texture" return;

    shader_program_add_attribute_config_if_missing(attributes, glsl_variable_to_vertex_attribute_configuration(.{type_name = "vec4", name = "passthrough_material_parameters"}));
    shader_program_add_attribute_config_if_missing(attributes, glsl_variable_to_vertex_attribute_configuration(.{type_name = "vec4", name = "passthrough_glass_parameters"}));
    shader_program_add_attribute_config_if_missing(attributes, glsl_variable_to_vertex_attribute_configuration(.{type_name = "vec4", name = "passthrough_volume_parameters"}));
}

legacy_shader_program_skips_uniform :: (program: Shader_Program_Metadata, name: string) -> bool {
    if program.name == "Camera_Per_Object_Transform_Deferred_Lighting_Compute_Light_Pass" && name == "camera_position" return true;
    return false;
}

shader_source_uses_local_to_world_matrices :: (source: string) -> bool {
    has_block := find_index_from_left(source, "uniform LtwMatrices") >= 0;
    has_matrix_array := find_index_from_left(source, "local_to_world_matrices") >= 0;
    has_index_attribute := find_index_from_left(source, "local_to_world_index") >= 0;
    return has_block && has_matrix_array && has_index_attribute;
}

shader_program_path_to_file_stem :: (path: string) -> string {
    start := 0;
    for i: 0..path.count-1 {
        if path[i] == #char "/" || path[i] == #char "\\" start = i + 1;
    }

    filename := slice(path, start, path.count - start);
    if ends_with(filename, ".program") return slice(filename, 0, filename.count - ".program".count);
    return filename;
}

shader_program_identifier_char :: (c: u8) -> bool {
    if c >= #char "a" && c <= #char "z" return true;
    if c >= #char "A" && c <= #char "Z" return true;
    if c >= #char "0" && c <= #char "9" return true;
    if c == #char "_" return true;
    return false;
}

shader_program_append_pascal_word :: (builder: *String_Builder, word: string) {
    if word.count == 0 return;

    if word == "msdf" {
        append(builder, "MSDF");
        return;
    }

    for i: 0..word.count-1 {
        c := word[i];
        if i == 0 c = to_upper(c);
        append(builder, c);
    }
}

shader_program_name_from_path :: (program_path: string) -> string {
    stem := shader_program_path_to_file_stem(program_path);

    builder: String_Builder;
    init_string_builder(*builder);

    word_start := 0;
    appended_word := false;
    for i: 0..stem.count-1 {
        if stem[i] == #char "_" {
            if appended_word append(*builder, "_");
            shader_program_append_pascal_word(*builder, slice(stem, word_start, i - word_start));
            appended_word = true;
            word_start = i + 1;
        }
    }

    if appended_word append(*builder, "_");
    shader_program_append_pascal_word(*builder, slice(stem, word_start, stem.count - word_start));

    return builder_to_string(*builder);
}

shader_program_parse_bool :: (value: string) -> (parsed: bool, ok: bool) {
    trimmed := trim(value);
    if trimmed == "true" return true, true;
    if trimmed == "false" return false, true;
    return false, false;
}

shader_program_parse_u32 :: (value: string) -> (parsed: u32, ok: bool) {
    trimmed := trim(value);
    if trimmed.count == 0 return 0, false;

    result: u32 = 0;
    for i: 0..trimmed.count-1 {
        c := trimmed[i];
        if c < #char "0" || c > #char "9" return 0, false;
        result = result * 10 + cast(u32) (c - #char "0");
    }

    return result, true;
}

shader_program_metadata_field_value :: (source: string, field_name: string) -> (value: string, found: bool) {
    remainder := source;
    while remainder.count > 0 {
        field_index := find_index_from_left(remainder, field_name);
        if field_index < 0 return "", false;

        before_ok := field_index == 0 || !shader_program_identifier_char(remainder[field_index - 1]);
        after_index := field_index + field_name.count;
        after_ok := after_index >= remainder.count || !shader_program_identifier_char(remainder[after_index]);
        if !before_ok || !after_ok {
            remainder = advance(remainder, after_index);
            continue;
        }

        working := trim(advance(remainder, after_index));
        if working.count == 0 || working[0] != #char "=" {
            remainder = advance(remainder, after_index);
            continue;
        }

        working = trim(advance(working, 1));
        if working.count == 0 return "", false;

        if working[0] == #char "\"" {
            for i: 1..working.count-1 {
                if working[i] == #char "\"" return slice(working, 1, i - 1), true;
            }

            return "", false;
        }

        end := working.count;
        for i: 0..working.count-1 {
            c := working[i];
            if c == #char "," || c == #char "\n" || c == #char "\r" || c == #char "}" {
                end = i;
                break;
            }
        }

        return trim(slice(working, 0, end)), true;
    }

    return "", false;
}

read_shader_program_metadata_file :: (program_path: string) -> (program: Shader_Program_Metadata, ok: bool) {
    source, read_ok := read_entire_file(program_path);
    if !read_ok {
        log_error("Failed to read shader program file: %", program_path);
        return .{}, false;
    }

    result := Shader_Program_Metadata.{
        name = shader_program_name_from_path(program_path),
    };

    value: string;
    found: bool;

    value, found = shader_program_metadata_field_value(source, "vertex_shader_path");
    if !found {
        log_error("Shader program % is missing vertex_shader_path.", program_path);
        return .{}, false;
    }
    result.vertex_shader_path = value;

    value, found = shader_program_metadata_field_value(source, "fragment_shader_path");
    if !found {
        log_error("Shader program % is missing fragment_shader_path.", program_path);
        return .{}, false;
    }
    result.fragment_shader_path = value;

    value, found = shader_program_metadata_field_value(source, "per_object_transforms");
    if found {
        parsed, parse_ok := shader_program_parse_bool(value);
        if !parse_ok {
            log_error("Shader program % has invalid per_object_transforms value: %", program_path, value);
            return .{}, false;
        }
        result.per_object_transforms = parsed;
    }

    value, found = shader_program_metadata_field_value(source, "immediate_mode_support");
    if found {
        parsed, parse_ok := shader_program_parse_bool(value);
        if !parse_ok {
            log_error("Shader program % has invalid immediate_mode_support value: %", program_path, value);
            return .{}, false;
        }
        result.immediate_mode_support = parsed;
    }

    value, found = shader_program_metadata_field_value(source, "num_elements_in_each_buffer");
    if found {
        parsed, parse_ok := shader_program_parse_u32(value);
        if !parse_ok {
            log_error("Shader program % has invalid num_elements_in_each_buffer value: %", program_path, value);
            return .{}, false;
        }
        result.num_elements_in_each_buffer = parsed;
    }

    value, found = shader_program_metadata_field_value(source, "num_elements_in_each_immediate_buffer");
    if found {
        parsed, parse_ok := shader_program_parse_u32(value);
        if !parse_ok {
            log_error("Shader program % has invalid num_elements_in_each_immediate_buffer value: %", program_path, value);
            return .{}, false;
        }
        result.num_elements_in_each_immediate_buffer = parsed;
    }

    value, found = shader_program_metadata_field_value(source, "primitive_mode");
    if found result.primitive_mode = gl_primitive_mode_from_string(value);

    return result, true;
}

shader_program_generation_visitor :: (info: *File_Visit_Info, _: *void) {
    if !ends_with(info.full_name, ".program") return;

    program_path := tprint("data/shaders/programs/%", shader_program_path_to_file_stem(info.full_name));
    program_path = tprint("%.program", program_path);

    program, ok := read_shader_program_metadata_file(program_path);
    if !ok return;

    create_code_to_render_stuff_with_shader_from_program(program_path, program);
}

create_code_to_render_stuff_with_shader_program_files :: (program_directory: string = "data/shaders/programs") {
    visit_files(program_directory, recursive = false, null, shader_program_generation_visitor, visit_directories = false);
}

create_code_to_render_stuff_with_shader_from_program :: (program_path: string, program: Shader_Program_Metadata) {
    vertex_source, vertex_ok := read_entire_file(program.vertex_shader_path);
    if !vertex_ok {
        log_error("Failed to read vertex shader for program %: %", program_path, program.vertex_shader_path);
        return;
    }

    fragment_source, fragment_ok := read_entire_file(program.fragment_shader_path);
    if !fragment_ok {
        log_error("Failed to read fragment shader for program %: %", program_path, program.fragment_shader_path);
        return;
    }

    attributes: [..] GL_Vertex_Attribute_Configuration;
    uniforms: [..] GL_Vertex_Uniform_Configuration;
    per_object_transforms := program.per_object_transforms || shader_source_uses_local_to_world_matrices(vertex_source);

    vertex_inputs := glsl_collect_declarations(vertex_source, "in");
    for vertex_inputs {
        if per_object_transforms && it.name == "local_to_world_index" continue;

        config := glsl_variable_to_vertex_attribute_configuration(it);
        shader_program_add_attribute_config_if_missing(*attributes, config);
    }
    if legacy_shader_program_path(program) {
        legacy_add_pbr_extra_attributes(program, *attributes);
        sort_legacy_attribute_configs(program, *attributes);
    }

    vertex_uniforms := glsl_collect_declarations(vertex_source, "uniform");
    for vertex_uniforms {
        if legacy_shader_program_path(program) && !legacy_shader_uniform_is_allowed(it.name) continue;
        if legacy_shader_program_path(program) && legacy_shader_program_skips_uniform(program, it.name) continue;

        config := glsl_variable_to_uniform_configuration(it);
        shader_program_add_uniform_config_if_missing(*uniforms, config);
    }

    fragment_uniforms := glsl_collect_declarations(fragment_source, "uniform");
    for fragment_uniforms {
        if legacy_shader_program_path(program) && !legacy_shader_uniform_is_allowed(it.name) continue;
        if legacy_shader_program_path(program) && legacy_shader_program_skips_uniform(program, it.name) continue;

        config := glsl_variable_to_uniform_configuration(it);
        shader_program_add_uniform_config_if_missing(*uniforms, config);
    }
    if legacy_shader_program_path(program) sort_legacy_uniform_configs(program, *uniforms);

    shader := Shader_Metadata.{
        name = program.name,
        attribute_configs = attributes,
        uniform_configs = uniforms,
        per_object_transforms = per_object_transforms,
        num_elements_in_each_buffer = program.num_elements_in_each_buffer,
        immediate_mode_support = program.immediate_mode_support,
        num_elements_in_each_immediate_buffer = program.num_elements_in_each_immediate_buffer,
        vertex_shader_path = program.vertex_shader_path,
        fragment_shader_path = program.fragment_shader_path,
        primitive_mode = program.primitive_mode,
    };

    create_code_to_render_stuff_with_shader(shader);
}

shader_attribute_configurations :: (shader: Shader_Metadata) -> [..] GL_Vertex_Attribute_Configuration {
    result: [..] GL_Vertex_Attribute_Configuration;

    for shader.attribute_configs array_add(*result, it);

    return result;
}

shader_uniform_configurations :: (shader: Shader_Metadata) -> [..] GL_Vertex_Uniform_Configuration {
    result: [..] GL_Vertex_Uniform_Configuration;

    for shader.uniform_configs array_add(*result, it);

    return result;
}

is_disabled_generated_vertex_attribute :: (attr: GL_Vertex_Attribute_Configuration) -> bool {
    return attr.var_name_in_shader == "passthrough_packed_texture_index_for_ambient_occlusion"
        || attr.var_name_in_shader == "passthrough_packed_texture_bounding_box_index_for_ambient_occlusion";
}

create_code_to_render_stuff_with_shader :: (shader: Shader_Metadata) {
    push_allocator(temp);

    builder: String_Builder;
    init_string_builder(*builder);

    print_to_builder(*builder, "// auto-generated renderer for shader: %\n", shader.name);
    print_to_builder(*builder, "// do not edit manually.\n\n");

    attribute_configs := shader_attribute_configurations(shader);
    has_attributes := attribute_configs.count > 0;

    if has_attributes {
        append(*builder, generate_renderable_struct_for_given_shader(shader));
        append(*builder, generate_code_for_constructing_renderable_from_generic_geometry_type(shader));
        append(*builder, generate_code_for_deinit_renderable(shader));
        append(*builder, generate_code_for_unbuffer_renderable(shader));
        append(*builder, generate_code_for_queue_render_from_renderable(shader));
        if shader.per_object_transforms append(*builder, generate_code_for_set_local_to_world_matrix(shader));
    }

    append(*builder, generate_renderer_struct_for_given_shader(shader));
    append(*builder, generate_code_for_uniform_setter_functions(shader));
    append(*builder, generate_code_for_init(shader));
    append(*builder, generate_code_for_deinit_renderer(shader));

    if has_attributes {
        append(*builder, generate_init_buffers_no_data(shader));
        append(*builder, generate_init_immediate_buffers(shader));       
        append(*builder, generate_code_for_buffer_object_from_renderable(shader));
        append(*builder, generate_buffer_object(shader));
        append(*builder, generate_rebuffer_object(shader));
        append(*builder, generate_render(shader));
        append(*builder, generate_immediate_render(shader));            
    }

    output := builder_to_string(*builder);

    renderers_dir := tprint("%/renderers", #filepath);
    make_directory_if_it_does_not_exist(renderers_dir);

    filename := tprint("%/%_renderer.jai", renderers_dir, to_lower_copy(shader.name));

    success := write_entire_file(filename, output);
    if !success {
        log_error("Failed to write generated file: %", filename);
    } 
}

jai_struct_attributes_for_gl_vertex_attribute_handles :: (attributes: [] GL_Vertex_Attribute_Configuration) -> string {
    push_allocator(temp); // everything in this function is temp storage, yay!

    builder: String_Builder;
    init_string_builder(*builder); 

    for attributes {
        print_to_builder(*builder, "    %_buffer_gl_handle: GLuint;\n", it.plural_name);
    }

    return builder_to_string(*builder);
}

generate_code_for_per_object_transform_attributes :: (s : Shader_Metadata) -> string {
    if !s.per_object_transforms return "";

    return #string END 

    using #as ltw_pool : Local_To_World_Matrix_Pool;

    local_to_world_index_buffer_gl_handle : GLuint;

    END;
}

generate_code_for_cached_uniform_location_attributes :: (shader: Shader_Metadata) -> string {
    push_allocator(temp);
    builder: String_Builder;
    init_string_builder(*builder);

    uniforms := shader_uniform_configurations(shader);
    for uniforms {
        print_to_builder(*builder, "    %_uniform_location : GLint = -1;\n", 
            it.var_name_in_shader);
    }

    return builder_to_string(*builder);
}

generate_code_for_immediate_mode_attributes :: (s : Shader_Metadata) -> string {
    if !s.immediate_mode_support return "";

    push_allocator(temp);
    builder: String_Builder;
    init_string_builder(*builder);

    print_to_builder(*builder, "\n    // immediate-mode buffers\n");
    print_to_builder(*builder, "    immediate_vertex_attribute_array_gl_handle: GLuint;\n");
    print_to_builder(*builder, "    immediate_index_buffer_gl_handle: GLuint;\n");
    if s.per_object_transforms {
        print_to_builder(*builder, "    immediate_local_to_world_index_buffer_gl_handle : GLuint;\n");
    }

    attributes := shader_attribute_configurations(s);
    for attributes {
        print_to_builder(*builder, "    immediate_%_buffer_gl_handle: GLuint;\n", it.plural_name);
    }

    return builder_to_string(*builder);
}

generate_renderer_struct_for_given_shader :: (s : Shader_Metadata) -> string {
    return tprint(#string END

%1 :: struct {
    using #as psr : Per_Shader_Renderer;

%2
%3
%4
%5
}

    END, get_renderer_struct_name(s), 
         generate_code_for_per_object_transform_attributes(s), 
         generate_code_for_cached_uniform_location_attributes(s),    
         jai_struct_attributes_for_gl_vertex_attribute_handles(shader_attribute_configurations(s)),
         generate_code_for_immediate_mode_attributes(s));
}

generate_renderable_struct_attributes :: (shader : Shader_Metadata) -> string {
    push_allocator(temp); 

    builder: String_Builder;
    init_string_builder(*builder); 

    if shader.per_object_transforms print_to_builder(*builder, "    local_to_world_index : u32;\n\n");

    attributes := shader_attribute_configurations(shader);
    for attributes {
        print_to_builder(*builder, "    %: [..] %;\n", it.argument_name_in_buffer_object, it.type_in_jai);
    }

    return builder_to_string(*builder);
}

generate_renderable_struct_for_given_shader :: (s : Shader_Metadata) -> string {

    return tprint(#string END

%1 :: struct {
    indices : [..] u32;
    object_index : u32;

%2
}

    END, get_renderable_struct_name(s), generate_renderable_struct_attributes(s));
}

generate_code_for_constructing_renderable_from_generic_geometry_type :: (shader: Shader_Metadata) -> string {
    push_allocator(temp);

    geometry_struct_name := tprint("%1_Geometry", shader.name);

    geometry_fields: String_Builder;
    init_string_builder(*geometry_fields);
    print_to_builder(*geometry_fields, "    indices : [..] u32;\n");
    attributes := shader_attribute_configurations(shader);
    for attributes {
        print_to_builder(*geometry_fields, "    %: [..] %;\n", it.argument_name_in_buffer_object, it.type_in_jai);
    }

    copy_assignments: String_Builder;
    init_string_builder(*copy_assignments);
    print_to_builder(*copy_assignments, "    array_copy(*renderable.indices, geometry.indices);\n");
    for attributes {
        print_to_builder(*copy_assignments, "    array_copy(*renderable.%, geometry.%);\n", it.argument_name_in_buffer_object, it.argument_name_in_buffer_object);
    }

    shallow_assignments: String_Builder;
    init_string_builder(*shallow_assignments);
    print_to_builder(*shallow_assignments, "    renderable.indices = geometry.indices;\n");
    for attributes {
        print_to_builder(*shallow_assignments, "    renderable.% = geometry.%;\n", it.argument_name_in_buffer_object, it.argument_name_in_buffer_object);
    }

    return tprint(#string END

%1 :: struct {
%2}

assign_geometry_copy :: (renderable: *%3, geometry: $T/interface %1) {
%4}

assign_geometry :: (renderable: *%3, geometry: $T/interface %1) {
%5}

    END,
    geometry_struct_name,
    builder_to_string(*geometry_fields),
    get_renderable_struct_name(shader),
    builder_to_string(*copy_assignments),
    builder_to_string(*shallow_assignments)
    );
}

generate_code_for_set_local_to_world_matrix :: (shader: Shader_Metadata) -> string {
    push_allocator(temp);

    renderable_struct_name := get_renderable_struct_name(shader);
    renderer_struct_name := get_renderer_struct_name(shader);

    return tprint(#string END

set_local_to_world_matrix :: (renderer: *%1, renderable: %2, matrix: Matrix4) {
    set_matrix(*renderer.ltw_pool, renderable.local_to_world_index, matrix);
}

    END,
    renderer_struct_name,
    renderable_struct_name
    );
}

generate_code_for_deinit_renderable :: (shader: Shader_Metadata) -> string {
    push_allocator(temp);

    array_frees: String_Builder;
    init_string_builder(*array_frees);

    print_to_builder(*array_frees, "    array_free(renderable.indices);\n");
    attributes := shader_attribute_configurations(shader);
    for attributes {
        print_to_builder(*array_frees, "    array_free(renderable.%);\n", it.argument_name_in_buffer_object);
    }

    per_object_transform_cleanup := "";
    if shader.per_object_transforms {
        per_object_transform_cleanup = "    free_index(*renderer.ltw_pool, renderable.local_to_world_index);\n    renderable.local_to_world_index = 0;\n    renderable.object_index = 0;\n";
    }

    return tprint(#string END

deinit :: (renderable: *%1) {
%4}

/*

So deinit exists but also unbuffer object exists, the difference is that deinit takes in a renderable and frees its CPU-side arrays and resets its transform slot, whereas unbuffer_object only frees the GPU-side virtual allocation, leaving the CPU data intact for potential re-buffering later.

*/
deinit :: (renderable: *%1, renderer: *%2) {
    unbuffer_object(*renderer.psr, renderable.object_index);
%3%4}

    END,
    get_renderable_struct_name(shader),
    get_renderer_struct_name(shader),
    per_object_transform_cleanup,
    builder_to_string(*array_frees)
    );
}

generate_code_for_unbuffer_renderable :: (shader: Shader_Metadata) -> string {
    push_allocator(temp);

    local_to_world_reset := "";
    if shader.per_object_transforms {
        local_to_world_reset = tprint(
            "    free_index(*renderer.ltw_pool, renderable.local_to_world_index);\n    renderable.local_to_world_index = 0;\n"
        );
    }

    return tprint(#string END

unbuffer_object :: (renderer: *%1, renderable: *%2) {
    unbuffer_object(*renderer.psr, renderable.object_index);
%3    renderable.object_index = 0;
}

    END,
    get_renderer_struct_name(shader),
    get_renderable_struct_name(shader),
    local_to_world_reset
    );
}

generate_code_for_queue_render_from_renderable :: (shader: Shader_Metadata) -> string {
    return tprint(#string END

queue_render :: (using renderer: *%1, renderable: %2) {
    queue_render(*renderer.psr, renderable.object_index);
}

    END,
    get_renderer_struct_name(shader),
    get_renderable_struct_name(shader));
}

generate_code_for_initting_matrices :: (s : Shader_Metadata) -> string {
    if !s.per_object_transforms return "";
    return #string END
    init(*renderer.ltw_pool);
    END;
}

generate_code_for_caching_uniform_locations :: (shader: Shader_Metadata) -> string {
    push_allocator(temp);
    builder: String_Builder;
    init_string_builder(*builder);

    uniforms := shader_uniform_configurations(shader);
    for uniforms {
        print_to_builder(*builder, 
            "    %_uniform_location = glGetUniformLocation(shader_program_gl_handle, \"%\");\n",
            it.var_name_in_shader, it.var_name_in_shader);
    }

    return builder_to_string(*builder);
}

generate_code_for_init :: (shader : Shader_Metadata) -> string {

    immediate_init_call := ifx shader.immediate_mode_support then "    init_immediate_buffers(renderer);\n" else "";
    init_buffers_call := ifx shader_attribute_configurations(shader).count > 0 then "    init_buffers_no_data(renderer);\n" else "";

    return tprint(#string END

init :: (using renderer : *%1) { 
    vertex_shader_loaded, vertex_shader_source := load_asset("%2");
    assert(vertex_shader_loaded, "Failed to load vertex shader asset: %2");
    fragment_shader_loaded, fragment_shader_source := load_asset("%3");
    assert(fragment_shader_loaded, "Failed to load fragment shader asset: %3");

    init(renderer, vertex_shader_source, fragment_shader_source, max_num_elements_in_each_buffer);
%6%7
%4
%5
}

    END, get_renderer_struct_name(shader), 
         shader.vertex_shader_path, 
         shader.fragment_shader_path, 
         generate_code_for_initting_matrices(shader),
         generate_code_for_caching_uniform_locations(shader),
         init_buffers_call,
         immediate_init_call); 
}

generate_code_for_deinit_renderer :: (shader: Shader_Metadata) -> string {
    push_allocator(temp);

    builder: String_Builder;
    init_string_builder(*builder);

    // deinit the local-to-world matrix pool if applicable
    if shader.per_object_transforms {
        print_to_builder(*builder, "    deinit(*ltw_pool);\n\n");
    }

    // deinit the base per-shader renderer (shader program, VAO, index buffer, tables, allocator, etc.)
    print_to_builder(*builder, "    deinit(*psr);\n\n");

    // delete per-attribute GL buffers
    attributes := shader_attribute_configurations(shader);
    for attributes {
        print_to_builder(*builder, "    glDeleteBuffers(1, *%_buffer_gl_handle);\n", it.plural_name);
    }

    // delete the local_to_world_index buffer if applicable
    if shader.per_object_transforms {
        print_to_builder(*builder, "    glDeleteBuffers(1, *local_to_world_index_buffer_gl_handle);\n");
    }

    // delete immediate-mode GL resources if applicable
    if shader.immediate_mode_support {
        print_to_builder(*builder, "\n    // immediate-mode cleanup\n");
        print_to_builder(*builder, "    glDeleteBuffers(1, *immediate_index_buffer_gl_handle);\n");
        if shader.per_object_transforms {
            print_to_builder(*builder, "    glDeleteBuffers(1, *immediate_local_to_world_index_buffer_gl_handle);\n");
        }
        for attributes {
            print_to_builder(*builder, "    glDeleteBuffers(1, *immediate_%_buffer_gl_handle);\n", it.plural_name);
        }
        print_to_builder(*builder, "    glDeleteVertexArrays(1, *immediate_vertex_attribute_array_gl_handle);\n");
    }

    return tprint(#string END

deinit :: (using renderer : *%1) {
%2}

    END,
    get_renderer_struct_name(shader),
    builder_to_string(*builder));
}

generate_attribute_setup_code :: (attributes: [] GL_Vertex_Attribute_Configuration) -> string {
    push_allocator(temp);
    builder: String_Builder;

    for glvac: attributes {
        if is_disabled_generated_vertex_attribute(glvac) continue;

        print_to_builder(*builder,
            "    generate_buffer_for_vertex_attribute(*%_buffer_gl_handle, %, max_num_elements_in_each_buffer);\n",
            glvac.plural_name, glvac.type_in_jai
        );

        print_to_builder(*builder,
            "    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, %_buffer_gl_handle, \"%\", %, %, %, %, %);\n\n",
            glvac.plural_name,
            glvac.var_name_in_shader,
            glvac.components_per_vertex,
            gl_enum_to_string(glvac.data_type_of_component),
            gl_bool_to_string(glvac.normalize),
            glvac.stride,
            pointer_offset_to_string(glvac.pointer_offset_to_start_of_data)
        );
    }

    return builder_to_string(*builder);
}

generate_code_for_setting_up_local_to_world_matrices :: (shader : Shader_Metadata) -> string {
    if !shader.per_object_transforms return "";
    return #string END

    generate_buffer_for_vertex_attribute(*local_to_world_index_buffer_gl_handle, u32, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, local_to_world_index_buffer_gl_handle, "local_to_world_index", 1, GL_UNSIGNED_INT, GL_FALSE, 0, null);

    END;
}


generate_init_buffers_no_data :: (shader : Shader_Metadata) -> string {
    return tprint(#string END


init_buffers_no_data :: (using apcr : *%1) { // todo change renderer name

    glGenVertexArrays(1, *vertex_attribute_array_gl_handle);
    glBindVertexArray(vertex_attribute_array_gl_handle);

%2

    glGenBuffers(1, *index_buffer_gl_handle);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index_buffer_gl_handle);
    // NOTE: it's probably wrong to use  max_num_elements_in_each_buffer because as noted before the number of indices
    // could be larger than this value if we try and render all objects, but we won't care about that until it's a problem.
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, size_of(u32) *  max_num_elements_in_each_buffer, null, GL_DYNAMIC_DRAW);
    // note: we don't have to init the vertex attribute for indices because they used in the shader program for rendering, they're just used during glDrawElements.

%3

	glBindBuffer (GL_ARRAY_BUFFER, 0);
}

    END, 
    get_renderer_struct_name(shader), 
    generate_code_for_setting_up_local_to_world_matrices(shader), 
    generate_attribute_setup_code(shader_attribute_configurations(shader)));
}

generate_init_immediate_buffers :: (shader : Shader_Metadata) -> string {
    if !shader.immediate_mode_support return "";

    push_allocator(temp);

    per_object_immediate_attribute_setup := "";
    if shader.per_object_transforms {
        per_object_immediate_attribute_setup = tprint(#string END
    immediate_local_to_world_indices: [..] u32;
    defer array_free(immediate_local_to_world_indices);
    array_resize(*immediate_local_to_world_indices, %);
    for * immediate_local_to_world_indices it.* = 0;
    glGenBuffers(1, *immediate_local_to_world_index_buffer_gl_handle);
    glBindBuffer(GL_ARRAY_BUFFER, immediate_local_to_world_index_buffer_gl_handle);
    glBufferData(GL_ARRAY_BUFFER, size_of(u32) * immediate_local_to_world_indices.count, immediate_local_to_world_indices.data, GL_STATIC_DRAW);
    init_vertex_attribute(shader_program_gl_handle, immediate_vertex_attribute_array_gl_handle, immediate_local_to_world_index_buffer_gl_handle, "local_to_world_index", 1, GL_UNSIGNED_INT, GL_FALSE, 0, null);

    END, shader.num_elements_in_each_immediate_buffer);
    }

    attribute_setup: String_Builder;
    init_string_builder(*attribute_setup);

    attributes := shader_attribute_configurations(shader);
    for attr_conf: attributes {

        print_to_builder(*attribute_setup,
            "    generate_buffer_for_vertex_attribute(*immediate_%_buffer_gl_handle, %, %);\n",
            attr_conf.plural_name, attr_conf.type_in_jai, shader.num_elements_in_each_immediate_buffer
        );

        print_to_builder(*attribute_setup,
            "    init_vertex_attribute(shader_program_gl_handle, immediate_vertex_attribute_array_gl_handle, immediate_%_buffer_gl_handle, \"%\", %, %, %, %, %);\n\n",
            attr_conf.plural_name,
            attr_conf.var_name_in_shader,
            attr_conf.components_per_vertex,
            gl_enum_to_string(attr_conf.data_type_of_component),
            gl_bool_to_string(attr_conf.normalize),
            attr_conf.stride,
            pointer_offset_to_string(attr_conf.pointer_offset_to_start_of_data)
        );
    }

    return tprint(#string END


init_immediate_buffers :: (using renderer : *%1) {

    glGenVertexArrays(1, *immediate_vertex_attribute_array_gl_handle);
    glBindVertexArray(immediate_vertex_attribute_array_gl_handle);

    glGenBuffers(1, *immediate_index_buffer_gl_handle);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, immediate_index_buffer_gl_handle);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, size_of(u32) * %2, null, GL_STREAM_DRAW);

%3
%4

    glBindBuffer(GL_ARRAY_BUFFER, 0);
}

    END, 
    get_renderer_struct_name(shader),
    shader.num_elements_in_each_immediate_buffer,
    per_object_immediate_attribute_setup,
    builder_to_string(*attribute_setup));
}


generate_buffer_vertex_attribute_data_at_index_code :: (attr_conf: GL_Vertex_Attribute_Configuration) -> string {
    return tprint(#string END

    glBindBuffer(GL_ARRAY_BUFFER, %1_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, index * size_of(%2), %3.count * size_of(%2), %3.data);

    END, attr_conf.plural_name, attr_conf.type_in_jai, attr_conf.argument_name_in_buffer_object);
}


code_to_buffer_local_to_world_indices :: #string END
    ltw_index_we_used, ltw_success := alloc_index(*ltw_pool);
    if !ltw_success {
        virtual_free(*first_fit_virtual_allocator, index);
        return 0, 0, false;
    }

    local_to_world_indices: [..] u32;
    for 0..positions.count-1 array_add(*local_to_world_indices, ltw_index_we_used);

    glBindBuffer(GL_ARRAY_BUFFER, local_to_world_index_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, index * size_of(u32), local_to_world_indices.count * size_of(u32), local_to_world_indices.data);

    array_free(local_to_world_indices);
END;

generate_buffer_vertex_attributes_code :: (shader : Shader_Metadata) -> string {
    push_allocator(temp);
    builder: String_Builder;

    attributes := shader_attribute_configurations(shader);
    for attributes {
        print_to_builder(*builder, "    %\n", generate_buffer_vertex_attribute_data_at_index_code(it));
    }

    if shader.per_object_transforms print_to_builder(*builder, code_to_buffer_local_to_world_indices);

    return builder_to_string(*builder);
}

generate_parameter_list_for_buffer_object :: (shader : Shader_Metadata) -> string {

    push_allocator(temp);
    builder: String_Builder;


    attributes := shader_attribute_configurations(shader);
    for attributes {
        print_to_builder(*builder, "        % : [..] %", it.argument_name_in_buffer_object, it.type_in_jai); 
        if it_index < attributes.count-1 print_to_builder(*builder, ",\n");
    }

    return tprint(#string END
        using renderer: *%1,
        indices : [..] u32,
%2
    END, get_renderer_struct_name(shader), builder_to_string(*builder));
}

// was about to integrate this.

generate_code_for_return_type_of_buffer_object :: (shader : Shader_Metadata) -> string {
    if shader.per_object_transforms return "object_index: u32, local_to_world_index: u32, success: bool";
    return "object_index: u32, success: bool";
}

generate_code_for_return_in_failure_case  :: (shader : Shader_Metadata) -> string {
    if shader.per_object_transforms return "return 0, 0, false;";
    return "return 0, false;";
}

generate_code_for_final_return :: (shader : Shader_Metadata) -> string {
    if shader.per_object_transforms return "return index, ltw_index_we_used, true;";
    return "return index, true;";
}


generate_buffer_object :: (shader : Shader_Metadata) -> string {

    return tprint(#string END
// todo ability to specify the transform matrix upon buffering?
buffer_object :: (
%1
        ) -> %2 {

    // note: we use the positions as count, becaues that is the actual data that needs to be in the buffer
    // the indices use duplicates sometimes to refer to the same vertex multiple times.
    length := positions.count; // TODO: need to metaprogram this out, but it's pretty safe for now.
    index, success := virtual_alloc(*first_fit_virtual_allocator, xx length);
    if !success {
        log("ran out of virtual memory");
        %3
    }

    global_indices_for_object : [..] u32;
    for indices 
        array_add(*global_indices_for_object, xx index + it);

    table_add(*buffered_object_index_to_global_indices, xx index, global_indices_for_object);

    glBindVertexArray(vertex_attribute_array_gl_handle);

%4

    glBindVertexArray(0);

    %5
}
    END, 
    generate_parameter_list_for_buffer_object(shader), 
    generate_code_for_return_type_of_buffer_object(shader), 
    generate_code_for_return_in_failure_case(shader),
    generate_buffer_vertex_attributes_code(shader),
    generate_code_for_final_return(shader)
    );

}

generate_code_for_buffer_object_from_renderable :: (shader : Shader_Metadata) -> string {

    push_allocator(temp); 

    // we're building a the body here.
    buffer_object_call_code: String_Builder;

    if !shader.per_object_transforms { 
        print_to_builder(*buffer_object_call_code, #string END

    object_index, success := buffer_object(renderer, 
            renderable.indices, 

        END);
    } else {
        print_to_builder(*buffer_object_call_code, #string END

    object_index, local_to_world_index, success := buffer_object(renderer, 
            renderable.indices, 

        END);
    }

    attributes := shader_attribute_configurations(shader);
    for attributes {
        print_to_builder(*buffer_object_call_code, "            renderable.%", it.argument_name_in_buffer_object); 
        if it_index < attributes.count-1 {
            print_to_builder(*buffer_object_call_code, ",\n");
        } else {
            print_to_builder(*buffer_object_call_code, "\n    );");
        }
    }

    success_assignment_code : String_Builder;
    print_to_builder(*success_assignment_code, "        renderable.object_index = object_index;\n");
    if shader.per_object_transforms print_to_builder(*success_assignment_code, "        renderable.local_to_world_index = local_to_world_index;\n");

    return tprint(#string END

buffer_object :: (using renderer : *%1, renderable : *$T/interface %2) -> success: bool {

%3

    if success {
%4
    };
    return success;
}

    END, 
    get_renderer_struct_name(shader), 
    get_renderable_struct_name(shader),
    builder_to_string(*buffer_object_call_code),
    builder_to_string(*success_assignment_code)
    );
}

generate_rebuffer_object :: (shader : Shader_Metadata) -> string {
    push_allocator(temp);

    renderer_name := get_renderer_struct_name(shader);
    renderable_name := get_renderable_struct_name(shader);

    upload_code: String_Builder;
    init_string_builder(*upload_code);

    attributes := shader_attribute_configurations(shader);
    for attr_conf: attributes {
        print_to_builder(*upload_code, #string ATTR
    glBindBuffer(GL_ARRAY_BUFFER, %1_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, renderable.object_index * size_of(%2), renderable.%3.count * size_of(%2), renderable.%3.data);

ATTR,
            attr_conf.plural_name,
            attr_conf.type_in_jai,
            attr_conf.argument_name_in_buffer_object);
    }

    return tprint(#string END

/*

So this function is kinda sketchy right now, you can only rebuffer an object if it takes up the exact same size, 
if you're rebuffering things and using up more space then you did before you'll start having undefined behavior in rendering and things 
will go off the rails.

*/
rebuffer_object :: (using renderer : *%1, renderable : $T/interface %2) {

    glBindVertexArray(vertex_attribute_array_gl_handle);

%3
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);
}

    END,
    renderer_name,
    renderable_name,
    builder_to_string(*upload_code));
}


generate_code_for_uploading_local_to_world_matrices :: (s: Shader_Metadata) -> string {
    if !s.per_object_transforms return "";
    return #string END

    upload_to_gpu(*ltw_pool);

    END;
}

generate_render :: (shader : Shader_Metadata) -> string {

    return tprint(#string END
render :: (using renderer : *%1, primitive_mode: GLenum = %3) {

    // todo think about if we should be using temporary storage.

    glUseProgram(shader_program_gl_handle);

%2

    glBindVertexArray(vertex_attribute_array_gl_handle);
    // todo: reserve so we don't get a ton of reallocations in this for loop
    geom_indices_to_render : [..] u32;  // can we just use temp storage?
    defer array_free(geom_indices_to_render);
    // array_reserve(*geom_indices_to_render, ???); // needs some running count whenever we buffer an obj.
    for object_indices_to_render_this_frame {
        success, geom_indices := table_find(*buffered_object_index_to_global_indices, it);
        if !success log("couldn't find the global indices of object with id: %", it);
        for geom_indices 
            array_add(*geom_indices_to_render, it);
    }


    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index_buffer_gl_handle);
    // here we're just overwriting the buffer on each draw call, if there's less data written than last iteration it's fine
    // as we will only access the smaller portion
    glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, 0, geom_indices_to_render.count * size_of(u32), geom_indices_to_render.data);

    glDrawElements(primitive_mode, xx geom_indices_to_render.count, GL_UNSIGNED_INT, cast (*void) 0);

    // the rendering the same objects test as last frame test is a worthwhile optimization that should occur.

    array_reset(*object_indices_to_render_this_frame);

    glBindVertexArray(0);
    glUseProgram(0);
}

    END, 
    get_renderer_struct_name(shader), 
    generate_code_for_uploading_local_to_world_matrices(shader),
    gl_primitive_mode_to_string(shader.primitive_mode),
    );

}

generate_immediate_render :: (shader : Shader_Metadata) -> string {
    if !shader.immediate_mode_support return "";

    push_allocator(temp);

    param_list: String_Builder;
    init_string_builder(*param_list);
    attributes := shader_attribute_configurations(shader);
    for attributes {
        print_to_builder(*param_list, "        % : [] %", it.argument_name_in_buffer_object, it.type_in_jai);
        if it_index < attributes.count-1 print_to_builder(*param_list, ",\n");
    }

    upload_code: String_Builder;
    init_string_builder(*upload_code);
    for attr_conf: attributes {
        print_to_builder(*upload_code,
            "    glBindBuffer(GL_ARRAY_BUFFER, immediate_%1_buffer_gl_handle);\n    glBufferSubData(GL_ARRAY_BUFFER, 0, %2.count * size_of(%3), %2.data);\n\n",
            attr_conf.plural_name, attr_conf.argument_name_in_buffer_object, attr_conf.type_in_jai);
    }

    slice_version := tprint(#string END

immediate_render :: (
        using renderer: *%1,
        indices : [] u32,
%2
        ) {

    assert(indices.count > 0, "No indices to render.");

    glUseProgram(shader_program_gl_handle);
    glBindVertexArray(immediate_vertex_attribute_array_gl_handle);

%3
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, immediate_index_buffer_gl_handle);
    glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, 0, indices.count * size_of(u32), indices.data);

    glDrawElements(GL_TRIANGLES, xx indices.count, GL_UNSIGNED_INT, cast(*void) 0);

    glBindVertexArray(0);
    glUseProgram(0);
}

    END,
    get_renderer_struct_name(shader),
    builder_to_string(*param_list),
    builder_to_string(*upload_code));

    // Geometry convenience overload
    geometry_struct_name := tprint("%1_Geometry", shader.name);

    geometry_args: String_Builder;
    init_string_builder(*geometry_args);
    print_to_builder(*geometry_args, "            geometry.indices,\n");
    for attributes {
        print_to_builder(*geometry_args, "            geometry.%", it.argument_name_in_buffer_object);
        if it_index < attributes.count - 1 print_to_builder(*geometry_args, ",\n");
        else print_to_builder(*geometry_args, "\n");
    }

    geometry_version := tprint(#string END

immediate_render :: (using renderer : *%1, geometry : $T/interface %2) {
    immediate_render(renderer,
%3    );
}

    END,
    get_renderer_struct_name(shader),
    geometry_struct_name,
    builder_to_string(*geometry_args));

    // Combine both
    result: String_Builder;
    init_string_builder(*result);
    append(*result, slice_version);
    append(*result, geometry_version);
    return builder_to_string(*result);
}

generate_buffer_for_vertex_attribute :: (attribute_buffer_gl_handle : *GLuint, $attribute_type : Type, num_elements: u32) {
    glGenBuffers(1, attribute_buffer_gl_handle);
    glBindBuffer(GL_ARRAY_BUFFER, attribute_buffer_gl_handle.*);
    glBufferData(GL_ARRAY_BUFFER, size_of(attribute_type) * num_elements, null, GL_DYNAMIC_DRAW);
}

GL_Vertex_Attribute_Configuration :: struct { // gl_vac

    type_in_jai: Type;

    // I'm pretty sure this is just the enum name right? can I remove this?
    var_name_in_shader : string;

    // the plural name can be automated as well, index -> indices everything else trivial add exceptions when needed.
    // this is actually what we call something in the code or something.
    plural_name : string;

    argument_name_in_buffer_object : string;

    // when a value is constant across an object, then you only have to pass in a single value into buffer object rather than an array of them
    constant_across_object : bool;  

    // value_is_constant_per_object : bool; // as of right now only local to world index has this property, when there are other ones that have this we could think about doing this.

    components_per_vertex: GLint;
    data_type_of_component: GLenum;
    normalize : GLboolean;
    stride : GLsizei ;
    pointer_offset_to_start_of_data : *void;

    passthrough := false;
}

gl_uniform_suffix_for_type :: (type: Type) -> string { // unused didn't see the potential yet after doing the matrix fun below
    if type == {
        case Matrix4;  return "Matrix4fv";

        // uncomment as needed so we can find the bug when it happens rather than assuming this is always correct.
        // case Matrix3;  return "Matrix3fv";
        // case Matrix2;  return "Matrix2fv";
        // case Vector4;  return "4fv";
        // case Vector3;  return "3fv";
        // case Vector2;  return "2fv";
        // case float32;  return "1f";
        // case s32;      return "1i";
        // case u32;      return "1ui";
    }

    return "UNSUPPORTED_TYPE";
}

GL_Vertex_Uniform_Configuration :: struct { // (i don't give a) gl_vuc 

    type_in_jai: Type;

    var_name_in_shader : string;

    // plural_name : string; don't think I need this for uniforms??
}
generate_code_for_uniform_setter_function :: (shader : Shader_Metadata, unif_conf : GL_Vertex_Uniform_Configuration) -> string {
    lower_name := unif_conf.var_name_in_shader;
    
    // Determine the right glUniform call based on type
    gl_call: string;
    args: string;
    if unif_conf.type_in_jai == {
        case Matrix4;
            gl_call = "glUniformMatrix4fv";
            args = "renderer.%1_uniform_location, 1, GL_TRUE, *v.coef[0][0]";
        case Matrix3;
            gl_call = "glUniformMatrix3fv";
            args = "renderer.%1_uniform_location, 1, GL_TRUE, *v.coef[0][0]";
        case Vector4;
            gl_call = "glUniform4f";
            args = "renderer.%1_uniform_location, v.x, v.y, v.z, v.w";
        case Vector3;
            gl_call = "glUniform3f";
            args = "renderer.%1_uniform_location, v.x, v.y, v.z";
        case Vector2;
            gl_call = "glUniform2f";
            args = "renderer.%1_uniform_location, v.x, v.y";
        case float32;
            gl_call = "glUniform1f";
            args = "renderer.%1_uniform_location, v";
        case s32;
            gl_call = "glUniform1i";
            args = "renderer.%1_uniform_location, v";
        case u32;
            gl_call = "glUniform1ui";
            args = "renderer.%1_uniform_location, v";
        case bool;
            gl_call = "glUniform1i";
            args = "renderer.%1_uniform_location, xx v";
        case;
            gl_call = "glUniform1i";
            args = "renderer.%1_uniform_location, v";
    }
    
    // replace %1 in args with the actual lower_name
    resolved_args := tprint(args, lower_name);
    
    return tprint(#string END

set_%1_uniform :: (renderer : *%2, v: %3) {
    %4(%5);
}
    END, 
    lower_name,
    get_renderer_struct_name(shader), 
    unif_conf.type_in_jai, 
    gl_call,
    resolved_args
    );
}

generate_code_for_uniform_setter_functions :: (shader : Shader_Metadata) -> string {
    push_allocator(temp);
    builder : String_Builder;

    uniforms := shader_uniform_configurations(shader);
    for uniforms {
        print_to_builder(*builder, generate_code_for_uniform_setter_function(shader, it));
    }
    return builder_to_string(*builder); 
}


init_vertex_attribute :: (
        shader_program_gl_handle : GLuint,
        vertex_attribute_array_gl_handle: GLuint,
        attribute_buffer_gl_handle: GLuint,
        var_name_in_shader: string,
        components_per_vertex: GLint,
        data_type_of_component: GLenum,
        normalize: GLboolean,
        stride: GLsizei,
        pointer_offset_to_start_of_data: *void
    ) {

    glBindVertexArray(vertex_attribute_array_gl_handle);
    glBindBuffer(GL_ARRAY_BUFFER, attribute_buffer_gl_handle);

    vertex_attribute_gl_handle : s32 = glGetAttribLocation(shader_program_gl_handle, temp_c_string(var_name_in_shader));
    if vertex_attribute_gl_handle < 0 return;

    glEnableVertexAttribArray(xx vertex_attribute_gl_handle);

    // todo: there are probably more integer types right?
    data_type_is_integer : bool = data_type_of_component == GL_INT || data_type_of_component == GL_UNSIGNED_INT;

    if (data_type_is_integer) { 
        // doesn't take in the normalize value.
        glVertexAttribIPointer(xx vertex_attribute_gl_handle, components_per_vertex, data_type_of_component, stride, pointer_offset_to_start_of_data);
    } else {
        glVertexAttribPointer(xx vertex_attribute_gl_handle, components_per_vertex, data_type_of_component, normalize, stride, pointer_offset_to_start_of_data);
    }

    glBindVertexArray(0);
}

#load "per_shader_renderer.jai";
