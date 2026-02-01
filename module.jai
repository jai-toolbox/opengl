#import "GL";
#import "Basic";
#import "Math";

#import,file "first_fit_virtual_allocator.jai";

#import "Hash_Table";

// opengl's coordinate system is only NDC space, everything else is something that you make up
// and ndc space we have the following, the misconception can be understood here:
// https://www.gingerbill.org/article/2024/11/10/opengl-is-not-right-handed/
GL_FORWARD_VEC :: Vector3.{0, 0, 1};
GL_RIGHT_VEC :: Vector3.{1, 0, 0};
GL_UP_VEC :: Vector3.{0, 1, 0};

// in the future it'd be interesting to have a way to re-map things, which would occur at the shader level so that there isn't an associated runtime cost of flipping things.

enable_wireframe_mode :: () { glPolygonMode(GL_FRONT_AND_BACK, GL_LINE); }
disable_wireframe_mode :: () { glPolygonMode(GL_FRONT_AND_BACK, GL_FILL); }

// SHADER_PREFIX : string : "#version 330 core";
SHADER_PREFIX : string : "";

/*

The optimal workflow would be that we specify what shaders we want to use and then we can generated the IVPX_Renderable struct for taht specific shader so that we only need to use the ones that we ever have to render rather than thinking about some combinatorial explosion of IVPXYZ's

*/


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

Absolute_Position_Renderer :: struct {

}

