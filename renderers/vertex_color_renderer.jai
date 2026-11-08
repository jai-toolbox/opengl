// auto-generated renderer for shader: Vertex_Color
// do not edit manually.

Vertex_Color_Mesh_Vertex_Uniforms_Bindings :: struct {
    object_transforms: GLuint;
    world_to_camera: Matrix4;
    camera_to_clip: Matrix4;
}


Vertex_Color_Renderable :: struct {
    indices : [..] u32;
    object_index : u32;

    positions: [..] Vector3;
    colors: [..] Vector3;
    local_to_world_indices: [..] s32;

}


Vertex_Color_Geometry :: struct {
    indices : [..] u32;
    positions: [..] Vector3;
    colors: [..] Vector3;
    local_to_world_indices: [..] s32;
}

assign_geometry_copy :: (renderable: *Vertex_Color_Renderable, geometry: $T/interface Vertex_Color_Geometry) {
    array_copy(*renderable.indices, geometry.indices);
    array_copy(*renderable.positions, geometry.positions);
    array_copy(*renderable.colors, geometry.colors);
    array_copy(*renderable.local_to_world_indices, geometry.local_to_world_indices);
}

assign_geometry :: (renderable: *Vertex_Color_Renderable, geometry: $T/interface Vertex_Color_Geometry) {
    renderable.indices = geometry.indices;
    renderable.positions = geometry.positions;
    renderable.colors = geometry.colors;
    renderable.local_to_world_indices = geometry.local_to_world_indices;
}


deinit :: (renderable: *Vertex_Color_Renderable) {
    array_free(renderable.indices);
    array_free(renderable.positions);
    array_free(renderable.colors);
    array_free(renderable.local_to_world_indices);
}

/*

so deinit exists but also unbuffer object exists, the difference is that deinit takes in a renderable and frees its CPU-side arrays and resets its transform slot, whereas unbuffer_object only frees the GPU-side virtual allocation, leaving the CPU data intact for potential re-buffering later.

*/
deinit :: (renderable: *Vertex_Color_Renderable, renderer: *Vertex_Color_Renderer) {
    unbuffer_object(*renderer.psr, renderable.object_index);
    array_free(renderable.indices);
    array_free(renderable.positions);
    array_free(renderable.colors);
    array_free(renderable.local_to_world_indices);
}


unbuffer_object :: (renderer: *Vertex_Color_Renderer, renderable: *Vertex_Color_Renderable) {
    unbuffer_object(*renderer.psr, renderable.object_index);
    renderable.object_index = 0;
}


queue_render :: (using renderer: *Vertex_Color_Renderer, renderable: Vertex_Color_Renderable) {
    queue_render(*renderer.psr, renderable.object_index);
}

// Indices are relative to this buffered object's first vertex.
update_object_indices :: (renderer : *Vertex_Color_Renderer, object_index : u32, indices : [] u32) -> bool {
    return update_object_indices(*renderer.psr, object_index, indices);
}

update_object_indices :: (renderer : *Vertex_Color_Renderer, renderable : $T/interface Vertex_Color_Renderable, indices : [] u32) -> bool {
    return update_object_indices(renderer, renderable.object_index, indices);
}

queue_render :: (renderer : *Vertex_Color_Renderer, object_index : u32) {
    queue_render(*renderer.psr, object_index);
}


unbuffer_object :: (renderer : *Vertex_Color_Renderer, object_index : u32) {
    unbuffer_object(*renderer.psr, object_index);
}

buffer_object :: (renderer : *Vertex_Color_Renderer, vertices : [] Mesh_Vertex_Color_Input, indices : [] u32) -> (object_index : u32, success : bool) {
    positions : [..] Vector3;
    defer array_free(positions);
    colors : [..] Vector3;
    defer array_free(colors);
    local_to_world_indices : [..] s32;
    defer array_free(local_to_world_indices);
    for vertex : vertices {
        array_add(*positions, vertex.vertex.position);
        array_add(*colors, vertex.vertex.color);
        array_add(*local_to_world_indices, vertex.local_to_world_index);
    }
    buffered_index, buffered := buffer_object(renderer, indices, positions, colors, local_to_world_indices);
    return buffered_index, buffered;
}


