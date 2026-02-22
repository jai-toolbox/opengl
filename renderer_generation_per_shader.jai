#import "String";
#import "File";

Shader_Metadata :: struct { // call this Shader_Metadata?

    name : string;

    // we use array views here because if we use dynamic arrays then 
    // we cannot fill them in at compile time, this makes them act like string literals in that way.
    attributes : [] GL_Shader_Vertex_Attribute_Variable;
    uniforms   : [] GL_Shader_Uniform_Variable;

    per_object_transforms : bool;

    num_elements_in_each_buffer : u32;

    vertex_shader_path   : string;
    fragment_shader_path : string;
}

ABSOLUTE_POSITION_COLOR_SHADER :: Shader_Metadata.{
    name = "Absolute_Position_Color", 
    attributes = .[.POSITION, .PASSTHROUGH_RGB_COLOR],
    uniforms = .[],
    per_object_transforms = false,
    num_elements_in_each_buffer = 100000,
    vertex_shader_path = "data/shaders/out/absolute_position_color.vert",
    fragment_shader_path = "data/shaders/out/color.frag"
};

CAMERA_PER_OBJECT_TRANSFORMS_COLOR :: Shader_Metadata.{
    // todo one day rename Transform to Transforms here, will have to update the using code too. hence why I'm not doing it now.
    name = "Camera_Per_Object_Transform_Color", 
    attributes = .[.POSITION, .PASSTHROUGH_RGB_COLOR],
    uniforms = .[.CAMERA_TO_CLIP, .WORLD_TO_CAMERA],
    per_object_transforms = true,
    num_elements_in_each_buffer = 100000,
    vertex_shader_path = "data/shaders/out/camera_per_object_transforms.vert",
    fragment_shader_path = "data/shaders/out/color.frag"
};

/*
 in opengl3.3 we can batch our objects together but then we run into the problem
 of how do we bind the right texture if we draw all our objects at once, this shader
 solves it by making a bunch of texture atlases of all the textures we are using 
 then we use indices to determine which atlas to go into and then which bounding box is used
 for a particular texture.

 We abbreivate all the above as a shader being "texture packed". 

 I'm pretty sure that in later versions of opengl 4.6 you can just use bindless textures, but I'm
 still keeping this in-case there's a context where 3.3 is important.
*/

CAMERA_PER_OBJECT_TRANSFORM_PACKED_TEXTURE :: Shader_Metadata.{
    // todo change to not use transforms instead just the singular.
    name = "Camera_Per_Object_Transforms_Packed_Texture", 
    attributes = .[
        .POSITION,
        .PASSTHROUGH_PACKED_TEXTURE_INDEX, 
        .PASSTHROUGH_TEXTURE_COORDINATE,
        .PASSTHROUGH_PACKED_TEXTURE_BOUNDING_BOX_INDEX,
    ],
    uniforms = .[
        .CAMERA_TO_CLIP, 
        .WORLD_TO_CAMERA,
        .PACKED_TEXTURES,
        .PACKED_TEXTURE_BOUNDING_BOXES
    ],
    per_object_transforms = true,
    num_elements_in_each_buffer = 100000,
    vertex_shader_path = "data/shaders/out/camera_per_object_transform_packed_texture.vert",
    fragment_shader_path = "data/shaders/out/packed_texture.frag"
};


CAMERA_PER_OBJECT_TRANSFORM_DEFERRED_LIGHTING_GEOMETRY_PASS :: Shader_Metadata.{
    name = "Camera_Per_Object_Transform_Deferred_Lighting_Geometry_Pass", 
    attributes = .[
        .POSITION,
        .PASSTHROUGH_RGB_COLOR,
        .PASSTHROUGH_NORMAL
    ],
    uniforms = .[
        .CAMERA_TO_CLIP, 
        .WORLD_TO_CAMERA
    ],
    per_object_transforms = true,
    num_elements_in_each_buffer = 100000,
    vertex_shader_path   = "data/shaders/out/lighting/camera_per_object_transform_color_normal.vert",
    fragment_shader_path = "data/shaders/out/lighting/render_position_color_normal_textures.frag"
};

CAMERA_PER_OBJECT_TRANSFORM_DEFERRED_LIGHTING_COMPUTE_LIGHT_PASS :: Shader_Metadata.{
    name = "Camera_Per_Object_Transform_Deferred_Lighting_Compute_Light_Pass", 
    attributes = .[
        .POSITION,
        .PASSTHROUGH_TEXTURE_COORDINATE,
    ],
    uniforms = .[
        .ASPECT_RATIO,
        .POSITION_TEXTURE,
        .COLOR_TEXTURE,
        .NORMAL_TEXTURE
    ],
    per_object_transforms = false,
    num_elements_in_each_buffer = 100000,
    vertex_shader_path   = "data/shaders/out/absolute_position_textured.vert",
    fragment_shader_path = "data/shaders/out/lighting/compute_lighting_from_position_color_normal_textures.frag"
};