/*
 this is a "base renderer" struct that you can compose into other structs to make real renderers.
 this models the idea that in opengl you can only render something with a particular shader
 this means that the number of draw calls you need to render a scene is at least the number of 
 shaders required to render the scene, this might be a reason why people make mega shaders.
*/
Per_Shader_Renderer :: struct {

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

Per_Object_Transform_Renderer :: struct { // POTR for short said as "potter"

    using psr : Per_Shader_Renderer;

    NUM_LOCAL_TO_WORLD_MATRICES :: 1024;
    local_to_world_matrices : [NUM_LOCAL_TO_WORLD_MATRICES] Matrix4; 

    local_to_world_gl_uniform_buffer_handle : GLuint;

    position_buffer_gl_handle: GLuint;
    local_to_world_index_buffer_gl_handle : GLuint;
    color_buffer_gl_handle: GLuint; // I'm just stuffing this in here so we can render basic things and not get visually confused.
}

// don't buffer the same thing twice? I guess you can if they'res really 2 of them.
buffer_object :: (
        using potr : Per_Object_Transform_Renderer, 
        indices: [..] u32, 
        local_to_world_indices: [..] u32,
        positions: [..] Vector3, 
        colors: [..] Vector3
        ) -> object_index: u32, success: bool {

    // todo: transform matrix

    // note: we use the positions as count, becaues that is the actual data that needs to be in the buffer
    // the indices use duplicates sometimes to refer to the same vertex multiple times.
    length := positions.count;
    index, success := virtual_alloc(*first_fit_virtual_allocator, xx length);
    if (! success) {
        log("ran out of virtual memory");
        return 0, false;
    }

    global_indices_for_object : [..] u32;
    for indices 
        array_add(*global_indices_for_object, xx index + it);

    log("just added idx: % to the table", index);
    table_add(*buffered_object_index_to_global_indices, xx index, global_indices_for_object);

    glBindVertexArray(vertex_attribute_array_gl_handle);

    // this doesn't have to exist right?
    // glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index_buffer_gl_handle);
    // glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, index * size_of(u32), indices.count * size_of(u32), indices.data);

    glBindBuffer(GL_ARRAY_BUFFER, position_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, index * size_of(Vector3), positions.count * size_of(Vector3), positions.data);

    glBindBuffer(GL_ARRAY_BUFFER, color_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, index * size_of(Vector3), colors.count * size_of(Vector3), colors.data);

    glBindBuffer(GL_ARRAY_BUFFER, local_to_world_index_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, index * size_of(u32), local_to_world_indices.count * size_of(u32), local_to_world_indices.data);

    glBindVertexArray(0);

    return index, true;
}

queue_render :: (using potr : *Per_Object_Transform_Renderer, object_index : u32) { 

    // todo do a check to see if it exists first right? through the virtual allocator
   
   array_add(*object_indices_to_render_this_frame, object_index);

   // add it to the per frame thing, which gets emptied when rendering.
}

// todo maybe only draw the things we requested to draw this frame.
render :: (using potr : *Per_Object_Transform_Renderer) {

    glUseProgram(shader_program_gl_handle);

    glBindBuffer(GL_UNIFORM_BUFFER, local_to_world_gl_uniform_buffer_handle);
    glBufferData(GL_UNIFORM_BUFFER, size_of(Matrix4) * local_to_world_matrices.count, local_to_world_matrices.data, GL_DYNAMIC_DRAW);
    glBindBufferBase(GL_UNIFORM_BUFFER, 0, local_to_world_gl_uniform_buffer_handle);

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


// Colored_Positions_POTR :: struct { 
//     using Per_Object_Transform_Renderer;
//     color_buffer_gl_handle : GLuint;
// }

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

buffer_local_to_world_matrices :: (using potr : *Per_Object_Transform_Renderer) {
    glBindBuffer(GL_UNIFORM_BUFFER, local_to_world_matrices_gl_handle);
    glBufferData(GL_UNIFORM_BUFFER, NUM_LOCAL_TO_WORLD_MATRICES * size_of(Matrix4), local_to_world_matrices, GL_DYNAMIC_DRAW);
    glBindBufferBase(GL_UNIFORM_BUFFER, 0, ltw_matrices_gl_name);
}

// precond: the shader program is initialize.
// without initialization the potr has undefined behavior
init :: (using potr : *Per_Object_Transform_Renderer) { 

    for 0..NUM_LOCAL_TO_WORLD_MATRICES-1
        // this might not be necessary, doing it for now
        local_to_world_matrices[it] = Matrix4_Identity;

    first_fit_virtual_allocator.size = MAX_NUM_ELEMENTS_IN_EACH_BUFFER;

    init_buffers_no_data(potr);
}

init_buffers_no_data :: (using potr : *Per_Object_Transform_Renderer) {

    glGenVertexArrays(1, *vertex_attribute_array_gl_handle);
    glBindVertexArray(vertex_attribute_array_gl_handle);

    glGenBuffers(1, *local_to_world_gl_uniform_buffer_handle);
    glBindBuffer(GL_UNIFORM_BUFFER, local_to_world_gl_uniform_buffer_handle);
    glBufferData(GL_UNIFORM_BUFFER, local_to_world_matrices.count * size_of(Matrix4), local_to_world_matrices.data, GL_DYNAMIC_DRAW);
    glBindBufferBase(GL_UNIFORM_BUFFER, 0, local_to_world_gl_uniform_buffer_handle);

    glGenBuffers(1, *index_buffer_gl_handle);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index_buffer_gl_handle);
    // NOTE: it's probably wrong to use  MAX_NUM_ELEMENTS_IN_EACH_BUFFER because as noted before the number of indices
    // could be larger than this value if we try and render all objects, but we won't care about that until it's a problem.
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, size_of(u32) *  MAX_NUM_ELEMENTS_IN_EACH_BUFFER, null, GL_DYNAMIC_DRAW);
    // note: we don't have to init the vertex attribute for indices because they used in the shader program for rendering, they're just used during glDrawElements.


    glGenBuffers(1, *position_buffer_gl_handle);
    glBindBuffer(GL_ARRAY_BUFFER, position_buffer_gl_handle);
    glBufferData(GL_ARRAY_BUFFER, size_of(Vector3) * MAX_NUM_ELEMENTS_IN_EACH_BUFFER, null, GL_DYNAMIC_DRAW);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, position_buffer_gl_handle, POSITION_GL_VAC);

    glGenBuffers(1, *color_buffer_gl_handle);
    glBindBuffer(GL_ARRAY_BUFFER, color_buffer_gl_handle);
    glBufferData(GL_ARRAY_BUFFER, size_of(Vector3) * MAX_NUM_ELEMENTS_IN_EACH_BUFFER, null, GL_DYNAMIC_DRAW);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, color_buffer_gl_handle, PASSTHROUGH_RGB_COLOR_GL_VAC);

    glGenBuffers(1, *local_to_world_index_buffer_gl_handle);
    glBindBuffer(GL_ARRAY_BUFFER, local_to_world_index_buffer_gl_handle);
    glBufferData(GL_ARRAY_BUFFER, size_of(u32) * MAX_NUM_ELEMENTS_IN_EACH_BUFFER, null, GL_DYNAMIC_DRAW);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, local_to_world_index_buffer_gl_handle, LOCAL_TO_WORLD_INDEX_GL_VAC);

	glBindBuffer (GL_ARRAY_BUFFER, 0);
}


BASIC_VERTEX_SHADER :: #string  END 

#version 330 core
layout (location = 0) in vec3 position;

