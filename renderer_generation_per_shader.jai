/*

I want the following:
- We define what are valid shader variable names, and their types, this is so when we create new shaders we can interact with them the same way across different shaders.
- Given a shader, we can generate a renderer for that shader, this automatically sets up a shader

*/

// TODO: this is unused so far, but it would be eventually generated per vertex/fragmnt shader pair and used to fill out this struct
// we can also meta program this out to make a renderer for the shader program which does the big buffer soa approach.
Shader :: struct { // call this Shader_Metadata?

    attributes : [..] GL_Shader_Attribute_Variable;
    uniforms   : [..] GL_Shader_Uniform_Variable;

    per_object_transforms : bool;

    vertex_shader_source : string;
    fragment_shader_source : string;
}


/*
for each attribute, we need to create those buffers and set them up as in the absolute one (create init_buffers_no_data)
for each uniform, we need to generate a concrete function that binds the value.
then we also need the specific buffer_object function
then we also need the render function.
it also creates a struct which is a blah renderable struct which we can use.

all this goes into it's own file and it's called like a blah renderer or something
*/

GL_Vertex_Attribute_Configuration :: struct { // gl_vac

    var_name_in_shader : string;

    components_per_vertex: GLint;
    data_type_of_component: GLenum;
    normalize : GLboolean;
    stride : GLsizei ;
    pointer_offset_to_start_of_data : *void;
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

POSITION_GL_VAC :: GL_Vertex_Attribute_Configuration.{"position", 3, GL_FLOAT, GL_FALSE, 0, cast (*void) 0};
PASSTHROUGH_RGB_COLOR_GL_VAC :: GL_Vertex_Attribute_Configuration.{"passthrough_rgb_color", 3, GL_FLOAT, GL_FALSE, 0, cast (*void) 0};
LOCAL_TO_WORLD_INDEX_GL_VAC :: GL_Vertex_Attribute_Configuration.{"local_to_world_index", 1,  GL_UNSIGNED_INT, GL_FALSE, 0, cast (* void) 0};

init_vertex_attribute :: (
        shader_program_gl_handle : GLuint, 
        vertex_attribute_array_gl_handle: GLuint, 
        attribute_buffer_gl_handle: GLuint, 
        using glvac : GL_Vertex_Attribute_Configuration
    ) {

    glBindVertexArray(vertex_attribute_array_gl_handle);
    glBindBuffer(GL_ARRAY_BUFFER, attribute_buffer_gl_handle);

    s := temp_c_string(var_name_in_shader);
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
