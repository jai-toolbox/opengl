#import "String";
#import "File";

/*

I want the following:
- We define what are valid shader variable names, and their types, this is so when we create new shaders we can interact with them the same way across different shaders.
- Given a shader, we can generate a renderer for that shader, this automatically sets up a shader

*/

// TODO: this is unused so far, but it would be eventually generated per vertex/fragmnt shader pair and used to fill out this struct
// we can also meta program this out to make a renderer for the shader program which does the big buffer soa approach.
Shader_Metadata :: struct { // call this Shader_Metadata?

    name : string;

    // we use array views here because if we use dynamic arrays then 
    // we cannot fill them in at compile time, this makes them act like string literals in that way.
    attributes : [] GL_Shader_Vertex_Attribute_Variable;
    uniforms   : [] GL_Shader_Uniform_Variable;

    per_object_transforms : bool;

    vertex_shader_source : string;
    fragment_shader_source : string;
}

get_renderer_struct_name :: (shader : Shader_Metadata) -> string {
    return tprint("Per_Object_%1_Renderer", shader.name);
}

ABSOLUTE_POSITION_COLOR_SHADER :: Shader_Metadata.{
    "Absolute_Position_Color", 
    .[.POSITION, .PASSTHROUGH_RGB_COLOR],
    .[],
    false,
    ABSOLUTE_POSITION_COLOR_VERTEX_SHADER,
    COLOR_FRAGMENT_SHADER
};

#run create_code_to_render_stuff_with_shader(ABSOLUTE_POSITION_COLOR_SHADER);

create_code_to_render_stuff_with_shader :: (shader: Shader_Metadata) {
    push_allocator(temp);

    builder: String_Builder;
    init_string_builder(*builder);

    // File header
    print_to_builder(*builder, "// Auto-generated renderer for shader: %\n", shader.name);
    print_to_builder(*builder, "// Do not edit manually.\n\n");

    append(*builder, generate_renderer_struct_for_given_shader(shader));
    append(*builder, generate_init_buffers_no_data(shader));
    append(*builder, generate_buffer_object(shader));

    output := builder_to_string(*builder);

    filename := tprint("%/%_renderer.jai", #filepath, to_lower_copy(shader.name));

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

generate_renderer_struct_for_given_shader :: (s : Shader_Metadata) -> string {

    return tprint(#string END

%1 :: struct {
    using #as psr : Per_Shader_Renderer;

%2
}

    END, get_renderer_struct_name(s), jai_struct_attributes_for_gl_vertex_attribute_handles(s.attributes));
}

generate_attribute_setup_code :: (attributes: [] GL_Shader_Vertex_Attribute_Variable) -> string {
    push_allocator(temp);
    builder: String_Builder;

    for attr: attributes {
        glvac := get_configuration(attr);

        print_to_builder(*builder,
            "    generate_a_buffer_for_a_vertex_attribute(%_buffer_gl_handle, %, MAX_NUM_ELEMENTS_IN_EACH_BUFFER);\n",
            glvac.plural_name, glvac.type_in_jai
        );

        print_to_builder(*builder,
            "    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, %_buffer_gl_handle, .%);\n\n",
            glvac.plural_name, attr
        );
    }

    return builder_to_string(*builder);
}

generate_init_buffers_no_data :: (shader : Shader_Metadata) -> string {
    return tprint(#string END


init_buffers_no_data :: (using apcr : *Per_Object_Absolute_Position_Color_Renderer) { // todo change renderer name

    glGenVertexArrays(1, *vertex_attribute_array_gl_handle);
    glBindVertexArray(vertex_attribute_array_gl_handle);

    glGenBuffers(1, *index_buffer_gl_handle);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index_buffer_gl_handle);
    // NOTE: it's probably wrong to use  MAX_NUM_ELEMENTS_IN_EACH_BUFFER because as noted before the number of indices
    // could be larger than this value if we try and render all objects, but we won't care about that until it's a problem.
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, size_of(u32) *  MAX_NUM_ELEMENTS_IN_EACH_BUFFER, null, GL_DYNAMIC_DRAW);
    // note: we don't have to init the vertex attribute for indices because they used in the shader program for rendering, they're just used during glDrawElements.

%1

	glBindBuffer (GL_ARRAY_BUFFER, 0);
}

    END, generate_attribute_setup_code(shader.attributes));
}


generate_buffer_vertex_attribute_data_at_index_code :: (attribute: GL_Shader_Vertex_Attribute_Variable) -> string {
    // maybe just pass the conf then?
    attr_conf := get_configuration(attribute);
    return tprint(#string END

    glBindBuffer(GL_ARRAY_BUFFER, %1_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, index * size_of(%2), %3.count * size_of(%2), %3.data);

    END, attr_conf.plural_name, attr_conf.type_in_jai, attr_conf.argument_name_in_buffer_object);
}

