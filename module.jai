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

/*

Something important to realize about this is what a local_to_world_index is and how that is different from a object index.

A local to world index, is the index which maps into the local to world matrices which tells the renderer where this object should be in space.

The object index a number which represents where we can put this object in the gpu's buffer where there is enough space to fit all the data in.

Because we do SoA style buffers for each attribute, each buffer is just a scaled version of the other depending on the size of the individual elements stored in the buffer. (buffer is just an array of a particular attribute)

Now we can understand the difference between this and the local to world index.

If you were to buffer an object that has 8 vertices, then in each SoA buffer, we would do "virtual allocation" to find a place we can store it, and at the start
that will be index 0, and we'll take up 8 of the elements in the array. We can assign this object the local_to_world index of 0 as well. 

When we create the second object, then now its object_index is going to be 8, because that was the next space in the buffer where we can put the object. 
But we can still assign this object the local to world index of 1, because the local to world index is the same along every vertex of the object. 

This means that the local_to_world index can just be the number of objects you've created up until this point (not thinking about removals or anything).

*/
Per_Object_Transform_Renderer :: struct { // POTR for short said as "potter", also this name should say that it uses a camera.

    using #as psr : Per_Shader_Renderer;

    NUM_LOCAL_TO_WORLD_MATRICES :: 1024;
    current_local_to_world_index : u32 = 0;

    local_to_world_matrices : [NUM_LOCAL_TO_WORLD_MATRICES] Matrix4; 

    local_to_world_gl_uniform_buffer_handle : GLuint;

    position_buffer_gl_handle: GLuint;
    local_to_world_index_buffer_gl_handle : GLuint;
    color_buffer_gl_handle: GLuint; // I'm just stuffing this in here so we can render basic things and not get visually confused.
}

// a templated adaptor to allow buffering of generic things that have the required attributes so we can be lazy.
// it didn't work because it would recursively select itself, which is not what I want
// buffer_object_from_renderable :: (potr : *Per_Object_Transform_Renderer, renderable : $T) -> object_index: u32, local_to_world_index: u32, success: bool {
//     return buffer_object(potr, renderable.indices, renderable.positions, renderable.rgb_colors);
// }