Vertex_Color_Renderer :: struct {
    using #as psr : Per_Shader_Renderer = .{max_num_elements_in_each_buffer = 100000};


    typed_0_uniform_location : GLint = -1;
    typed_1_uniform_location : GLint = -1;
    typed_2_uniform_location : GLint = -1;

    positions_buffer_gl_handle: GLuint;
    colors_buffer_gl_handle: GLuint;
    local_to_world_indices_buffer_gl_handle: GLuint;


}

set_uniforms :: (renderer: *Vertex_Color_Renderer, ctx: Vertex_Color_Mesh_Vertex_Uniforms_Bindings) {
    gl_set_active_shader_program(renderer.shader_program_gl_handle);
    gl_set_active_texture_unit(GL_TEXTURE0 + 0);
    gl_bind_texture_to_binding_target_of_active_texture_unit(GL_TEXTURE_2D,ctx.object_transforms);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_0_uniform_location,0);
    gl_set_uniform_matrix_4fv_on_active_shader_program(renderer.typed_1_uniform_location, 1, GL_TRUE, *ctx.world_to_camera.coef[0][0]);
    gl_set_uniform_matrix_4fv_on_active_shader_program(renderer.typed_2_uniform_location, 1, GL_TRUE, *ctx.camera_to_clip.coef[0][0]);
    gl_set_active_texture_unit(GL_TEXTURE0);
    gl_clear_active_shader_program();
}


init :: (using renderer : *Vertex_Color_Renderer) -> bool {
    vertex_shader_source := Vertex_Color_Vertex_Source;
    fragment_shader_source := Vertex_Color_Fragment_Source;

    if !init(*renderer.psr, vertex_shader_source, fragment_shader_source, max_num_elements_in_each_buffer) return false;
    init_buffers_no_data(renderer);


    typed_0_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "object_transforms");
    typed_1_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "world_to_camera");
    typed_2_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "camera_to_clip");

    return true;
}


deinit :: (using renderer : *Vertex_Color_Renderer) {
    deinit(*psr);

    gl_delete_buffer(positions_buffer_gl_handle);
    gl_delete_buffer(colors_buffer_gl_handle);
    gl_delete_buffer(local_to_world_indices_buffer_gl_handle);
}



init_buffers_no_data :: (using apcr : *Vertex_Color_Renderer) { // todo change renderer name

    vertex_attribute_array_gl_handle = gl_create_vertex_array();
    gl_bind_vertex_array(vertex_attribute_array_gl_handle);



    index_buffer_gl_handle = gl_create_buffer();
    gl_bind_buffer_to_binding_target(GL_ELEMENT_ARRAY_BUFFER, index_buffer_gl_handle);
    // note: it's probably wrong to use  max_num_elements_in_each_buffer because as noted before the number of indices
    // could be larger than this value if we try and render all objects, but we won't care about that until it's a problem.
    gl_allocate_storage_for_buffer_bound_to_binding_target(GL_ELEMENT_ARRAY_BUFFER, size_of(u32) * max_num_elements_in_each_buffer, null, GL_DYNAMIC_DRAW);
    index_buffer_capacity_in_indices = cast(int) max_num_elements_in_each_buffer;
    // note: we don't have to init the vertex attribute for indices because they used in the shader program for rendering, they're just used during glDrawElements.

    generate_buffer_for_vertex_attribute(*positions_buffer_gl_handle, Vector3, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, positions_buffer_gl_handle, "position", 3, GL_FLOAT, GL_FALSE, 0, null);

    generate_buffer_for_vertex_attribute(*colors_buffer_gl_handle, Vector3, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, colors_buffer_gl_handle, "color", 3, GL_FLOAT, GL_FALSE, 0, null);

    generate_buffer_for_vertex_attribute(*local_to_world_indices_buffer_gl_handle, s32, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, local_to_world_indices_buffer_gl_handle, "local_to_world_index", 1, GL_INT, GL_FALSE, 0, null);



	gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, 0);
}


buffer_object :: (
    using renderer : *Vertex_Color_Renderer,
    renderable : *$T/interface Vertex_Color_Renderable,
    budgeter: *GL_Budgeter = null,
) -> success: bool {


    object_index, success := buffer_object(renderer,
            renderable.indices,

            renderable.positions,
            renderable.colors,
            renderable.local_to_world_indices,
            budgeter
    );

    if success {
        renderable.object_index = object_index;

    };
    return success;
}

