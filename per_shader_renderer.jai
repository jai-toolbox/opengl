/*
This is a thing that allows us to render a bunch of things in a game, each of which are their "own object", and can be moved independently in space.

The Hello Triangle of opengl usually gets you to create a vbo and an ibo, under a vao. This is usually extended naively to a per object triplet,
so each object ends up getting its own draw call, which is inefficient. 

A better approach would be to render all your objects at once if possible. So instead of creating per object opengl buffers, instead we just create one and store all
our objects in there. This is like going from AOS to SOA.

For example if you're rendering something with position, color, and normals, then there will be the following GL_ARRAY_BUFFERS:
* positions_buffer
* colors_buffer
* normals_buffer

Along with that there is a singular GL_ELEMENT_ARRAY_BUFFER
* index_buffer (rename to indices_buffer?)

We support rendering objects, by first buffering them into the system, this takes an itp-like (indexed triangle positions).

Suppose we have an itp object called Obj. By default such an object has their own local indices which use values from 0 to k-1, to define how the triangles should be rendered.
(note that they can be re-used and thus there may be more than k indices)

Note that we store a virtual allocator which keeps track of the usage of the index_buffer, and will help us during the buffer_object call.

When we call buffer object on Obj, then the virtual allocator will return some index j where j to j + (Obj.indices.count - 1) are all open index slots.

It then increments all of Obj's indices by j which makes them unique, so that when we do our glDrawElements call it will access in the right place.
If we didn't do this then all of them would be trying to access from 0 to some number and would be clobbering eachother.

In this system we can think about Obj holding a collection of global indices into the huge buffer, in reality there is one layer of indirection here
Obj holds an id, given to it by the renderer and then there is a table of object ids to their global indices, so we can render them.

*/

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
    index_buffer_capacity_in_indices: int;

    object_indices_to_render_this_frame: [..] u32;
    object_indices_in_cached_index_buffer: [..] u32;
    num_indices_in_cached_index_buffer: GLsizei;
    cached_index_buffer_is_valid: bool;

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

deinit :: (using psr : *Per_Shader_Renderer) {

    // delete the shader program
    gl_delete_shader_program(shader_program_gl_handle);
    shader_program_gl_handle = 0;

    // delete the VAO and index buffer
    gl_delete_vertex_array(vertex_attribute_array_gl_handle);
    gl_delete_buffer(index_buffer_gl_handle);
    vertex_attribute_array_gl_handle = 0;
    index_buffer_gl_handle = 0;

    // free the render queue arrays
    array_free(object_indices_to_render_this_frame);
    array_free(object_indices_in_cached_index_buffer);

    // free all the dynamic arrays stored as values in the table, then free the table itself
    for buffered_object_index_to_global_indices {
        array_free(it);
    }
    deinit(*buffered_object_index_to_global_indices);

    // free the virtual allocator
    deinit(*first_fit_virtual_allocator);
}


set_active_program :: (renderer: Per_Shader_Renderer) {
    gl_set_active_shader_program(renderer.shader_program_gl_handle);
}

clear_active_program :: () {
    gl_clear_active_shader_program();
}

queue_render :: (using psr : *Per_Shader_Renderer, object_index : u32) { 

    // todo do a check to see if it exists first right? through the virtual allocator
   
   array_add(*object_indices_to_render_this_frame, object_index);

   // add it to the per frame thing, which gets emptied when rendering.
}

queued_objects_match_cached_index_buffer :: (
    using psr: *Per_Shader_Renderer,
) -> bool {
    if !cached_index_buffer_is_valid return false;
    if object_indices_to_render_this_frame.count
        != object_indices_in_cached_index_buffer.count return false;

    for object_index, queue_index: object_indices_to_render_this_frame {
        if object_index
            != object_indices_in_cached_index_buffer[queue_index] return false;
    }
    return true;
}

