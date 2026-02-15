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
    attributes : [] GL_Vertex_Attribute_Configuration;
    uniforms   : [] GL_Shader_Uniform_Variable;

    per_object_transforms : bool;

    vertex_shader_source : string;
    fragment_shader_source : string;
}

ABSOLUTE_POSITION_COLOR_SHADER :: Shader_Metadata.{
    "Absolute_Position_Color", 
    .[POSITION_GL_VAC, PASSTHROUGH_RGB_COLOR_GL_VAC],
    .[],
    false,
    ABSOLUTE_POSITION_COLOR_VERTEX_SHADER,
    COLOR_FRAGMENT_SHADER
};

jai_struct_attributes_for_gl_vertex_attribute_handles :: (gsavs: [] GL_Vertex_Attribute_Configuration) -> string {
    push_allocator(temp); // everything in this function is temp storage, yay!

    builder: String_Builder;
    init_string_builder(*builder); 

    for gsavs {
        print_to_builder(*builder, "    %_buffer_gl_handle: GLuint;\n", it.var_name_in_shader);
    }

    return builder_to_string(*builder);
}

jai_renderer_struct_for_given_shader :: (s : Shader_Metadata) -> string {

    return tprint(#string END

Per_Object_%1_Renderer :: struct {
    using #as psr : Per_Shader_Renderer;

%2
}

    END, s.name, jai_struct_attributes_for_gl_vertex_attribute_handles(s.attributes));
}

// jai_init_buffers_no_data :: () {
//     return tprint(#string END
// 
// 
// init_buffers_no_data :: (using apcr : *Per_Object_Absolute_Position_Color_Renderer) {
// 
//     glGenVertexArrays(1, *vertex_attribute_array_gl_handle);
//     glBindVertexArray(vertex_attribute_array_gl_handle);
// 
//     glGenBuffers(1, *index_buffer_gl_handle);
//     glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index_buffer_gl_handle);
//     // NOTE: it's probably wrong to use  MAX_NUM_ELEMENTS_IN_EACH_BUFFER because as noted before the number of indices
//     // could be larger than this value if we try and render all objects, but we won't care about that until it's a problem.
//     glBufferData(GL_ELEMENT_ARRAY_BUFFER, size_of(u32) *  MAX_NUM_ELEMENTS_IN_EACH_BUFFER, null, GL_DYNAMIC_DRAW);
//     // note: we don't have to init the vertex attribute for indices because they used in the shader program for rendering, they're just used during glDrawElements.
// 
//     // this should be meta programmed away, by iterating over a vector of GL_VAC's and #inserting the code here.
// 
//     %
// 
//     // todo I was right here and I was trying to do the init vertex attribute but there's a problem because it needs the POSITION_GL_VAC
// 
//     #insert #run opengl_code_to_generate_a_buffer_for_a_vertex_attribute(POSITION_GL_VAC);
//     init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, position_buffer_gl_handle, POSITION_GL_VAC);
// 
//     #insert #run opengl_code_to_generate_a_buffer_for_a_vertex_attribute(PASSTHROUGH_RGB_COLOR_GL_VAC);
//     init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, passthrough_rgb_color_buffer_gl_handle, PASSTHROUGH_RGB_COLOR_GL_VAC);
// 
// 	glBindBuffer (GL_ARRAY_BUFFER, 0);
// }
// 
//     END
// }
// 
// jai_code_to_setup_empty_opengl_vertex_attribute_buffer :: () {
// }



#run log("%", jai_renderer_struct_for_given_shader(ABSOLUTE_POSITION_COLOR_SHADER));


/*
for each attribute, we need to create those buffers and set them up as in the absolute one (create init_buffers_no_data)
for each uniform, we need to generate a concrete function that binds the value.
then we also need the specific buffer_object function
then we also need the render function.
it also creates a struct which is a blah renderable struct which we can use.

all this goes into it's own file and it's called like a blah renderer or something
*/

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
set_uniform :: (shader_program_gl_handle: GLuint, gl_vuc: GL_Vertex_Uniform_Configuration, m: Matrix4) {
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
GL_Shader_Attribute_Variable :: enum u32 { // gl_sav
    POSITION;

    PASSTHROUGH_RGB_COLOR;
    RGB_COLOR;
}

GL_Shader_Uniform_Variable :: enum u32 { // gl_suv
    WORLD_TO_CAMERA;
    CAMERA_TO_CLIP;
}

POSITION_GL_VAC :: GL_Vertex_Attribute_Configuration.{
    Vector3, "position", "positions", 3, GL_FLOAT, GL_FALSE, 0, cast (*void) 0, false
};

PASSTHROUGH_RGB_COLOR_GL_VAC :: GL_Vertex_Attribute_Configuration.{
    Vector3, "passthrough_rgb_color", "colors", 3, GL_FLOAT, GL_FALSE, 0, cast (*void) 0, true
};

LOCAL_TO_WORLD_INDEX_GL_VAC :: GL_Vertex_Attribute_Configuration.{
    u32, "local_to_world_index", "local_to_world_indices", 1,  GL_UNSIGNED_INT, GL_FALSE, 0, cast (* void) 0, false
};

WORLD_TO_CAMERA_GL_VUC :: GL_Vertex_Uniform_Configuration.{
    Matrix4,
    "world_to_camera"
};

// autogenerate this in the future, fine for now.
set_world_to_camera_uniform :: (shader_program_gl_handle : GLuint,m : Matrix4) {
    set_uniform(shader_program_gl_handle, WORLD_TO_CAMERA_GL_VUC, m);
}

CAMERA_TO_CLIP_GL_VUC :: GL_Vertex_Uniform_Configuration.{
    Matrix4,
    "camera_to_clip"
};

// autogenerate this in the future, fine for now.
set_camera_to_clip_uniform :: (shader_program_gl_handle : GLuint,m : Matrix4) {
    set_uniform(shader_program_gl_handle, CAMERA_TO_CLIP_GL_VUC, m);
}

init_vertex_attribute :: (
        shader_program_gl_handle : GLuint, 
        vertex_attribute_array_gl_handle: GLuint, 
        attribute_buffer_gl_handle: GLuint, 
        using glvac : GL_Vertex_Attribute_Configuration
    ) {

    glBindVertexArray(vertex_attribute_array_gl_handle);
    glBindBuffer(GL_ARRAY_BUFFER, attribute_buffer_gl_handle);

    // s := temp_c_string(var_name_in_shader);
    x := glGetAttribLocation(shader_program_gl_handle, temp_c_string(var_name_in_shader));

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

// glUniformMatrix4fv(glGetUniformLocation(per_object_transform_renderer.shader_program_gl_handle, "world_to_camera"), num_matrices_we_are_updating, row_major, *camera.world_to_camera.coef[0][0]);

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