// todo ability to specify the transform matrix upon buffering?
buffer_object :: (
        using potr : *Per_Object_Transform_Renderer, 
        indices: [..] u32, 
        positions: [..] Vector3, 
        colors: [..] Vector3
        ) -> object_index: u32, local_to_world_index: u32, success: bool {

    // todo: transform matrix

    // note: we use the positions as count, becaues that is the actual data that needs to be in the buffer
    // the indices use duplicates sometimes to refer to the same vertex multiple times.
    length := positions.count;
    index, success := virtual_alloc(*first_fit_virtual_allocator, xx length);
    if (! success) {
        log("ran out of virtual memory");
        return 0, 0, false;
    }

    global_indices_for_object : [..] u32;
    for indices 
        array_add(*global_indices_for_object, xx index + it);

    // log("just added idx: % to the table", index);
    table_add(*buffered_object_index_to_global_indices, xx index, global_indices_for_object);

    glBindVertexArray(vertex_attribute_array_gl_handle);

    // this doesn't have to exist right?
    // glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index_buffer_gl_handle);
    // glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, index * size_of(u32), indices.count * size_of(u32), indices.data);

    glBindBuffer(GL_ARRAY_BUFFER, position_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, index * size_of(Vector3), positions.count * size_of(Vector3), positions.data);

    glBindBuffer(GL_ARRAY_BUFFER, color_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, index * size_of(Vector3), colors.count * size_of(Vector3), colors.data);

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

queue_render :: (using psr : *Per_Shader_Renderer, object_index : u32) { 

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

buffer_local_to_world_matrices :: (using potr : *Per_Object_Transform_Renderer) {
    glBindBuffer(GL_UNIFORM_BUFFER, local_to_world_matrices_gl_handle);
    glBufferData(GL_UNIFORM_BUFFER, NUM_LOCAL_TO_WORLD_MATRICES * size_of(Matrix4), local_to_world_matrices, GL_DYNAMIC_DRAW);
    glBindBufferBase(GL_UNIFORM_BUFFER, 0, ltw_matrices_gl_name);
}

// precond: the shader program is initialize.
// without initialization the potr has undefined behavior
init :: (using potr : *Per_Object_Transform_Renderer) { 

    shader_program_handle, success := create_shader_program(VERTEX_SHADER_WITH_CAMERA_AND_PER_OBJECT_TRANSFORMS, COLOR_FRAGMENT_SHADER);
	if !success
        log("shader compilation failed");
		// return false;
    if success 
        log("shader compilation succeeded");

    shader_program_gl_handle = shader_program_handle;

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

ABSOLUTE_POSITION_VERTEX_SHADER :: #string  END 
#version 330 core
layout (location = 0) in vec3 position;

void main() {
   gl_Position = vec4(position.x, position.y, position.z, 1.0);
}
END

ABSOLUTE_POSITION_COLOR_VERTEX_SHADER :: #string  END 
#version 330 core

in vec3 position;

in vec3 passthrough_rgb_color;
out vec3 rgb_color;

void main() {
   rgb_color = passthrough_rgb_color;
   gl_Position = vec4(position.x, position.y, position.z, 1.0);
}

END

FIXED_COLOR_FRAGMENT_SHADER :: #string END
#version 330 core
out vec4 FragColor;

void main() {
    FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
}
END


COLOR_FRAGMENT_SHADER :: #string END
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

// TODO: this is unused so far, but it would be eventually generated per vertex/fragmnt shader pair and used to fill out this struct
// we can also meta program this out to make a renderer for the shader program which does the big buffer soa approach.
Shader :: struct {

    attributes : [..] GL_Shader_Attribute_Variable;

    vertex_shader_source : string;
    fragment_shader_source : string;
}

// should be autogenerated from a tuple?
ABSOLUTE_POSITION_COLOR_SHADER :: Shader.{
    vertex_shader_source = ABSOLUTE_POSITION_COLOR_VERTEX_SHADER,
    fragment_shader_source = COLOR_FRAGMENT_SHADER
};

// this should be generated by the meta programming too.
Absolute_Position_Color_Renderable :: struct {
    indices : [..] u32;
    positions : [..] Vector3;
    rgb_colors : [..] Vector3;

    object_index : u32;
}

// meta program this by looking at a shader like the one above.
Per_Object_Absolute_Position_Color_Renderer :: struct {
    using #as psr : Per_Shader_Renderer;

    // todo meta program this by iterating over the non passthrough vertex attributes in each shader source.

    position_buffer_gl_handle: GLuint;
    color_buffer_gl_handle: GLuint; 
}

// precond: the shader program is initialize.
// without initialization the potr has undefined behavior
init :: (using apcr : *Per_Object_Absolute_Position_Color_Renderer) { 

    shader_program_handle, success := create_shader_program(ABSOLUTE_POSITION_COLOR_VERTEX_SHADER, COLOR_FRAGMENT_SHADER);
	if !success
        log("shader compilation failed");
		// return false;
    if success 
        log("shader compilation succeeded");

    shader_program_gl_handle = shader_program_handle;

    first_fit_virtual_allocator.size = MAX_NUM_ELEMENTS_IN_EACH_BUFFER;

    init_buffers_no_data(apcr);
}

init_buffers_no_data :: (using apcr : *Per_Object_Absolute_Position_Color_Renderer) {

    glGenVertexArrays(1, *vertex_attribute_array_gl_handle);
    glBindVertexArray(vertex_attribute_array_gl_handle);

    glGenBuffers(1, *index_buffer_gl_handle);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index_buffer_gl_handle);
    // NOTE: it's probably wrong to use  MAX_NUM_ELEMENTS_IN_EACH_BUFFER because as noted before the number of indices
    // could be larger than this value if we try and render all objects, but we won't care about that until it's a problem.
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, size_of(u32) *  MAX_NUM_ELEMENTS_IN_EACH_BUFFER, null, GL_DYNAMIC_DRAW);
    // note: we don't have to init the vertex attribute for indices because they used in the shader program for rendering, they're just used during glDrawElements.

    // this should be meta programmed away, by iterating over a vector of GL_VAC's and #inserting the code here.

    glGenBuffers(1, *position_buffer_gl_handle);
    glBindBuffer(GL_ARRAY_BUFFER, position_buffer_gl_handle);
    glBufferData(GL_ARRAY_BUFFER, size_of(Vector3) * MAX_NUM_ELEMENTS_IN_EACH_BUFFER, null, GL_DYNAMIC_DRAW);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, position_buffer_gl_handle, POSITION_GL_VAC);

    glGenBuffers(1, *color_buffer_gl_handle);
    glBindBuffer(GL_ARRAY_BUFFER, color_buffer_gl_handle);
    glBufferData(GL_ARRAY_BUFFER, size_of(Vector3) * MAX_NUM_ELEMENTS_IN_EACH_BUFFER, null, GL_DYNAMIC_DRAW);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, color_buffer_gl_handle, PASSTHROUGH_RGB_COLOR_GL_VAC);

	glBindBuffer (GL_ARRAY_BUFFER, 0);
}

buffer_object :: (
        using apcr : *Per_Object_Absolute_Position_Color_Renderer, 
        renderable : *$T/interface Absolute_Position_Color_Renderable
        ) -> success: bool {
    object_index, success := buffer_object(apcr, renderable.indices, renderable.positions, renderable.rgb_colors);
    if success renderable.object_index = object_index;
    return success;
}

buffer_object :: (
        using apcr : *Per_Object_Absolute_Position_Color_Renderer, 
        indices: [..] u32, 
        positions: [..] Vector3, 
        colors: [..] Vector3
        ) -> object_index: u32, success: bool {

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

    // log("just added idx: % to the table", index);
    table_add(*buffered_object_index_to_global_indices, xx index, global_indices_for_object);

    glBindVertexArray(vertex_attribute_array_gl_handle);

    // todo meta program this buy looping over attributes to do this.
        
    glBindBuffer(GL_ARRAY_BUFFER, position_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, index * size_of(Vector3), positions.count * size_of(Vector3), positions.data);

    glBindBuffer(GL_ARRAY_BUFFER, color_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, index * size_of(Vector3), colors.count * size_of(Vector3), colors.data);

    glBindVertexArray(0);

    return index, true;
}

// todo this can probably take in the per shader renderer thing.
render :: (using potr : *Per_Object_Absolute_Position_Color_Renderer) {

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