// todo ability to specify the transform matrix upon buffering?
buffer_object :: (
        using renderer: *Vertex_Color_Renderer,
        indices : [] u32,
        positions : [] Vector3,
        colors : [] Vector3,
        local_to_world_indices : [] s32,

        budgeter: *GL_Budgeter = null

        ) -> object_index: u32, success: bool {

    /*
    note: we use the positions as count, becaues that is the actual data that needs to be in the buffer
    the indices use duplicates sometimes to refer to the same vertex multiple times.
    */
    length := positions.count;
    if length == 0 { return 0, false; }
    index, success := allocate_buffered_object(*renderer.psr, cast(u32) length, indices);
    if !success {
        log("ran out of virtual memory");
        return 0, false;
    }



    gl_bind_vertex_array(vertex_attribute_array_gl_handle);


    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, positions_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(budgeter, GL_ARRAY_BUFFER, index * size_of(Vector3), positions.count * size_of(Vector3), positions.data);



    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, colors_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(budgeter, GL_ARRAY_BUFFER, index * size_of(Vector3), colors.count * size_of(Vector3), colors.data);



    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, local_to_world_indices_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(budgeter, GL_ARRAY_BUFFER, index * size_of(s32), local_to_world_indices.count * size_of(s32), local_to_world_indices.data);




    gl_bind_vertex_array(0);

    return index, true;
}

/*

so this function is kinda sketchy right now, you can only rebuffer an object if it takes up the exact same size,
if you're rebuffering things and using up more space then you did before you'll start having undefined behavior in rendering and things
will go off the rails.

*/
rebuffer_object :: (using renderer : *Vertex_Color_Renderer, renderable : $T/interface Vertex_Color_Renderable) {

    gl_bind_vertex_array(vertex_attribute_array_gl_handle);

    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, positions_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, renderable.object_index * size_of(Vector3), renderable.positions.count * size_of(Vector3), renderable.positions.data);

    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, colors_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, renderable.object_index * size_of(Vector3), renderable.colors.count * size_of(Vector3), renderable.colors.data);

    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, local_to_world_indices_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, renderable.object_index * size_of(s32), renderable.local_to_world_indices.count * size_of(s32), renderable.local_to_world_indices.data);


    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, 0);
    gl_bind_vertex_array(0);
}

render :: (using renderer : *Vertex_Color_Renderer, primitive_mode: GLenum = GL_TRIANGLES) {

    // todo think about if we should be using temporary storage.

    gl_set_active_shader_program(shader_program_gl_handle);



    gl_bind_vertex_array(vertex_attribute_array_gl_handle);
    index_count := prepare_index_buffer_for_queued_objects(*renderer.psr);
    gl_draw_indexed_vertices_from_bound_vertex_array(
        primitive_mode,
        index_count,
        GL_UNSIGNED_INT,
        cast(*void) 0);
    array_reset(*object_indices_to_render_this_frame);

    gl_bind_vertex_array(0);
    gl_clear_active_shader_program();
}

Vertex_Color_Vertex_Source :: #string END_Vertex_Color_Vertex_Source
#version 330 core
// Generated from Jai procedure mesh_vertex_color_vertex_shader.
in vec3 position;
in vec3 color;
in int local_to_world_index;
out vec3 passthrough_color;
uniform sampler2D object_transforms;
uniform mat4 world_to_camera;
uniform mat4 camera_to_clip;

vec4 jai_mesh_transform(sampler2D table, int index, vec4 value) {
    return vec4(dot(texelFetch(table, ivec2(0, index), 0), value), dot(texelFetch(table, ivec2(1, index), 0), value), dot(texelFetch(table, ivec2(2, index), 0), value), dot(texelFetch(table, ivec2(3, index), 0), value));
}

void main() {
    vec4 world = jai_mesh_transform(object_transforms, local_to_world_index, vec4(position.x, position.y, position.z, 1.0));
    gl_Position = ((camera_to_clip * world_to_camera) * world);
    passthrough_color = color;
}

END_Vertex_Color_Vertex_Source

Vertex_Color_Fragment_Source :: #string END_Vertex_Color_Fragment_Source
#version 330 core
// Generated from Jai procedure mesh_vertex_color_fragment_shader.
in vec3 passthrough_color;
layout(location=0) out vec4 gpu_rendering_pipeline_stage_attachment_color;

void main() {
    gpu_rendering_pipeline_stage_attachment_color = vec4(passthrough_color.x, passthrough_color.y, passthrough_color.z, 1.0);
}

END_Vertex_Color_Fragment_Source