void main() {
   gl_Position = vec4(position.x, position.y, position.z, 1.0);
}
END

BASIC_FRAGMENT_SHADER :: #string END
#version 330 core
out vec4 FragColor;

void main() {
    FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
}
END


VERTEX_COLOR_FRAGMENT_SHADER :: #string END
#version 330 core

in vec3 rgb_color;

out vec4 frag_color;

void main() {
    frag_color = vec4(rgb_color, 1.0);
}
END

VERTEX_SHADER_WITH_CAMERA_MATRICES :: #string END
#version 330 core
layout (location = 0) in vec3 xyz_position;
uniform mat4 world_to_camera;
uniform mat4 camera_to_clip;

void main() {
    gl_Position = camera_to_clip * world_to_camera * vec4(xyz_position, 1.0);
}
END

VERTEX_SHADER_WITH_CAMERA_AND_PER_OBJECT_TRANSFORMS :: #string END
#version 330

in vec3 position;
in vec3 passthrough_rgb_color;

uniform mat4 camera_to_clip;
uniform mat4 world_to_camera;

in uint local_to_world_index;

layout(std140, row_major) uniform LtwMatrices {
    mat4 local_to_world_matrices[1024];
};

out vec3 rgb_color;

void main() {
    rgb_color = passthrough_rgb_color;
    gl_Position = camera_to_clip * world_to_camera * local_to_world_matrices[local_to_world_index] * vec4(position, 1.0);
}
END

check_compile_errors :: (shader : GLuint) -> success: bool, info_log : string {
    success : s32;
    glGetShaderiv (shader, GL_COMPILE_STATUS, *success);
    if !success {
        info_len : s32;
        glGetShaderiv (shader, GL_INFO_LOG_LENGTH, *info_len);
        info_data := cast (*u8) alloc (info_len,, temp);
        glGetShaderInfoLog (shader, xx info_len, xx *info_len, info_data);
        result : string;
        result.data = info_data;
        result.count = info_len;

        return false, result;
    }

    return true, "";
}

check_link_errors :: (program : GLuint) -> success: bool, info_log : string {
    success : s32;
    glGetProgramiv (program, GL_LINK_STATUS, *success);
    if !success {
        info_len : s32;
        glGetProgramiv (program, GL_INFO_LOG_LENGTH, *info_len);
        info_data := cast (*u8) alloc (info_len,, temp);
        glGetProgramInfoLog (program, xx info_len, xx *info_len, info_data);
        result : string;
        result.data = info_data;
        result.count = info_len;

        return false, result;
    }

    return true, "";
}

create_shader_program :: (vertex_source : string, fragment_source : string) -> program_handle: GLuint, success: bool {
    // in order to operate opengl you pretty much have to understand the entire rendering pipeline for rasterization on the gpu at a high level
	// OpenGL requires us to create at least a vertex shader and a
	// fragment shader, to create a shader program that it can execute.

	vertex_shader_handle := glCreateShader (GL_VERTEX_SHADER);
	defer glDeleteShader (vertex_shader_handle);

    shaders := *u8.[   SHADER_PREFIX.data ,    vertex_source.data ];
    lengths := s32.[xx SHADER_PREFIX.count, xx vertex_source.count];
	glShaderSource (vertex_shader_handle, 2, shaders.data, lengths.data);
	glCompileShader (vertex_shader_handle);
	ok, info_log := check_compile_errors (vertex_shader_handle);
	if !ok {
		log_error("Could not compile vertex shader %", info_log);
		return 0, false;
	}

	fragment_shader_handle := glCreateShader (GL_FRAGMENT_SHADER);
	defer glDeleteShader (fragment_shader_handle);
	shaders[1] =    fragment_source.data;
	lengths[1] = xx fragment_source.count;
	glShaderSource (fragment_shader_handle, 2, shaders.data, lengths.data);
	glCompileShader (fragment_shader_handle);

	ok, info_log = check_compile_errors (fragment_shader_handle);
	if !ok {
		log_error ("Could not compile fragment shader: %", info_log);
		return 0, false;
	}

	result := glCreateProgram ();
	glAttachShader(result, vertex_shader_handle);
	glAttachShader(result, fragment_shader_handle);

	glLinkProgram(result);
	ok, info_log = check_link_errors (result);

	if !ok {
		log_error ("Could not link shader program: %", info_log);
		glDeleteProgram (result);
		return 0, false;
	}

	return result, true;
}

set_vsync :: (value : bool) {
    wglSwapIntervalEXT(xx ifx value then 1 else 0);
}

