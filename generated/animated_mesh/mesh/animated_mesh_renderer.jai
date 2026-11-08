// auto-generated renderer for shader: Animated_Mesh
// do not edit manually.

Animated_Mesh_Animated_Mesh_Uniforms_Bindings :: struct {
    world_to_clip: Matrix4;
    image: GLuint;
    first_offset: Vector2;
    second_offset: Vector2;
    frame_mix: float32;
    eye: Vector3;
    direction: Vector3;
    orthographic: bool;
    volume: bool;
    blend_axis_stacks: bool;
    emission: float32;
}


Animated_Mesh_Renderable :: struct {
    indices : [..] u32;
    object_index : u32;

    positions: [..] Vector3;
    normals: [..] Vector3;
    uvs: [..] Vector2;
    spacings: [..] float32;

}


Animated_Mesh_Geometry :: struct {
    indices : [..] u32;
    positions: [..] Vector3;
    normals: [..] Vector3;
    uvs: [..] Vector2;
    spacings: [..] float32;
}

assign_geometry_copy :: (renderable: *Animated_Mesh_Renderable, geometry: $T/interface Animated_Mesh_Geometry) {
    array_copy(*renderable.indices, geometry.indices);
    array_copy(*renderable.positions, geometry.positions);
    array_copy(*renderable.normals, geometry.normals);
    array_copy(*renderable.uvs, geometry.uvs);
    array_copy(*renderable.spacings, geometry.spacings);
}

assign_geometry :: (renderable: *Animated_Mesh_Renderable, geometry: $T/interface Animated_Mesh_Geometry) {
    renderable.indices = geometry.indices;
    renderable.positions = geometry.positions;
    renderable.normals = geometry.normals;
    renderable.uvs = geometry.uvs;
    renderable.spacings = geometry.spacings;
}


deinit :: (renderable: *Animated_Mesh_Renderable) {
    array_free(renderable.indices);
    array_free(renderable.positions);
    array_free(renderable.normals);
    array_free(renderable.uvs);
    array_free(renderable.spacings);
}

/*

so deinit exists but also unbuffer object exists, the difference is that deinit takes in a renderable and frees its CPU-side arrays and resets its transform slot, whereas unbuffer_object only frees the GPU-side virtual allocation, leaving the CPU data intact for potential re-buffering later.

*/
deinit :: (renderable: *Animated_Mesh_Renderable, renderer: *Animated_Mesh_Renderer) {
    unbuffer_object(*renderer.psr, renderable.object_index);
    array_free(renderable.indices);
    array_free(renderable.positions);
    array_free(renderable.normals);
    array_free(renderable.uvs);
    array_free(renderable.spacings);
}


unbuffer_object :: (renderer: *Animated_Mesh_Renderer, renderable: *Animated_Mesh_Renderable) {
    unbuffer_object(*renderer.psr, renderable.object_index);
    renderable.object_index = 0;
}


queue_render :: (using renderer: *Animated_Mesh_Renderer, renderable: Animated_Mesh_Renderable) {
    queue_render(*renderer.psr, renderable.object_index);
}

// Indices are relative to this buffered object's first vertex.
update_object_indices :: (renderer : *Animated_Mesh_Renderer, object_index : u32, indices : [] u32) -> bool {
    return update_object_indices(*renderer.psr, object_index, indices);
}

update_object_indices :: (renderer : *Animated_Mesh_Renderer, renderable : $T/interface Animated_Mesh_Renderable, indices : [] u32) -> bool {
    return update_object_indices(renderer, renderable.object_index, indices);
}

queue_render :: (renderer : *Animated_Mesh_Renderer, object_index : u32) {
    queue_render(*renderer.psr, object_index);
}


unbuffer_object :: (renderer : *Animated_Mesh_Renderer, object_index : u32) {
    unbuffer_object(*renderer.psr, object_index);
}

buffer_object :: (renderer : *Animated_Mesh_Renderer, vertices : [] Animated_Mesh_Vertex, indices : [] u32) -> (object_index : u32, success : bool) {
    positions : [..] Vector3;
    defer array_free(positions);
    normals : [..] Vector3;
    defer array_free(normals);
    uvs : [..] Vector2;
    defer array_free(uvs);
    spacings : [..] float32;
    defer array_free(spacings);
    for vertex : vertices {
        array_add(*positions, vertex.position);
        array_add(*normals, vertex.normal);
        array_add(*uvs, vertex.uv);
        array_add(*spacings, vertex.spacing);
    }
    buffered_index, buffered := buffer_object(renderer, indices, positions, normals, uvs, spacings);
    return buffered_index, buffered;
}