get_renderer_struct_name :: (shader : Shader_Metadata) -> string {
    return tprint("%1_Renderer", shader.name);
}

get_renderable_struct_name :: (shader : Shader_Metadata) -> string {
    return tprint("%1_Renderable", shader.name);
}

#run create_code_to_render_stuff_with_shader(ABSOLUTE_POSITION_COLOR_SHADER);
#run create_code_to_render_stuff_with_shader(CAMERA_PER_OBJECT_TRANSFORMS_COLOR);

#run create_code_to_render_stuff_with_shader(CAMERA_PER_OBJECT_TRANSFORM_PACKED_TEXTURE);

#run create_code_to_render_stuff_with_shader(CAMERA_PER_OBJECT_TRANSFORM_DEFERRED_LIGHTING_GEOMETRY_PASS);
#run create_code_to_render_stuff_with_shader(CAMERA_PER_OBJECT_TRANSFORM_DEFERRED_LIGHTING_COMPUTE_LIGHT_PASS);

create_code_to_render_stuff_with_shader :: (shader: Shader_Metadata) {
    push_allocator(temp);

    builder: String_Builder;
    init_string_builder(*builder);

    print_to_builder(*builder, "// auto-generated renderer for shader: %\n", shader.name);
    print_to_builder(*builder, "// do not edit manually.\n\n");

    append(*builder, generate_renderable_struct_for_given_shader(shader));
    append(*builder, generate_code_for_constructing_renderable_from_generic_geometry_type(shader));
    append(*builder, generate_code_for_deinit_renderable(shader));
    if shader.per_object_transforms append(*builder, generate_code_for_set_local_to_world_matrix(shader));
    append(*builder, generate_renderer_struct_for_given_shader(shader));
    append(*builder, generate_code_for_uniform_setter_functions(shader));
    append(*builder, generate_code_for_init(shader));
    append(*builder, generate_init_buffers_no_data(shader));
    append(*builder, generate_code_for_buffer_object_from_renderable(shader));
    append(*builder, generate_buffer_object(shader));
    append(*builder, generate_render(shader));

    output := builder_to_string(*builder);

    renderers_dir := tprint("%/renderers", #filepath);
    make_directory_if_it_does_not_exist(renderers_dir);

    filename := tprint("%/%_renderer.jai", renderers_dir, to_lower_copy(shader.name));

    success := write_entire_file(filename, output);
    if !success {
        log_error("Failed to write generated file: %", filename);
    } else {
        log("Generated: %", filename);
    }
}

jai_struct_attributes_for_gl_vertex_attribute_handles :: (attributes: [] GL_Shader_Vertex_Attribute_Variable) -> string {
    push_allocator(temp); // everything in this function is temp storage, yay!

    builder: String_Builder;
    init_string_builder(*builder); 

    for attributes {
        attr_conf := get_configuration(it); 
        print_to_builder(*builder, "    %_buffer_gl_handle: GLuint;\n", attr_conf.plural_name);
    }

    return builder_to_string(*builder);
}

generate_code_for_per_object_transform_attributes :: (s : Shader_Metadata) -> string {
    if !s.per_object_transforms return "";

    return #string END 

    NUM_LOCAL_TO_WORLD_MATRICES :: 1024;
    current_local_to_world_index : u32 = 0;
    local_to_world_matrices : [NUM_LOCAL_TO_WORLD_MATRICES] Matrix4; 
    local_to_world_gl_uniform_buffer_handle : GLuint;

    local_to_world_index_buffer_gl_handle : GLuint;

    END;
}

generate_renderer_struct_for_given_shader :: (s : Shader_Metadata) -> string {

    return tprint(#string END

%1 :: struct {
    using #as psr : Per_Shader_Renderer;

%2

%3
}

    END, get_renderer_struct_name(s), generate_code_for_per_object_transform_attributes(s), jai_struct_attributes_for_gl_vertex_attribute_handles(s.attributes));
}

generate_renderable_struct_attributes :: (shader : Shader_Metadata) -> string {
    push_allocator(temp); 

    builder: String_Builder;
    init_string_builder(*builder); 

    if shader.per_object_transforms print_to_builder(*builder, "    local_to_world_index : u32;\n\n");

    for shader.attributes {
        attr_conf := get_configuration(it); 
        print_to_builder(*builder, "    %: [..] %;\n", attr_conf.argument_name_in_buffer_object, attr_conf.type_in_jai);
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
    for shader.attributes {
        attr_conf := get_configuration(it);
        print_to_builder(*geometry_fields, "    %: [..] %;\n", attr_conf.argument_name_in_buffer_object, attr_conf.type_in_jai);
    }

    assignments: String_Builder;
    init_string_builder(*assignments);
    print_to_builder(*assignments, "    array_copy(*renderable.indices, geometry.indices);\n");
    for shader.attributes {
        attr_conf := get_configuration(it);
        print_to_builder(*assignments, "    array_copy(*renderable.%, geometry.%);\n", attr_conf.argument_name_in_buffer_object, attr_conf.argument_name_in_buffer_object);
    }

    return tprint(#string END

%1 :: struct {
%2}

assign_geometry :: (renderable: *%3, geometry: $T/interface %1) {
%4}

    END,
    geometry_struct_name,
    builder_to_string(*geometry_fields),
    get_renderable_struct_name(shader),
    builder_to_string(*assignments)
    );
}

generate_code_for_set_local_to_world_matrix :: (shader: Shader_Metadata) -> string {
    push_allocator(temp);

    renderable_struct_name := get_renderable_struct_name(shader);
    renderer_struct_name := get_renderer_struct_name(shader);

    return tprint(#string END

set_local_to_world_matrix :: (renderer: *%1, renderable: %2, matrix: Matrix4) {
    renderer.local_to_world_matrices[renderable.local_to_world_index] = matrix;
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
    for shader.attributes {
        attr_conf := get_configuration(it);
        print_to_builder(*array_frees, "    array_free(renderable.%);\n", attr_conf.argument_name_in_buffer_object);
    }

    per_object_transform_cleanup := "";
    if shader.per_object_transforms {
        per_object_transform_cleanup = "    renderer.local_to_world_matrices[renderable.local_to_world_index] = Matrix4_Identity;\n";
    }

    return tprint(#string END

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

generate_code_for_initting_matrices :: (s : Shader_Metadata) -> string {
    if !s.per_object_transforms return "";
    return #string END
    for 0..NUM_LOCAL_TO_WORLD_MATRICES-1
        // this might not be necessary, doing it for now
        local_to_world_matrices[it] = Matrix4_Identity;
    END;
}

generate_code_for_init :: (shader : Shader_Metadata) -> string {
    return tprint(#string END

init :: (using renderer : *%1) { 
    vertex_shader_source := read_entire_file("%2");
    fragment_shader_source := read_entire_file("%3");

    init(renderer, vertex_shader_source, fragment_shader_source, max_num_elements_in_each_buffer);
    init_buffers_no_data(renderer);

%4

}

    END, get_renderer_struct_name(shader), shader.vertex_shader_path, shader.fragment_shader_path, generate_code_for_initting_matrices(shader));
}

generate_attribute_setup_code :: (attributes: [] GL_Shader_Vertex_Attribute_Variable) -> string {
    push_allocator(temp);
    builder: String_Builder;

    for attr: attributes {
        glvac := get_configuration(attr);

        print_to_builder(*builder,
            "    generate_buffer_for_vertex_attribute(*%_buffer_gl_handle, %, max_num_elements_in_each_buffer);\n",
            glvac.plural_name, glvac.type_in_jai
        );

        print_to_builder(*builder,
            "    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, %_buffer_gl_handle, .%);\n\n",
            glvac.plural_name, attr
        );
    }

    return builder_to_string(*builder);
}

generate_code_for_setting_up_local_to_world_matrices :: (shader : Shader_Metadata) -> string {
    if !shader.per_object_transforms return "";
    return #string END

    glGenBuffers(1, *local_to_world_gl_uniform_buffer_handle);
    glBindBuffer(GL_UNIFORM_BUFFER, local_to_world_gl_uniform_buffer_handle);
    glBufferData(GL_UNIFORM_BUFFER, local_to_world_matrices.count * size_of(Matrix4), local_to_world_matrices.data, GL_DYNAMIC_DRAW);
    glBindBufferBase(GL_UNIFORM_BUFFER, 0, local_to_world_gl_uniform_buffer_handle);

    generate_buffer_for_vertex_attribute(*local_to_world_index_buffer_gl_handle, u32, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, local_to_world_index_buffer_gl_handle, .LOCAL_TO_WORLD_INDEX);

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
    generate_attribute_setup_code(shader.attributes));
}


generate_buffer_vertex_attribute_data_at_index_code :: (attribute: GL_Shader_Vertex_Attribute_Variable) -> string {
    // maybe just pass the conf then?
    attr_conf := get_configuration(attribute);
    return tprint(#string END

    glBindBuffer(GL_ARRAY_BUFFER, %1_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, index * size_of(%2), %3.count * size_of(%2), %3.data);

    END, attr_conf.plural_name, attr_conf.type_in_jai, attr_conf.argument_name_in_buffer_object);
}


code_to_buffer_local_to_world_indices :: #string END
    // local_to_world_indices are an array of the same value which is the local to world index
    // the alternative to this is binding the uniform per object, which we're trying to avoid because we want to render
    // everything at once in one big draw call.

    local_to_world_indices: [..] u32;
    for 0..positions.count array_add(*local_to_world_indices, current_local_to_world_index);

    ltw_index_we_used := current_local_to_world_index;
    current_local_to_world_index += 1;

    glBindBuffer(GL_ARRAY_BUFFER, local_to_world_index_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, index * size_of(u32), local_to_world_indices.count * size_of(u32), local_to_world_indices.data);
END;

generate_buffer_vertex_attributes_code :: (shader : Shader_Metadata) -> string {
    push_allocator(temp);
    builder: String_Builder;

    for shader.attributes {
        print_to_builder(*builder, "    %\n", generate_buffer_vertex_attribute_data_at_index_code(it));
    }

    if shader.per_object_transforms print_to_builder(*builder, code_to_buffer_local_to_world_indices);

    return builder_to_string(*builder);
}

generate_parameter_list_for_buffer_object :: (shader : Shader_Metadata) -> string {

    push_allocator(temp);
    builder: String_Builder;


    for shader.attributes {
        attr_conf := get_configuration(it);
        print_to_builder(*builder, "        % : [..] %", attr_conf.argument_name_in_buffer_object, attr_conf.type_in_jai); 
        if it_index < shader.attributes.count-1 print_to_builder(*builder, ",\n");
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

    for shader.attributes {
        attr_conf := get_configuration(it);
        print_to_builder(*buffer_object_call_code, "            renderable.%", attr_conf.argument_name_in_buffer_object); 
        if it_index < shader.attributes.count-1 {
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


generate_code_for_uploading_local_to_world_matrices :: (s: Shader_Metadata) -> string {
    if !s.per_object_transforms return "";
    return #string END
    glBindBuffer(GL_UNIFORM_BUFFER, local_to_world_gl_uniform_buffer_handle);
    glBufferData(GL_UNIFORM_BUFFER, size_of(Matrix4) * local_to_world_matrices.count, local_to_world_matrices.data, GL_DYNAMIC_DRAW);
    glBindBufferBase(GL_UNIFORM_BUFFER, 0, local_to_world_gl_uniform_buffer_handle);
    END;
}

generate_render :: (shader : Shader_Metadata) -> string {

    return tprint(#string END
render :: (using renderer : *%1) {

    // todo think about if we should be using temporary storage.

    glUseProgram(shader_program_gl_handle);

%2

    glBindVertexArray(vertex_attribute_array_gl_handle);
    // todo: reserve so we don't get a ton of reallocations in this for loop
    geom_indices_to_render : [..] u32; 
    // array_reserve(*geom_indices_to_render, ???); // needs some running count whenever we buffer an obj.
    for object_indices_to_render_this_frame {
        geom_indices , success := table_find(*buffered_object_index_to_global_indices, it);
        if !success log("couldn't find the global indices of object with id: %", it);
        for geom_indices 
            array_add(*geom_indices_to_render, it);
    }


    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index_buffer_gl_handle);
    // here we're just overwriting the buffer on each draw call, if there's less data written than last iteration it's fine
    // as we will only access the smaller portion
    glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, 0, geom_indices_to_render.count * size_of(u32), geom_indices_to_render.data);

    glDrawElements(GL_TRIANGLES, xx geom_indices_to_render.count, GL_UNSIGNED_INT, cast (*void) 0);

    // the rendering the same objects test as last frame test is a worthwhile optimization that should occur.

    array_reset(*object_indices_to_render_this_frame);

    glBindVertexArray(0);
    glUseProgram(0);
}

    END, get_renderer_struct_name(shader), generate_code_for_uploading_local_to_world_matrices(shader));

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

set_uniform :: (shader_program_gl_handle: GLuint, uniform: GL_Shader_Uniform_Variable, m: Matrix4) {
    gl_vuc := get_configuration(uniform);

    row_major := GL_TRUE;
    num_matrices_we_are_updating: u32 = 1;

    uniform_location := glGetUniformLocation(shader_program_gl_handle, temp_c_string(gl_vuc.var_name_in_shader));

    glUniformMatrix4fv(uniform_location, num_matrices_we_are_updating, row_major, *m.coef[0][0]);
}

set_uniform :: (shader_program_gl_handle: GLuint, uniform: GL_Shader_Uniform_Variable, v: Vector2) {
    gl_vuc := get_configuration(uniform);
    uniform_location := glGetUniformLocation(shader_program_gl_handle, temp_c_string(gl_vuc.var_name_in_shader));
    glUniform2f(uniform_location, v.x, v.y);
}

set_uniform :: (shader_program_gl_handle: GLuint, uniform: GL_Shader_Uniform_Variable, value: s32) {
    gl_vuc := get_configuration(uniform);
    uniform_location := glGetUniformLocation(shader_program_gl_handle, temp_c_string(gl_vuc.var_name_in_shader));
    glUniform1i(uniform_location, value);
}

set_uniform :: (shader_program_gl_handle: GLuint, uniform: GL_Shader_Uniform_Variable, value: u32) {
    gl_vuc := get_configuration(uniform);
    uniform_location := glGetUniformLocation(shader_program_gl_handle, temp_c_string(gl_vuc.var_name_in_shader));
    glUniform1ui(uniform_location, value);
}

set_uniform :: (shader_program_gl_handle: GLuint, uniform: GL_Shader_Uniform_Variable, value: float32) {
    gl_vuc := get_configuration(uniform);
    uniform_location := glGetUniformLocation(shader_program_gl_handle, temp_c_string(gl_vuc.var_name_in_shader));
    glUniform1f(uniform_location, value);
}

set_uniform :: (shader_program_gl_handle: GLuint, uniform: GL_Shader_Uniform_Variable, v: Vector3) {
    gl_vuc := get_configuration(uniform);
    uniform_location := glGetUniformLocation(shader_program_gl_handle, temp_c_string(gl_vuc.var_name_in_shader));
    glUniform3f(uniform_location, v.x, v.y, v.z);
}

set_uniform :: (shader_program_gl_handle: GLuint, uniform: GL_Shader_Uniform_Variable, v: Vector4) {
    gl_vuc := get_configuration(uniform);
    uniform_location := glGetUniformLocation(shader_program_gl_handle, temp_c_string(gl_vuc.var_name_in_shader));
    glUniform4f(uniform_location, v.x, v.y, v.z, v.w);
}

set_uniform :: (shader_program_gl_handle: GLuint, uniform: GL_Shader_Uniform_Variable, m: Matrix3) {
    gl_vuc := get_configuration(uniform);
    row_major := GL_TRUE;
    num_matrices_we_are_updating: u32 = 1;
    uniform_location := glGetUniformLocation(shader_program_gl_handle, temp_c_string(gl_vuc.var_name_in_shader));
    glUniformMatrix3fv(uniform_location, num_matrices_we_are_updating, row_major, *m.coef[0][0]);
}

set_uniform :: (shader_program_gl_handle: GLuint, uniform: GL_Shader_Uniform_Variable, value: bool) {
    gl_vuc := get_configuration(uniform);
    uniform_location := glGetUniformLocation(shader_program_gl_handle, temp_c_string(gl_vuc.var_name_in_shader));
    glUniform1i(uniform_location, cast(s32) ifx value then 1 else 0);
}

set_uniform :: (shader_program_gl_handle: GLuint, uniform: GL_Shader_Uniform_Variable, x: s32, y: s32) {
    gl_vuc := get_configuration(uniform);
    uniform_location := glGetUniformLocation(shader_program_gl_handle, temp_c_string(gl_vuc.var_name_in_shader));
    glUniform2i(uniform_location, x, y);
}

set_uniform :: (shader_program_gl_handle: GLuint, uniform: GL_Shader_Uniform_Variable, x: s32, y: s32, z: s32) {
    gl_vuc := get_configuration(uniform);
    uniform_location := glGetUniformLocation(shader_program_gl_handle, temp_c_string(gl_vuc.var_name_in_shader));
    glUniform3i(uniform_location, x, y, z);
}

set_uniform :: (shader_program_gl_handle: GLuint, uniform: GL_Shader_Uniform_Variable, x: s32, y: s32, z: s32, w: s32) {
    gl_vuc := get_configuration(uniform);
    uniform_location := glGetUniformLocation(shader_program_gl_handle, temp_c_string(gl_vuc.var_name_in_shader));
    glUniform4i(uniform_location, x, y, z, w);
}

GL_Vertex_Uniform_Configuration :: struct { // (i don't give a) gl_vuc 

    type_in_jai: Type;

    var_name_in_shader : string;

    // plural_name : string; don't think I need this for uniforms??
}


// this defines the allowed attribute variables that our shaders can have.
GL_Shader_Vertex_Attribute_Variable :: enum u32 { // gl_sav
    POSITION;
    LOCAL_TO_WORLD_INDEX;

    // common passthroughs for fragment shader
    PASSTHROUGH_RGB_COLOR;
    PASSTHROUGH_NORMAL;

    // used for texture packing
    PASSTHROUGH_PACKED_TEXTURE_INDEX;
    PASSTHROUGH_TEXTURE_COORDINATE;
    PASSTHROUGH_PACKED_TEXTURE_BOUNDING_BOX_INDEX;
    
}

GL_Shader_Uniform_Variable :: enum u32 { // gl_suv
    // things with a camera
    WORLD_TO_CAMERA;
    CAMERA_TO_CLIP;

    // used in 2d situations sometimes
    ASPECT_RATIO;

    // used for texture packing
    PACKED_TEXTURES;
    PACKED_TEXTURE_BOUNDING_BOXES;

    // used in deferred rendering
    POSITION_TEXTURE;
    COLOR_TEXTURE;
    NORMAL_TEXTURE;

    CAMERA_POSITION; // common in lighting situations
    LIGHTS;
}

// this stuff should probably go elsewhere
get_configuration :: (attr: GL_Shader_Vertex_Attribute_Variable) -> GL_Vertex_Attribute_Configuration {
    if #complete attr == {
        case .POSITION;
            return .{
                type_in_jai                     = Vector3,
                var_name_in_shader              = "position",
                plural_name                     = "positions",
                argument_name_in_buffer_object  = "positions",
                constant_across_object          = false,
                components_per_vertex           = 3,
                data_type_of_component          = GL_FLOAT,
                normalize                       = GL_FALSE,
                stride                          = 0,
                pointer_offset_to_start_of_data = null,
            };
        case .PASSTHROUGH_RGB_COLOR;
            return .{
                type_in_jai                     = Vector3,
                var_name_in_shader              = "passthrough_rgb_color",
                plural_name                     = "passthrough_rgb_colors",
                argument_name_in_buffer_object  = "rgb_colors",
                constant_across_object          = false,
                components_per_vertex           = 3,
                data_type_of_component          = GL_FLOAT,
                normalize                       = GL_FALSE,
                stride                          = 0,
                pointer_offset_to_start_of_data = null,
                passthrough              = true,
            };
        case .PASSTHROUGH_NORMAL;
            return .{
                type_in_jai                     = Vector3,
                var_name_in_shader              = "passthrough_normal",
                plural_name                     = "passthrough_normals",
                argument_name_in_buffer_object  = "normals",
                constant_across_object          = false,
                components_per_vertex           = 3,
                data_type_of_component          = GL_FLOAT,
                normalize                       = GL_FALSE,
                stride                          = 0,
                pointer_offset_to_start_of_data = null,
                passthrough              = true,
            };
        case .LOCAL_TO_WORLD_INDEX;
            return .{
                type_in_jai                     = u32,
                var_name_in_shader              = "local_to_world_index",
                plural_name                     = "local_to_world_indices",
                argument_name_in_buffer_object  = "local_to_world_index",
                constant_across_object          = true,
                components_per_vertex           = 1,
                data_type_of_component          = GL_UNSIGNED_INT,
                normalize                       = GL_FALSE,
                stride                          = 0,
                pointer_offset_to_start_of_data = null,
            };
        case .PASSTHROUGH_PACKED_TEXTURE_INDEX;
            return .{
                type_in_jai                     = int,
                var_name_in_shader              = "passthrough_packed_texture_index",
                plural_name                     = "passthrough_packed_texture_indices",
                argument_name_in_buffer_object  = "packed_texture_index",
                constant_across_object          = true,
                components_per_vertex           = 1,
                data_type_of_component          = GL_INT,
                normalize                       = GL_FALSE,
                stride                          = 0,
                pointer_offset_to_start_of_data = null,
            };
        case .PASSTHROUGH_TEXTURE_COORDINATE;
            return .{
                type_in_jai                     = Vector2,
                var_name_in_shader              = "passthrough_texture_coordinate",
                plural_name                     = "passthrough_texture_coordinates",
                argument_name_in_buffer_object  = "texture_coordinates",
                constant_across_object          = false,
                components_per_vertex           = 2,
                data_type_of_component          = GL_FLOAT,
                normalize                       = GL_FALSE,
                stride                          = 0,
                pointer_offset_to_start_of_data = null,
            };
        case .PASSTHROUGH_PACKED_TEXTURE_BOUNDING_BOX_INDEX;
            return .{
                type_in_jai                     = int,
                var_name_in_shader              = "passthrough_packed_texture_bounding_box_index",
                plural_name                     = "passthrough_packed_texture_bounding_box_indices",
                argument_name_in_buffer_object  = "packed_texture_bounding_box_index",
                constant_across_object          = true,
                components_per_vertex           = 1,
                data_type_of_component          = GL_INT,
                normalize                       = GL_FALSE,
                stride                          = 0,
                pointer_offset_to_start_of_data = null,
            };
    }
}

get_configuration :: (uniform: GL_Shader_Uniform_Variable) -> GL_Vertex_Uniform_Configuration {
    if #complete uniform == {
        case .WORLD_TO_CAMERA;
            return .{ type_in_jai = Matrix4, var_name_in_shader = "world_to_camera" };
        case .CAMERA_TO_CLIP;
            return .{ type_in_jai = Matrix4, var_name_in_shader = "camera_to_clip" };
        case .PACKED_TEXTURES;
            return .{ type_in_jai = s32, var_name_in_shader = "packed_textures" };
        case .PACKED_TEXTURE_BOUNDING_BOXES;
            return .{ type_in_jai = s32, var_name_in_shader = "packed_texture_bounding_boxes" };
        case .ASPECT_RATIO;
            return .{ type_in_jai = Vector2, var_name_in_shader = "aspect_ratio" };
        case .POSITION_TEXTURE;
            return .{ type_in_jai = s32, var_name_in_shader = "position_texture" };
        case .COLOR_TEXTURE;
            return .{ type_in_jai = s32, var_name_in_shader = "color_texture" };
        case .NORMAL_TEXTURE;
            return .{ type_in_jai = s32, var_name_in_shader = "normal_texture" };
        case .CAMERA_POSITION;
            return .{ type_in_jai = Vector3, var_name_in_shader = "camera_position" };
        case .LIGHTS;
            // todo the type is a list of lights or something.
            return .{ type_in_jai = int, var_name_in_shader = "camera_position" };
    }
}

generate_code_for_uniform_setter_function :: (shader : Shader_Metadata, uniform : GL_Shader_Uniform_Variable) -> string {
    unif_conf := get_configuration(uniform);
    return tprint(#string END

set_%1_uniform :: (renderer : *%2, v: %3) {
    // note, if this doesn't work we might have to use the shader program first.
    set_uniform(renderer.shader_program_gl_handle, .%4, v);
}
    END, 
    to_lower_copy(tprint("%", uniform)), // the context uses temp, so not mallocing
    get_renderer_struct_name(shader), 
    unif_conf.type_in_jai, 
    uniform
    );
}

generate_code_for_uniform_setter_functions :: (shader : Shader_Metadata) -> string {
    push_allocator(temp);
    builder : String_Builder;

    for shader.uniforms {
        print_to_builder(*builder, generate_code_for_uniform_setter_function(shader, it));
    }
    return builder_to_string(*builder); 
}


init_vertex_attribute :: (
        shader_program_gl_handle : GLuint, 
        vertex_attribute_array_gl_handle: GLuint, 
        attribute_buffer_gl_handle: GLuint, 
        attribute: GL_Shader_Vertex_Attribute_Variable
    ) {

    using glvac := get_configuration(attribute);

    glBindVertexArray(vertex_attribute_array_gl_handle);
    glBindBuffer(GL_ARRAY_BUFFER, attribute_buffer_gl_handle);

    log("%", var_name_in_shader);
    vertex_attribute_gl_handle : s32 = glGetAttribLocation(shader_program_gl_handle, temp_c_string(var_name_in_shader));

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

/*
This is a thing that allows us to render a bunch of things in a game, each of which are their "own object", and can be 
moved independently in space.

Instead of doing the per object vbo, ibo, vao approach, instead we just make a single grouping of that, which holds everything.

When you create an object, it is usually an itp-like (indexed triangle positions), and its indices use values from 0 to k. 

In this system we'll be holding tons of objects, and so if each object used their own local 0 to k indices, then the rendering would
fall off the rails due to overlapping indices, instead what happens here is that we have a huge index array, inside this array we know which ones are occupied and which are free.

Therefore we can think about an object in this system as something that holds a collection of global indices into the huge buffer

We take an itp and find enough contiguous space to store it, and then store its "global indices", which might be j to j + k.

*/
// note that positions are assumed to be part of this because you can't really do anything without positions in rendering
// note: this allocates big buffers and then all objects are put into these buffers, there is no "per object vbo,ibo,vao" thing going on here.

/*
 this is a "base renderer" struct that you can compose into other structs to make real renderers.
 this models the idea that in opengl you can only render something with a particular shader
 this means that the number of draw calls you need to render a scene is at least the number of 
 shaders required to render the scene, this might be a reason why people make mega shaders.
*/
Per_Shader_Renderer :: struct { // this should be called a per object shader renderer or something better.

    max_num_elements_in_each_buffer : u32 = 100000;  // default value until everything is meta programmed away.

    shader_program_gl_handle: GLuint;

    vertex_attribute_array_gl_handle : GLuint;


    // when you use glDrawElements, it takes from the active GL_ELEMENT_ARRAY_BUFFER
    // therefore when we want to render objects, we need to buffer the correct global indices into this 
    // the size of this index buffer could actually technically be larger than max_num_elements_in_each_buffer 
    // this is because a regular quad has 4 positions, but 6 indices, so indices.count >= positions.count
    index_buffer_gl_handle : GLuint;

    object_indices_to_render_this_frame : [..] u32;
    object_indices_we_rendered_last_frame : [..] u32;

    // this is how we manage the memory in all the attribute buffers and index buffer
    first_fit_virtual_allocator : First_Fit_Virtual_Allocator;

    // should this be a map of id to array views?
    buffered_object_index_to_global_indices: Table(u32, [..] u32);
}

init :: (psr : *Per_Shader_Renderer, vertex_shader_source : string, fragment_shader_source : string, max_num_elements_in_each_buffer : u32) {

    shader_program_handle, success := create_shader_program(vertex_shader_source, fragment_shader_source);
    max_num_elements_in_each_buffer = max_num_elements_in_each_buffer;

	if !success
        log("shader compilation failed");
		// return false;
    if success 
        log("shader compilation succeeded");

    psr.shader_program_gl_handle = shader_program_handle;

    psr.first_fit_virtual_allocator.size = max_num_elements_in_each_buffer;
}

queue_render :: (using psr : *Per_Shader_Renderer, object_index : u32) { 

    // todo do a check to see if it exists first right? through the virtual allocator
   
   array_add(*object_indices_to_render_this_frame, object_index);

   // add it to the per frame thing, which gets emptied when rendering.
}

render :: (using psr : *Per_Shader_Renderer) {

    glUseProgram(shader_program_gl_handle);

    glBindVertexArray(vertex_attribute_array_gl_handle);
    // todo: reserve so we don't get a ton of reallocations in this for loop
    geom_indices_to_render : [..] u32; 
    // array_reserve(*geom_indices_to_render, ???); // needs some running count whenever we buffer an obj.
    for object_indices_to_render_this_frame {
        geom_indices , success := table_find(*buffered_object_index_to_global_indices, it);
        if !success log("couldn't find the global indices of object with id: %", it);
        for geom_indices 
            array_add(*geom_indices_to_render, it);
    }


    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index_buffer_gl_handle);
    // here we're just overwriting the buffer on each draw call, if there's less data written than last iteration it's fine
    // as we will only access the smaller portion
    glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, 0, geom_indices_to_render.count * size_of(u32), geom_indices_to_render.data);

    glDrawElements(GL_TRIANGLES, xx geom_indices_to_render.count, GL_UNSIGNED_INT, cast (*void) 0);

    // the rendering the same objects test as last frame test is a worthwhile optimization that should occur.

    array_reset(*object_indices_to_render_this_frame);

    glBindVertexArray(0);
    glUseProgram(0);
}

unbuffer_object :: (using psr: *Per_Shader_Renderer, object_index: u32) {

    // note that we don't actually have to unbuffer it from the gpu arrays, we just have to make "free" in the sense that
    // now other people can use that place in the metadata that keeps up with ownership

    // todo: we should keep a list of what's used for the local to world indices, as of right now it literally just increments
    // the value by 1 every time, and that keeps it safe, in shaders that have local to world matrices, then we need to 
    // create a custom unbuffer object, this unbuffer object function needs to additionally free up local to world matrices, which we don't do here.

    virtual_free(*first_fit_virtual_allocator, object_index);

    global_indices, found := table_find(*buffered_object_index_to_global_indices, object_index);
    if found {
        array_free(global_indices);
        table_remove(*buffered_object_index_to_global_indices, object_index);
    } else {
        log("unbuffer_object: couldn't find global indices for object_index %", object_index);
    }

    for object_indices_to_render_this_frame {
        if it == object_index {
            remove it;
            break;
        }
    }
}