generate_buffer_vertex_attributes_code :: (shader : Shader_Metadata) -> string {
    push_allocator(temp);
    builder: String_Builder;

    for shader.attributes {
        print_to_builder(*builder, "    %\n", generate_buffer_vertex_attribute_data_at_index_code(it));
    }

    return builder_to_string(*builder);
}

generate_parameter_list_for_buffer_object :: (shader : Shader_Metadata) -> string {

    push_allocator(temp);
    builder: String_Builder;


    for shader.attributes {
        attr_conf := get_configuration(it);
        print_to_builder(*builder, "        % : [..] %\n", attr_conf.argument_name_in_buffer_object, attr_conf.type_in_jai); 
    }

    return tprint(#string END
        using renderer: *%1,
        indices : [..] u32,
%2
    END, get_renderer_struct_name(shader), builder_to_string(*builder));
}


generate_buffer_object :: (shader : Shader_Metadata) -> string {

    return tprint(#string END
// todo ability to specify the transform matrix upon buffering?
buffer_object :: (
%1
        ) -> object_index: u32, local_to_world_index: u32, success: bool {

    // note: we use the positions as count, becaues that is the actual data that needs to be in the buffer
    // the indices use duplicates sometimes to refer to the same vertex multiple times.
    length := positions.count; // TODO: need to metaprogram this out, but it's pretty safe for now.
    index, success := virtual_alloc(*first_fit_virtual_allocator, xx length);
    if !success {
        log("ran out of virtual memory");
        return 0, 0, false;
    }

    global_indices_for_object : [..] u32;
    for indices 
        array_add(*global_indices_for_object, xx index + it);

    table_add(*buffered_object_index_to_global_indices, xx index, global_indices_for_object);

    glBindVertexArray(vertex_attribute_array_gl_handle);

%2

    // glBindBuffer(GL_ARRAY_BUFFER, position_buffer_gl_handle);
    // glBufferSubData(GL_ARRAY_BUFFER, index * size_of(Vector3), positions.count * size_of(Vector3), positions.data);

    // glBindBuffer(GL_ARRAY_BUFFER, color_buffer_gl_handle);
    // glBufferSubData(GL_ARRAY_BUFFER, index * size_of(Vector3), colors.count * size_of(Vector3), colors.data);

    // later on we only need to do local to world indices if the shader uses per object transforms.

    // local_to_world_indices are an array of the same value which is the local to world index
    // the alternative to this is binding the uniform per object, which we're trying to avoid because we want to render
    // everything at once in one big draw call.

    local_to_world_indices: [..] u32;
    for 0..positions.count array_add(*local_to_world_indices, current_local_to_world_index);

    ltw_index_we_used := current_local_to_world_index;
    current_local_to_world_index += 1;

    glBindBuffer(GL_ARRAY_BUFFER, local_to_world_index_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, index * size_of(u32), local_to_world_indices.count * size_of(u32), local_to_world_indices.data);

    glBindVertexArray(0);

    return index, ltw_index_we_used, true;
}
    END, generate_parameter_list_for_buffer_object(shader), generate_buffer_vertex_attributes_code(shader) );

}

// TODO: I was about to add in generate_render, and we'll just copy the render code, but add in specific things

generate_buffer_for_vertex_attribute :: (attribute_buffer_gl_handle : *GLuint, $attribute_type : Type, num_elements: u32) {
    glGenBuffers(1, attribute_buffer_gl_handle);
    glBindBuffer(GL_ARRAY_BUFFER, attribute_buffer_gl_handle.*);
    glBufferData(GL_ARRAY_BUFFER, size_of(attribute_type) * num_elements, null, GL_DYNAMIC_DRAW);
}

opengl_code_to_generate_a_buffer_for_a_vertex_attribute :: (gl_vac : GL_Vertex_Attribute_Configuration) -> string {
    return sprint(#string END

    glGenBuffers(1, *%1_buffer_gl_handle);
    glBindBuffer(GL_ARRAY_BUFFER, %1_buffer_gl_handle);
    glBufferData(GL_ARRAY_BUFFER, size_of(%2) * MAX_NUM_ELEMENTS_IN_EACH_BUFFER, null, GL_DYNAMIC_DRAW);

    END, gl_vac.var_name_in_shader, gl_vac.type_in_jai);
}

// todo I want to actually do these functions and then automate the passing of parameters, much better.

// generate_buffer_for_vertex_attribute