Animated_Mesh_Renderer :: struct {
    using #as psr : Per_Shader_Renderer = .{max_num_elements_in_each_buffer = 100000};


    typed_0_uniform_location : GLint = -1;
    typed_1_uniform_location : GLint = -1;
    typed_2_uniform_location : GLint = -1;
    typed_3_uniform_location : GLint = -1;
    typed_4_uniform_location : GLint = -1;
    typed_5_uniform_location : GLint = -1;
    typed_6_uniform_location : GLint = -1;
    typed_7_uniform_location : GLint = -1;
    typed_8_uniform_location : GLint = -1;
    typed_9_uniform_location : GLint = -1;
    typed_10_uniform_location : GLint = -1;

    positions_buffer_gl_handle: GLuint;
    normals_buffer_gl_handle: GLuint;
    uvs_buffer_gl_handle: GLuint;
    spacings_buffer_gl_handle: GLuint;


}

set_uniforms :: (renderer: *Animated_Mesh_Renderer, ctx: Animated_Mesh_Animated_Mesh_Uniforms_Bindings) {
    gl_set_active_shader_program(renderer.shader_program_gl_handle);
    gl_set_uniform_matrix_4fv_on_active_shader_program(renderer.typed_0_uniform_location, 1, GL_TRUE, *ctx.world_to_clip.coef[0][0]);
    gl_set_active_texture_unit(GL_TEXTURE0 + 0);
    gl_bind_texture_to_binding_target_of_active_texture_unit(GL_TEXTURE_2D,ctx.image);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_1_uniform_location,0);
    gl_set_uniform_2f_on_active_shader_program(renderer.typed_2_uniform_location, ctx.first_offset.x, ctx.first_offset.y);
    gl_set_uniform_2f_on_active_shader_program(renderer.typed_3_uniform_location, ctx.second_offset.x, ctx.second_offset.y);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_4_uniform_location, ctx.frame_mix);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_5_uniform_location, ctx.eye.x, ctx.eye.y, ctx.eye.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_6_uniform_location, ctx.direction.x, ctx.direction.y, ctx.direction.z);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_7_uniform_location, xx ctx.orthographic);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_8_uniform_location, xx ctx.volume);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_9_uniform_location, xx ctx.blend_axis_stacks);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_10_uniform_location, ctx.emission);
    gl_set_active_texture_unit(GL_TEXTURE0);
    gl_clear_active_shader_program();
}


init :: (using renderer : *Animated_Mesh_Renderer) -> bool {
    vertex_shader_source := Animated_Mesh_Vertex_Source;
    fragment_shader_source := Animated_Mesh_Fragment_Source;

    if !init(*renderer.psr, vertex_shader_source, fragment_shader_source, max_num_elements_in_each_buffer) return false;
    init_buffers_no_data(renderer);


    typed_0_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "world_to_clip");
    typed_1_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "image");
    typed_2_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "first_offset");
    typed_3_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "second_offset");
    typed_4_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "frame_mix");
    typed_5_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "eye");
    typed_6_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "direction");
    typed_7_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "orthographic");
    typed_8_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "volume");
    typed_9_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "blend_axis_stacks");
    typed_10_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "emission");

    return true;
}


deinit :: (using renderer : *Animated_Mesh_Renderer) {
    deinit(*psr);

    gl_delete_buffer(positions_buffer_gl_handle);
    gl_delete_buffer(normals_buffer_gl_handle);
    gl_delete_buffer(uvs_buffer_gl_handle);
    gl_delete_buffer(spacings_buffer_gl_handle);
}



init_buffers_no_data :: (using apcr : *Animated_Mesh_Renderer) { // todo change renderer name

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

    generate_buffer_for_vertex_attribute(*normals_buffer_gl_handle, Vector3, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, normals_buffer_gl_handle, "normal", 3, GL_FLOAT, GL_FALSE, 0, null);

    generate_buffer_for_vertex_attribute(*uvs_buffer_gl_handle, Vector2, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, uvs_buffer_gl_handle, "uv", 2, GL_FLOAT, GL_FALSE, 0, null);

    generate_buffer_for_vertex_attribute(*spacings_buffer_gl_handle, float32, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, spacings_buffer_gl_handle, "spacing", 1, GL_FLOAT, GL_FALSE, 0, null);



	gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, 0);
}


buffer_object :: (
    using renderer : *Animated_Mesh_Renderer,
    renderable : *$T/interface Animated_Mesh_Renderable,
    budgeter: *GL_Budgeter = null,
) -> success: bool {


    object_index, success := buffer_object(renderer,
            renderable.indices,

            renderable.positions,
            renderable.normals,
            renderable.uvs,
            renderable.spacings,
            budgeter
    );

    if success {
        renderable.object_index = object_index;

    };
    return success;
}

// todo ability to specify the transform matrix upon buffering?
buffer_object :: (
        using renderer: *Animated_Mesh_Renderer,
        indices : [] u32,
        positions : [] Vector3,
        normals : [] Vector3,
        uvs : [] Vector2,
        spacings : [] float32,

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



    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, normals_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(budgeter, GL_ARRAY_BUFFER, index * size_of(Vector3), normals.count * size_of(Vector3), normals.data);



    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, uvs_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(budgeter, GL_ARRAY_BUFFER, index * size_of(Vector2), uvs.count * size_of(Vector2), uvs.data);



    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, spacings_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(budgeter, GL_ARRAY_BUFFER, index * size_of(float32), spacings.count * size_of(float32), spacings.data);




    gl_bind_vertex_array(0);

    return index, true;
}