invalidate_cached_index_buffer :: (using psr: *Per_Shader_Renderer) {
    cached_index_buffer_is_valid = false;
    num_indices_in_cached_index_buffer = 0;
    array_reset(*object_indices_in_cached_index_buffer);
}

// Rebuild the renderer's combined element buffer only when the queued object
// sequence changes. The exact order is part of the cache key because it is the
// order in which the objects' triangles are submitted to OpenGL.
prepare_index_buffer_for_queued_objects :: (
    using psr: *Per_Shader_Renderer,
) -> GLsizei {
    gl_bind_buffer_to_binding_target(GL_ELEMENT_ARRAY_BUFFER, index_buffer_gl_handle);
    if queued_objects_match_cached_index_buffer(psr) {
        return num_indices_in_cached_index_buffer;
    }

    combined_global_indices: [..] u32;
    defer array_free(combined_global_indices);
    for object_index: object_indices_to_render_this_frame {
        success, object_global_indices := table_find(
            *buffered_object_index_to_global_indices,
            object_index);
        if !success {
            log("couldn't find the global indices of object with id: %", object_index);
            continue;
        }
        for global_index: object_global_indices {
            array_add(*combined_global_indices, global_index);
        }
    }

    if combined_global_indices.count > index_buffer_capacity_in_indices {
        index_buffer_capacity_in_indices = max(
            combined_global_indices.count,
            max(index_buffer_capacity_in_indices * 2, 1));
        gl_allocate_storage_for_buffer_bound_to_binding_target(
            GL_ELEMENT_ARRAY_BUFFER,
            index_buffer_capacity_in_indices * size_of(u32),
            null,
            GL_DYNAMIC_DRAW);
    }
    gl_update_subdata_in_buffer_bound_to_binding_target(
        GL_ELEMENT_ARRAY_BUFFER,
        0,
        combined_global_indices.count * size_of(u32),
        combined_global_indices.data);

    array_reset(*object_indices_in_cached_index_buffer);
    for object_index: object_indices_to_render_this_frame {
        array_add(*object_indices_in_cached_index_buffer, object_index);
    }
    num_indices_in_cached_index_buffer = cast(GLsizei) combined_global_indices.count;
    cached_index_buffer_is_valid = true;
    return num_indices_in_cached_index_buffer;
}

render :: (using psr : *Per_Shader_Renderer, primitive_mode : GLenum = GL_TRIANGLES) {
    gl_set_active_shader_program(shader_program_gl_handle);
    gl_bind_vertex_array(vertex_attribute_array_gl_handle);

    index_count := prepare_index_buffer_for_queued_objects(psr);
    gl_draw_indexed_vertices_from_bound_vertex_array(
        primitive_mode,
        index_count,
        GL_UNSIGNED_INT,
        cast(*void) 0);
    array_reset(*object_indices_to_render_this_frame);

    gl_bind_vertex_array(0);
    gl_clear_active_shader_program();
}


/*
 Removes the object from the GPU-side virtual allocation and render queue,
 but leaves the CPU-side arrays (indices, positions, colors, etc.) intact
 so the renderable can be re-buffered later without rebuilding its data.
*/
unbuffer_object :: (using psr: *Per_Shader_Renderer, object_index: u32) {

    // note that we don't actually have to unbuffer it from the gpu arrays, we just have to make "free" in the sense that
    // now other people can use that place in the metadata that keeps up with ownership

    // todo: we should keep a list of what's used for the local to world indices, as of right now it literally just increments
    // the value by 1 every time, and that keeps it safe, in shaders that have local to world matrices, then we need to 
    // create a custom unbuffer object, this unbuffer object function needs to additionally free up local to world matrices, which we don't do here.

    virtual_free(*first_fit_virtual_allocator, object_index);

    found, global_indices := table_find(*buffered_object_index_to_global_indices, object_index);
    if found {
        array_free(global_indices);
        table_remove(*buffered_object_index_to_global_indices, object_index);
        invalidate_cached_index_buffer(psr);
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