// to be used in buffer object
opengl_code_to_buffer_vertex_attribute_data_at_index :: (gl_vac : GL_Vertex_Attribute_Configuration) -> string {
    return sprint(#string END

    glBindBuffer(GL_ARRAY_BUFFER, %1_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, index * size_of(%2), %3.count * size_of(%2), %3.data);

    END, gl_vac.var_name_in_shader, gl_vac.type_in_jai, gl_vac.plural_name);
}


GL_Vertex_Attribute_Configuration :: struct { // gl_vac

    type_in_jai: Type;

    var_name_in_shader : string;

    // this is actually what we call something in the code or something.
    plural_name : string;

    argument_name_in_buffer_object : string;

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

// you have to bind the program before calling this, should we do this ourselves? idk yet.
set_uniform :: (shader_program_gl_handle: GLuint, uniform:  GL_Shader_Uniform_Variable , m: Matrix4) {
    gl_vuc := get_configuration(uniform);
    row_major := GL_TRUE;
    num_matrices_we_are_updating: u32 = 1;

    uniform_location := glGetUniformLocation(shader_program_gl_handle, temp_c_string(gl_vuc.var_name_in_shader));

    glUniformMatrix4fv(uniform_location, num_matrices_we_are_updating, row_major, *m.coef[0][0]);
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
    PASSTHROUGH_RGB_COLOR;
}

GL_Shader_Uniform_Variable :: enum u32 { // gl_suv
    WORLD_TO_CAMERA;
    CAMERA_TO_CLIP;
}

get_configuration :: (attr: GL_Shader_Vertex_Attribute_Variable) -> GL_Vertex_Attribute_Configuration {
    if #complete attr == {
        case .POSITION;
            return .{
                type_in_jai              = Vector3,
                var_name_in_shader       = "position",
                plural_name              = "positions",
                argument_name_in_buffer_object = "positions",
                components_per_vertex    = 3,
                data_type_of_component   = GL_FLOAT,
                normalize                = GL_FALSE,
                stride                   = 0,
                pointer_offset_to_start_of_data = null,
            };
        case .PASSTHROUGH_RGB_COLOR;
            return .{
                type_in_jai              = Vector3,
                var_name_in_shader       = "passthrough_rgb_color",
                plural_name              = "passthrough_rgb_colors",
                argument_name_in_buffer_object = "rgb_colors",
                components_per_vertex    = 3,
                data_type_of_component   = GL_FLOAT,
                normalize                = GL_FALSE,
                stride                   = 0,
                pointer_offset_to_start_of_data = null,
                passthrough              = true,
            };
        case .LOCAL_TO_WORLD_INDEX;
            return .{
                type_in_jai              = u32,
                var_name_in_shader       = "local_to_world_index",
                plural_name              = "local_to_world_indices",
                argument_name_in_buffer_object = "local_to_world_index",
                components_per_vertex    = 1,
                data_type_of_component   = GL_UNSIGNED_INT,
                normalize                = GL_FALSE,
                stride                   = 0,
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
    }
}

// autogenerate this in the future, fine for now.
set_world_to_camera_uniform :: (shader_program_gl_handle : GLuint,m : Matrix4) {
    set_uniform(shader_program_gl_handle, .WORLD_TO_CAMERA, m);
}

// autogenerate this in the future, fine for now.
set_camera_to_clip_uniform :: (shader_program_gl_handle : GLuint,m : Matrix4) {
    set_uniform(shader_program_gl_handle, .CAMERA_TO_CLIP, m);
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
//
// 

/*
 this is a "base renderer" struct that you can compose into other structs to make real renderers.
 this models the idea that in opengl you can only render something with a particular shader
 this means that the number of draw calls you need to render a scene is at least the number of 
 shaders required to render the scene, this might be a reason why people make mega shaders.
*/
Per_Shader_Renderer :: struct { // this should be called a per object shader renderer or something better.

    MAX_NUM_ELEMENTS_IN_EACH_BUFFER : u32 = 100000;

    shader_program_gl_handle: GLuint;

    vertex_attribute_array_gl_handle : GLuint;


    // when you use glDrawElements, it takes from the active GL_ELEMENT_ARRAY_BUFFER
    // therefore when we want to render objects, we need to buffer the correct global indices into this 
    // the size of this index buffer could actually technically be larger than MAX_NUM_ELEMENTS_IN_EACH_BUFFER 
    // this is because a regular quad has 4 positions, but 6 indices, so indices.count >= positions.count
    index_buffer_gl_handle : GLuint;

    object_indices_to_render_this_frame : [..] u32;
    object_indices_we_rendered_last_frame : [..] u32;

    // this is how we manage the memory in all the attribute buffers and index buffer
    first_fit_virtual_allocator : First_Fit_Virtual_Allocator;

    // should this be a map of id to array views?
    buffered_object_index_to_global_indices: Table(u32, [..] u32);
}