/*

so this function is kinda sketchy right now, you can only rebuffer an object if it takes up the exact same size,
if you're rebuffering things and using up more space then you did before you'll start having undefined behavior in rendering and things
will go off the rails.

*/
rebuffer_object :: (using renderer : *Animated_Mesh_Renderer, renderable : $T/interface Animated_Mesh_Renderable) {

    gl_bind_vertex_array(vertex_attribute_array_gl_handle);

    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, positions_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, renderable.object_index * size_of(Vector3), renderable.positions.count * size_of(Vector3), renderable.positions.data);

    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, normals_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, renderable.object_index * size_of(Vector3), renderable.normals.count * size_of(Vector3), renderable.normals.data);

    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, uvs_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, renderable.object_index * size_of(Vector2), renderable.uvs.count * size_of(Vector2), renderable.uvs.data);

    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, spacings_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, renderable.object_index * size_of(float32), renderable.spacings.count * size_of(float32), renderable.spacings.data);


    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, 0);
    gl_bind_vertex_array(0);
}

render :: (using renderer : *Animated_Mesh_Renderer, primitive_mode: GLenum = GL_TRIANGLES) {

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

Animated_Mesh_Vertex_Source :: #string END_Animated_Mesh_Vertex_Source
#version 330 core
// Generated from Jai procedure animated_mesh_vertex.
in vec3 position;
in vec3 normal;
in vec2 uv;
in float spacing;
out vec3 passthrough_position_in_world;
out vec3 passthrough_normal;
out vec2 passthrough_uv;
out float passthrough_spacing;
uniform mat4 world_to_clip;

void main() {
    gl_Position = (world_to_clip * vec4(position.x, position.y, position.z, 1.0));
    passthrough_position_in_world = position;
    passthrough_normal = normal;
    passthrough_uv = uv;
    passthrough_spacing = spacing;
}

END_Animated_Mesh_Vertex_Source

Animated_Mesh_Fragment_Source :: #string END_Animated_Mesh_Fragment_Source
#version 330 core
// Generated from Jai procedure animated_mesh_fragment.
struct Surface_Shader {
    vec3 radiance;
    vec3 transmittance;
};
in vec3 passthrough_position_in_world;
in vec3 passthrough_normal;
in vec2 passthrough_uv;
in float passthrough_spacing;
layout(location=0) out vec4 gpu_rendering_pipeline_stage_attachment_color;
uniform sampler2D image;
uniform vec2 first_offset;
uniform vec2 second_offset;
uniform float frame_mix;
uniform vec3 eye;
uniform vec3 direction;
uniform bool orthographic;
uniform bool volume;
uniform bool blend_axis_stacks;
uniform float emission;

float jai_volume_slice_distance(float spacing, float normal_dot_view, bool blend_axis_stacks) {
    float cosine = abs(normal_dot_view);
    float weight = 1.0;
    if (blend_axis_stacks) {
        weight = (cosine * cosine);
    }
    return ((spacing * weight) / max(cosine, 0.05));
}

Surface_Shader jai_surface_from_cache(vec4 value) {
    float transmission = (1.0 - value.w);
    return Surface_Shader(vec3(value.x, value.y, value.z), vec3(transmission, transmission, transmission));
}

float jai_surface_opacity(Surface_Shader surface) {
    float opacity = (1.0 - (((surface.transmittance.x + surface.transmittance.y) + surface.transmittance.z) / 3.0));
    return opacity;
}

vec4 jai_surface_to_volume_premultiplied_rgba(Surface_Shader surface, float distance) {
    if ((distance <= 0.0)) {
        return vec4(0.0, 0.0, 0.0, 0.0);
    }
    float opacity = clamp(jai_surface_opacity(surface), 0.0, 1.0);
    float integrated = (1.0 - pow((1.0 - opacity), distance));
    float scale = distance;
    if ((opacity > 0.000001)) {
        scale = (integrated / opacity);
    }
    return vec4((surface.radiance.x * scale), (surface.radiance.y * scale), (surface.radiance.z * scale), integrated);
}

void main() {
    vec4 first = texture(image, (passthrough_uv + first_offset));
    vec4 second = texture(image, (passthrough_uv + second_offset));
    vec4 color = mix(first, second, frame_mix);
    if (volume) {
        vec3 view = direction;
        if (!(orthographic)) {
            view = normalize((eye - passthrough_position_in_world));
        }
        float facing = dot(normalize(passthrough_normal), view);
        float distance = jai_volume_slice_distance(passthrough_spacing, facing, blend_axis_stacks);
        Surface_Shader surface = jai_surface_from_cache(color);
        color = jai_surface_to_volume_premultiplied_rgba(surface, distance);
    }
    gpu_rendering_pipeline_stage_attachment_color = vec4((color.x * emission), (color.y * emission), (color.z * emission), color.w);
}

END_Animated_Mesh_Fragment_Source
