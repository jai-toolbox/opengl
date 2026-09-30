// auto-generated renderer for shader: Camera_Per_Object_Transform_Packed_Texture_Light_Baked
// do not edit manually.


Camera_Per_Object_Transform_Packed_Texture_Light_Baked_Renderable :: struct {
    indices : [..] u32;
    object_index : u32;

    local_to_world_index : u32;

    positions: [..] Vector3;
    normals: [..] Vector3;
    tangents: [..] Vector4;
    base_color_factors: [..] Vector4;
    material_parameters: [..] Vector4;
    alpha_parameters: [..] Vector2;
    base_color_and_normal_texture_coordinates: [..] Vector4;
    metallic_roughness_and_ambient_occlusion_texture_coordinates: [..] Vector4;
    emissive_and_lightmap_texture_coordinates: [..] Vector4;
    emissive_factors: [..] Vector3;
    base_color_and_normal_texture_indices: [..] [4] u32;
    metallic_roughness_and_ambient_occlusion_texture_indices: [..] [4] u32;
    emissive_and_lightmap_texture_indices: [..] [4] u32;

}


Camera_Per_Object_Transform_Packed_Texture_Light_Baked_Geometry :: struct {
    indices : [..] u32;
    positions: [..] Vector3;
    normals: [..] Vector3;
    tangents: [..] Vector4;
    base_color_factors: [..] Vector4;
    material_parameters: [..] Vector4;
    alpha_parameters: [..] Vector2;
    base_color_and_normal_texture_coordinates: [..] Vector4;
    metallic_roughness_and_ambient_occlusion_texture_coordinates: [..] Vector4;
    emissive_and_lightmap_texture_coordinates: [..] Vector4;
    emissive_factors: [..] Vector3;
    base_color_and_normal_texture_indices: [..] [4] u32;
    metallic_roughness_and_ambient_occlusion_texture_indices: [..] [4] u32;
    emissive_and_lightmap_texture_indices: [..] [4] u32;
}

assign_geometry_copy :: (renderable: *Camera_Per_Object_Transform_Packed_Texture_Light_Baked_Renderable, geometry: $T/interface Camera_Per_Object_Transform_Packed_Texture_Light_Baked_Geometry) {
    array_copy(*renderable.indices, geometry.indices);
    array_copy(*renderable.positions, geometry.positions);
    array_copy(*renderable.normals, geometry.normals);
    array_copy(*renderable.tangents, geometry.tangents);
    array_copy(*renderable.base_color_factors, geometry.base_color_factors);
    array_copy(*renderable.material_parameters, geometry.material_parameters);
    array_copy(*renderable.alpha_parameters, geometry.alpha_parameters);
    array_copy(*renderable.base_color_and_normal_texture_coordinates, geometry.base_color_and_normal_texture_coordinates);
    array_copy(*renderable.metallic_roughness_and_ambient_occlusion_texture_coordinates, geometry.metallic_roughness_and_ambient_occlusion_texture_coordinates);
    array_copy(*renderable.emissive_and_lightmap_texture_coordinates, geometry.emissive_and_lightmap_texture_coordinates);
    array_copy(*renderable.emissive_factors, geometry.emissive_factors);
    array_copy(*renderable.base_color_and_normal_texture_indices, geometry.base_color_and_normal_texture_indices);
    array_copy(*renderable.metallic_roughness_and_ambient_occlusion_texture_indices, geometry.metallic_roughness_and_ambient_occlusion_texture_indices);
    array_copy(*renderable.emissive_and_lightmap_texture_indices, geometry.emissive_and_lightmap_texture_indices);
}

assign_geometry :: (renderable: *Camera_Per_Object_Transform_Packed_Texture_Light_Baked_Renderable, geometry: $T/interface Camera_Per_Object_Transform_Packed_Texture_Light_Baked_Geometry) {
    renderable.indices = geometry.indices;
    renderable.positions = geometry.positions;
    renderable.normals = geometry.normals;
    renderable.tangents = geometry.tangents;
    renderable.base_color_factors = geometry.base_color_factors;
    renderable.material_parameters = geometry.material_parameters;
    renderable.alpha_parameters = geometry.alpha_parameters;
    renderable.base_color_and_normal_texture_coordinates = geometry.base_color_and_normal_texture_coordinates;
    renderable.metallic_roughness_and_ambient_occlusion_texture_coordinates = geometry.metallic_roughness_and_ambient_occlusion_texture_coordinates;
    renderable.emissive_and_lightmap_texture_coordinates = geometry.emissive_and_lightmap_texture_coordinates;
    renderable.emissive_factors = geometry.emissive_factors;
    renderable.base_color_and_normal_texture_indices = geometry.base_color_and_normal_texture_indices;
    renderable.metallic_roughness_and_ambient_occlusion_texture_indices = geometry.metallic_roughness_and_ambient_occlusion_texture_indices;
    renderable.emissive_and_lightmap_texture_indices = geometry.emissive_and_lightmap_texture_indices;
}


deinit :: (renderable: *Camera_Per_Object_Transform_Packed_Texture_Light_Baked_Renderable) {
    array_free(renderable.indices);
    array_free(renderable.positions);
    array_free(renderable.normals);
    array_free(renderable.tangents);
    array_free(renderable.base_color_factors);
    array_free(renderable.material_parameters);
    array_free(renderable.alpha_parameters);
    array_free(renderable.base_color_and_normal_texture_coordinates);
    array_free(renderable.metallic_roughness_and_ambient_occlusion_texture_coordinates);
    array_free(renderable.emissive_and_lightmap_texture_coordinates);
    array_free(renderable.emissive_factors);
    array_free(renderable.base_color_and_normal_texture_indices);
    array_free(renderable.metallic_roughness_and_ambient_occlusion_texture_indices);
    array_free(renderable.emissive_and_lightmap_texture_indices);
}

/*

so deinit exists but also unbuffer object exists, the difference is that deinit takes in a renderable and frees its CPU-side arrays and resets its transform slot, whereas unbuffer_object only frees the GPU-side virtual allocation, leaving the CPU data intact for potential re-buffering later.

*/
deinit :: (renderable: *Camera_Per_Object_Transform_Packed_Texture_Light_Baked_Renderable, renderer: *Camera_Per_Object_Transform_Packed_Texture_Light_Baked_Renderer) {
    unbuffer_object(*renderer.psr, renderable.object_index);
    free_index(*renderer.ltw_pool, renderable.local_to_world_index);
    renderable.local_to_world_index = 0;
    renderable.object_index = 0;
    array_free(renderable.indices);
    array_free(renderable.positions);
    array_free(renderable.normals);
    array_free(renderable.tangents);
    array_free(renderable.base_color_factors);
    array_free(renderable.material_parameters);
    array_free(renderable.alpha_parameters);
    array_free(renderable.base_color_and_normal_texture_coordinates);
    array_free(renderable.metallic_roughness_and_ambient_occlusion_texture_coordinates);
    array_free(renderable.emissive_and_lightmap_texture_coordinates);
    array_free(renderable.emissive_factors);
    array_free(renderable.base_color_and_normal_texture_indices);
    array_free(renderable.metallic_roughness_and_ambient_occlusion_texture_indices);
    array_free(renderable.emissive_and_lightmap_texture_indices);
}


unbuffer_object :: (renderer: *Camera_Per_Object_Transform_Packed_Texture_Light_Baked_Renderer, renderable: *Camera_Per_Object_Transform_Packed_Texture_Light_Baked_Renderable) {
    unbuffer_object(*renderer.psr, renderable.object_index);
    free_index(*renderer.ltw_pool, renderable.local_to_world_index);
    renderable.local_to_world_index = 0;
    renderable.object_index = 0;
}


queue_render :: (using renderer: *Camera_Per_Object_Transform_Packed_Texture_Light_Baked_Renderer, renderable: Camera_Per_Object_Transform_Packed_Texture_Light_Baked_Renderable) {
    queue_render(*renderer.psr, renderable.object_index);
}


set_local_to_world_matrix :: (renderer: *Camera_Per_Object_Transform_Packed_Texture_Light_Baked_Renderer, renderable: Camera_Per_Object_Transform_Packed_Texture_Light_Baked_Renderable, matrix: Matrix4) {
    set_matrix(*renderer.ltw_pool, renderable.local_to_world_index, matrix);
}


Camera_Per_Object_Transform_Packed_Texture_Light_Baked_Renderer :: struct {
    using #as psr : Per_Shader_Renderer;


    using #as ltw_pool : Local_To_World_Matrix_Pool;

    local_to_world_index_buffer_gl_handle : GLuint;


    camera_to_clip_uniform_location : GLint = -1;
    world_to_camera_uniform_location : GLint = -1;
    camera_position_uniform_location : GLint = -1;
    packed_textures_uniform_location : GLint = -1;
    packed_texture_bounding_boxes_uniform_location : GLint = -1;
    exposure_uniform_location : GLint = -1;
    lightmap_textures_uniform_location : GLint = -1;
    static_point_light_count_uniform_location : GLint = -1;
    reflection_probe_cubemap_0_uniform_location : GLint = -1;
    reflection_probe_cubemap_1_uniform_location : GLint = -1;
    reflection_probe_cubemap_2_uniform_location : GLint = -1;
    reflection_probe_cubemap_3_uniform_location : GLint = -1;
    reflection_probe_cubemap_4_uniform_location : GLint = -1;
    reflection_probe_cubemap_5_uniform_location : GLint = -1;
    reflection_probe_cubemap_6_uniform_location : GLint = -1;
    reflection_probe_cubemap_7_uniform_location : GLint = -1;
    reflection_probe_count_uniform_location : GLint = -1;
    reflection_probe_max_mip_uniform_location : GLint = -1;

    positions_buffer_gl_handle: GLuint;
    passthrough_normals_buffer_gl_handle: GLuint;
    passthrough_tangents_buffer_gl_handle: GLuint;
    passthrough_base_color_factors_buffer_gl_handle: GLuint;
    passthrough_material_parameters_buffer_gl_handle: GLuint;
    passthrough_alpha_parameters_buffer_gl_handle: GLuint;
    passthrough_base_color_and_normal_texture_coordinates_buffer_gl_handle: GLuint;
    passthrough_metallic_roughness_and_ambient_occlusion_texture_coordinates_buffer_gl_handle: GLuint;
    passthrough_emissive_and_lightmap_texture_coordinates_buffer_gl_handle: GLuint;
    passthrough_emissive_factors_buffer_gl_handle: GLuint;
    passthrough_base_color_and_normal_texture_indices_buffer_gl_handle: GLuint;
    passthrough_metallic_roughness_and_ambient_occlusion_texture_indices_buffer_gl_handle: GLuint;
    passthrough_emissive_and_lightmap_texture_indices_buffer_gl_handle: GLuint;


}


set_camera_to_clip_uniform :: (renderer : *Camera_Per_Object_Transform_Packed_Texture_Light_Baked_Renderer, v: Matrix4) {
    gl_set_uniform_matrix_4fv_on_active_shader_program(renderer.camera_to_clip_uniform_location, 1, GL_TRUE, *v.coef[0][0]);
}

set_world_to_camera_uniform :: (renderer : *Camera_Per_Object_Transform_Packed_Texture_Light_Baked_Renderer, v: Matrix4) {
    gl_set_uniform_matrix_4fv_on_active_shader_program(renderer.world_to_camera_uniform_location, 1, GL_TRUE, *v.coef[0][0]);
}

set_camera_position_uniform :: (renderer : *Camera_Per_Object_Transform_Packed_Texture_Light_Baked_Renderer, v: Vector3) {
    gl_set_uniform_3f_on_active_shader_program(renderer.camera_position_uniform_location, v.x, v.y, v.z);
}

set_packed_textures_uniform :: (renderer : *Camera_Per_Object_Transform_Packed_Texture_Light_Baked_Renderer, v: s32) {
    gl_set_uniform_1i_on_active_shader_program(renderer.packed_textures_uniform_location, v);
}

set_packed_texture_bounding_boxes_uniform :: (renderer : *Camera_Per_Object_Transform_Packed_Texture_Light_Baked_Renderer, v: s32) {
    gl_set_uniform_1i_on_active_shader_program(renderer.packed_texture_bounding_boxes_uniform_location, v);
}

set_exposure_uniform :: (renderer : *Camera_Per_Object_Transform_Packed_Texture_Light_Baked_Renderer, v: float32) {
    gl_set_uniform_1f_on_active_shader_program(renderer.exposure_uniform_location, v);
}

set_lightmap_textures_uniform :: (renderer : *Camera_Per_Object_Transform_Packed_Texture_Light_Baked_Renderer, v: s32) {
    gl_set_uniform_1i_on_active_shader_program(renderer.lightmap_textures_uniform_location, v);
}

set_static_point_light_count_uniform :: (renderer : *Camera_Per_Object_Transform_Packed_Texture_Light_Baked_Renderer, v: s32) {
    gl_set_uniform_1i_on_active_shader_program(renderer.static_point_light_count_uniform_location, v);
}

set_reflection_probe_cubemap_0_uniform :: (renderer : *Camera_Per_Object_Transform_Packed_Texture_Light_Baked_Renderer, v: s32) {
    gl_set_uniform_1i_on_active_shader_program(renderer.reflection_probe_cubemap_0_uniform_location, v);
}

set_reflection_probe_cubemap_1_uniform :: (renderer : *Camera_Per_Object_Transform_Packed_Texture_Light_Baked_Renderer, v: s32) {
    gl_set_uniform_1i_on_active_shader_program(renderer.reflection_probe_cubemap_1_uniform_location, v);
}

set_reflection_probe_cubemap_2_uniform :: (renderer : *Camera_Per_Object_Transform_Packed_Texture_Light_Baked_Renderer, v: s32) {
    gl_set_uniform_1i_on_active_shader_program(renderer.reflection_probe_cubemap_2_uniform_location, v);
}

set_reflection_probe_cubemap_3_uniform :: (renderer : *Camera_Per_Object_Transform_Packed_Texture_Light_Baked_Renderer, v: s32) {
    gl_set_uniform_1i_on_active_shader_program(renderer.reflection_probe_cubemap_3_uniform_location, v);
}

set_reflection_probe_cubemap_4_uniform :: (renderer : *Camera_Per_Object_Transform_Packed_Texture_Light_Baked_Renderer, v: s32) {
    gl_set_uniform_1i_on_active_shader_program(renderer.reflection_probe_cubemap_4_uniform_location, v);
}

set_reflection_probe_cubemap_5_uniform :: (renderer : *Camera_Per_Object_Transform_Packed_Texture_Light_Baked_Renderer, v: s32) {
    gl_set_uniform_1i_on_active_shader_program(renderer.reflection_probe_cubemap_5_uniform_location, v);
}

set_reflection_probe_cubemap_6_uniform :: (renderer : *Camera_Per_Object_Transform_Packed_Texture_Light_Baked_Renderer, v: s32) {
    gl_set_uniform_1i_on_active_shader_program(renderer.reflection_probe_cubemap_6_uniform_location, v);
}

set_reflection_probe_cubemap_7_uniform :: (renderer : *Camera_Per_Object_Transform_Packed_Texture_Light_Baked_Renderer, v: s32) {
    gl_set_uniform_1i_on_active_shader_program(renderer.reflection_probe_cubemap_7_uniform_location, v);
}

set_reflection_probe_count_uniform :: (renderer : *Camera_Per_Object_Transform_Packed_Texture_Light_Baked_Renderer, v: s32) {
    gl_set_uniform_1i_on_active_shader_program(renderer.reflection_probe_count_uniform_location, v);
}

set_reflection_probe_max_mip_uniform :: (renderer : *Camera_Per_Object_Transform_Packed_Texture_Light_Baked_Renderer, v: float32) {
    gl_set_uniform_1f_on_active_shader_program(renderer.reflection_probe_max_mip_uniform_location, v);
}

init :: (using renderer : *Camera_Per_Object_Transform_Packed_Texture_Light_Baked_Renderer) {
    vertex_shader_source := #run read_entire_file(tprint("%../shaders/out/camera_per_object_transform_packed_texture_light_baked.vert", #filepath));
    fragment_shader_source := #run read_entire_file(tprint("%../shaders/out/camera_per_object_transform_packed_texture_light_baked.frag", #filepath));

    init(renderer, vertex_shader_source, fragment_shader_source, max_num_elements_in_each_buffer);
    init_buffers_no_data(renderer);

    init(*renderer.ltw_pool);

    camera_to_clip_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "camera_to_clip");
    world_to_camera_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "world_to_camera");
    camera_position_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "camera_position");
    packed_textures_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "packed_textures");
    packed_texture_bounding_boxes_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "packed_texture_bounding_boxes");
    exposure_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "exposure");
    lightmap_textures_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lightmap_textures");
    static_point_light_count_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "static_point_light_count");
    reflection_probe_cubemap_0_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "reflection_probe_cubemap_0");
    reflection_probe_cubemap_1_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "reflection_probe_cubemap_1");
    reflection_probe_cubemap_2_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "reflection_probe_cubemap_2");
    reflection_probe_cubemap_3_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "reflection_probe_cubemap_3");
    reflection_probe_cubemap_4_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "reflection_probe_cubemap_4");
    reflection_probe_cubemap_5_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "reflection_probe_cubemap_5");
    reflection_probe_cubemap_6_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "reflection_probe_cubemap_6");
    reflection_probe_cubemap_7_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "reflection_probe_cubemap_7");
    reflection_probe_count_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "reflection_probe_count");
    reflection_probe_max_mip_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "reflection_probe_max_mip");

}


deinit :: (using renderer : *Camera_Per_Object_Transform_Packed_Texture_Light_Baked_Renderer) {
    deinit(*ltw_pool);

    deinit(*psr);

    gl_delete_buffer(positions_buffer_gl_handle);
    gl_delete_buffer(passthrough_normals_buffer_gl_handle);
    gl_delete_buffer(passthrough_tangents_buffer_gl_handle);
    gl_delete_buffer(passthrough_base_color_factors_buffer_gl_handle);
    gl_delete_buffer(passthrough_material_parameters_buffer_gl_handle);
    gl_delete_buffer(passthrough_alpha_parameters_buffer_gl_handle);
    gl_delete_buffer(passthrough_base_color_and_normal_texture_coordinates_buffer_gl_handle);
    gl_delete_buffer(passthrough_metallic_roughness_and_ambient_occlusion_texture_coordinates_buffer_gl_handle);
    gl_delete_buffer(passthrough_emissive_and_lightmap_texture_coordinates_buffer_gl_handle);
    gl_delete_buffer(passthrough_emissive_factors_buffer_gl_handle);
    gl_delete_buffer(passthrough_base_color_and_normal_texture_indices_buffer_gl_handle);
    gl_delete_buffer(passthrough_metallic_roughness_and_ambient_occlusion_texture_indices_buffer_gl_handle);
    gl_delete_buffer(passthrough_emissive_and_lightmap_texture_indices_buffer_gl_handle);
    gl_delete_buffer(local_to_world_index_buffer_gl_handle);
}



init_buffers_no_data :: (using apcr : *Camera_Per_Object_Transform_Packed_Texture_Light_Baked_Renderer) { // todo change renderer name

    vertex_attribute_array_gl_handle = gl_create_vertex_array();
    gl_bind_vertex_array(vertex_attribute_array_gl_handle);


    generate_buffer_for_vertex_attribute(*local_to_world_index_buffer_gl_handle, u32, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, local_to_world_index_buffer_gl_handle, "local_to_world_index", 1, GL_UNSIGNED_INT, GL_FALSE, 0, null);



    index_buffer_gl_handle = gl_create_buffer();
    gl_bind_buffer_to_binding_target(GL_ELEMENT_ARRAY_BUFFER, index_buffer_gl_handle);
    // NOTE: it's probably wrong to use  max_num_elements_in_each_buffer because as noted before the number of indices
    // could be larger than this value if we try and render all objects, but we won't care about that until it's a problem.
    gl_allocate_storage_for_buffer_bound_to_binding_target(GL_ELEMENT_ARRAY_BUFFER, size_of(u32) * max_num_elements_in_each_buffer, null, GL_DYNAMIC_DRAW);
    index_buffer_capacity_in_indices = cast(int) max_num_elements_in_each_buffer;
    // note: we don't have to init the vertex attribute for indices because they used in the shader program for rendering, they're just used during glDrawElements.

    generate_buffer_for_vertex_attribute(*positions_buffer_gl_handle, Vector3, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, positions_buffer_gl_handle, "position", 3, GL_FLOAT, GL_FALSE, 0, null);

    generate_buffer_for_vertex_attribute(*passthrough_normals_buffer_gl_handle, Vector3, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, passthrough_normals_buffer_gl_handle, "passthrough_normal", 3, GL_FLOAT, GL_FALSE, 0, null);

    generate_buffer_for_vertex_attribute(*passthrough_tangents_buffer_gl_handle, Vector4, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, passthrough_tangents_buffer_gl_handle, "passthrough_tangent", 4, GL_FLOAT, GL_FALSE, 0, null);

    generate_buffer_for_vertex_attribute(*passthrough_base_color_factors_buffer_gl_handle, Vector4, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, passthrough_base_color_factors_buffer_gl_handle, "passthrough_base_color_factor", 4, GL_FLOAT, GL_FALSE, 0, null);

    generate_buffer_for_vertex_attribute(*passthrough_material_parameters_buffer_gl_handle, Vector4, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, passthrough_material_parameters_buffer_gl_handle, "passthrough_material_parameters", 4, GL_FLOAT, GL_FALSE, 0, null);

    generate_buffer_for_vertex_attribute(*passthrough_alpha_parameters_buffer_gl_handle, Vector2, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, passthrough_alpha_parameters_buffer_gl_handle, "passthrough_alpha_parameters", 2, GL_FLOAT, GL_FALSE, 0, null);

    generate_buffer_for_vertex_attribute(*passthrough_base_color_and_normal_texture_coordinates_buffer_gl_handle, Vector4, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, passthrough_base_color_and_normal_texture_coordinates_buffer_gl_handle, "passthrough_base_color_and_normal_texture_coordinates", 4, GL_FLOAT, GL_FALSE, 0, null);

    generate_buffer_for_vertex_attribute(*passthrough_metallic_roughness_and_ambient_occlusion_texture_coordinates_buffer_gl_handle, Vector4, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, passthrough_metallic_roughness_and_ambient_occlusion_texture_coordinates_buffer_gl_handle, "passthrough_metallic_roughness_and_ambient_occlusion_texture_coordinates", 4, GL_FLOAT, GL_FALSE, 0, null);

    generate_buffer_for_vertex_attribute(*passthrough_emissive_and_lightmap_texture_coordinates_buffer_gl_handle, Vector4, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, passthrough_emissive_and_lightmap_texture_coordinates_buffer_gl_handle, "passthrough_emissive_and_lightmap_texture_coordinates", 4, GL_FLOAT, GL_FALSE, 0, null);

    generate_buffer_for_vertex_attribute(*passthrough_emissive_factors_buffer_gl_handle, Vector3, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, passthrough_emissive_factors_buffer_gl_handle, "passthrough_emissive_factor", 3, GL_FLOAT, GL_FALSE, 0, null);

    generate_buffer_for_vertex_attribute(*passthrough_base_color_and_normal_texture_indices_buffer_gl_handle, [4] u32, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, passthrough_base_color_and_normal_texture_indices_buffer_gl_handle, "passthrough_base_color_and_normal_texture_indices", 4, GL_UNSIGNED_INT, GL_FALSE, 0, null);

    generate_buffer_for_vertex_attribute(*passthrough_metallic_roughness_and_ambient_occlusion_texture_indices_buffer_gl_handle, [4] u32, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, passthrough_metallic_roughness_and_ambient_occlusion_texture_indices_buffer_gl_handle, "passthrough_metallic_roughness_and_ambient_occlusion_texture_indices", 4, GL_UNSIGNED_INT, GL_FALSE, 0, null);

    generate_buffer_for_vertex_attribute(*passthrough_emissive_and_lightmap_texture_indices_buffer_gl_handle, [4] u32, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, passthrough_emissive_and_lightmap_texture_indices_buffer_gl_handle, "passthrough_emissive_and_lightmap_texture_indices", 4, GL_UNSIGNED_INT, GL_FALSE, 0, null);



	gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, 0);
}


buffer_object :: (using renderer : *Camera_Per_Object_Transform_Packed_Texture_Light_Baked_Renderer, renderable : *$T/interface Camera_Per_Object_Transform_Packed_Texture_Light_Baked_Renderable) -> success: bool {


    object_index, local_to_world_index, success := buffer_object(renderer,
            renderable.indices,

            renderable.positions,
            renderable.normals,
            renderable.tangents,
            renderable.base_color_factors,
            renderable.material_parameters,
            renderable.alpha_parameters,
            renderable.base_color_and_normal_texture_coordinates,
            renderable.metallic_roughness_and_ambient_occlusion_texture_coordinates,
            renderable.emissive_and_lightmap_texture_coordinates,
            renderable.emissive_factors,
            renderable.base_color_and_normal_texture_indices,
            renderable.metallic_roughness_and_ambient_occlusion_texture_indices,
            renderable.emissive_and_lightmap_texture_indices
    );

    if success {
        renderable.object_index = object_index;
        renderable.local_to_world_index = local_to_world_index;

    };
    return success;
}

// todo ability to specify the transform matrix upon buffering?
buffer_object :: (
        using renderer: *Camera_Per_Object_Transform_Packed_Texture_Light_Baked_Renderer,
        indices : [..] u32,
        positions : [..] Vector3,
        normals : [..] Vector3,
        tangents : [..] Vector4,
        base_color_factors : [..] Vector4,
        material_parameters : [..] Vector4,
        alpha_parameters : [..] Vector2,
        base_color_and_normal_texture_coordinates : [..] Vector4,
        metallic_roughness_and_ambient_occlusion_texture_coordinates : [..] Vector4,
        emissive_and_lightmap_texture_coordinates : [..] Vector4,
        emissive_factors : [..] Vector3,
        base_color_and_normal_texture_indices : [..] [4] u32,
        metallic_roughness_and_ambient_occlusion_texture_indices : [..] [4] u32,
        emissive_and_lightmap_texture_indices : [..] [4] u32

        ) -> object_index: u32, local_to_world_index: u32, success: bool {

    /*
    note: we use the positions as count, becaues that is the actual data that needs to be in the buffer
    the indices use duplicates sometimes to refer to the same vertex multiple times.
    */
    length := positions.count; // todo: need to metaprogram this out, but it's pretty safe for now.
    index, success := virtual_alloc(*first_fit_virtual_allocator, xx length);
    if !success {
        log("ran out of virtual memory");
        return 0, 0, false;
    }

    global_indices_for_object : [..] u32;
    for indices
        array_add(*global_indices_for_object, xx index + it);

    table_add(*buffered_object_index_to_global_indices, xx index, global_indices_for_object);
    invalidate_cached_index_buffer(*renderer.psr);

    gl_bind_vertex_array(vertex_attribute_array_gl_handle);


    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, positions_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, index * size_of(Vector3), positions.count * size_of(Vector3), positions.data);



    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, passthrough_normals_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, index * size_of(Vector3), normals.count * size_of(Vector3), normals.data);



    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, passthrough_tangents_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, index * size_of(Vector4), tangents.count * size_of(Vector4), tangents.data);



    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, passthrough_base_color_factors_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, index * size_of(Vector4), base_color_factors.count * size_of(Vector4), base_color_factors.data);



    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, passthrough_material_parameters_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, index * size_of(Vector4), material_parameters.count * size_of(Vector4), material_parameters.data);



    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, passthrough_alpha_parameters_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, index * size_of(Vector2), alpha_parameters.count * size_of(Vector2), alpha_parameters.data);



    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, passthrough_base_color_and_normal_texture_coordinates_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, index * size_of(Vector4), base_color_and_normal_texture_coordinates.count * size_of(Vector4), base_color_and_normal_texture_coordinates.data);



    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, passthrough_metallic_roughness_and_ambient_occlusion_texture_coordinates_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, index * size_of(Vector4), metallic_roughness_and_ambient_occlusion_texture_coordinates.count * size_of(Vector4), metallic_roughness_and_ambient_occlusion_texture_coordinates.data);



    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, passthrough_emissive_and_lightmap_texture_coordinates_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, index * size_of(Vector4), emissive_and_lightmap_texture_coordinates.count * size_of(Vector4), emissive_and_lightmap_texture_coordinates.data);



    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, passthrough_emissive_factors_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, index * size_of(Vector3), emissive_factors.count * size_of(Vector3), emissive_factors.data);



    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, passthrough_base_color_and_normal_texture_indices_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, index * size_of([4] u32), base_color_and_normal_texture_indices.count * size_of([4] u32), base_color_and_normal_texture_indices.data);



    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, passthrough_metallic_roughness_and_ambient_occlusion_texture_indices_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, index * size_of([4] u32), metallic_roughness_and_ambient_occlusion_texture_indices.count * size_of([4] u32), metallic_roughness_and_ambient_occlusion_texture_indices.data);



    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, passthrough_emissive_and_lightmap_texture_indices_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, index * size_of([4] u32), emissive_and_lightmap_texture_indices.count * size_of([4] u32), emissive_and_lightmap_texture_indices.data);


    ltw_index_we_used, ltw_success := alloc_index(*ltw_pool);
    if !ltw_success {
        virtual_free(*first_fit_virtual_allocator, index);
        return 0, 0, false;
    }

    local_to_world_indices: [..] u32;
    for 0..positions.count-1 array_add(*local_to_world_indices, ltw_index_we_used);

    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, local_to_world_index_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, index * size_of(u32), local_to_world_indices.count * size_of(u32), local_to_world_indices.data);

    array_free(local_to_world_indices);


    gl_bind_vertex_array(0);

    return index, ltw_index_we_used, true;
}

/*

so this function is kinda sketchy right now, you can only rebuffer an object if it takes up the exact same size,
if you're rebuffering things and using up more space then you did before you'll start having undefined behavior in rendering and things
will go off the rails.

*/
rebuffer_object :: (using renderer : *Camera_Per_Object_Transform_Packed_Texture_Light_Baked_Renderer, renderable : $T/interface Camera_Per_Object_Transform_Packed_Texture_Light_Baked_Renderable) {

    gl_bind_vertex_array(vertex_attribute_array_gl_handle);

    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, positions_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, renderable.object_index * size_of(Vector3), renderable.positions.count * size_of(Vector3), renderable.positions.data);

    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, passthrough_normals_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, renderable.object_index * size_of(Vector3), renderable.normals.count * size_of(Vector3), renderable.normals.data);

    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, passthrough_tangents_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, renderable.object_index * size_of(Vector4), renderable.tangents.count * size_of(Vector4), renderable.tangents.data);

    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, passthrough_base_color_factors_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, renderable.object_index * size_of(Vector4), renderable.base_color_factors.count * size_of(Vector4), renderable.base_color_factors.data);

    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, passthrough_material_parameters_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, renderable.object_index * size_of(Vector4), renderable.material_parameters.count * size_of(Vector4), renderable.material_parameters.data);

    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, passthrough_alpha_parameters_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, renderable.object_index * size_of(Vector2), renderable.alpha_parameters.count * size_of(Vector2), renderable.alpha_parameters.data);

    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, passthrough_base_color_and_normal_texture_coordinates_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, renderable.object_index * size_of(Vector4), renderable.base_color_and_normal_texture_coordinates.count * size_of(Vector4), renderable.base_color_and_normal_texture_coordinates.data);

    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, passthrough_metallic_roughness_and_ambient_occlusion_texture_coordinates_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, renderable.object_index * size_of(Vector4), renderable.metallic_roughness_and_ambient_occlusion_texture_coordinates.count * size_of(Vector4), renderable.metallic_roughness_and_ambient_occlusion_texture_coordinates.data);

    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, passthrough_emissive_and_lightmap_texture_coordinates_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, renderable.object_index * size_of(Vector4), renderable.emissive_and_lightmap_texture_coordinates.count * size_of(Vector4), renderable.emissive_and_lightmap_texture_coordinates.data);

    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, passthrough_emissive_factors_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, renderable.object_index * size_of(Vector3), renderable.emissive_factors.count * size_of(Vector3), renderable.emissive_factors.data);

    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, passthrough_base_color_and_normal_texture_indices_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, renderable.object_index * size_of([4] u32), renderable.base_color_and_normal_texture_indices.count * size_of([4] u32), renderable.base_color_and_normal_texture_indices.data);

    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, passthrough_metallic_roughness_and_ambient_occlusion_texture_indices_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, renderable.object_index * size_of([4] u32), renderable.metallic_roughness_and_ambient_occlusion_texture_indices.count * size_of([4] u32), renderable.metallic_roughness_and_ambient_occlusion_texture_indices.data);

    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, passthrough_emissive_and_lightmap_texture_indices_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, renderable.object_index * size_of([4] u32), renderable.emissive_and_lightmap_texture_indices.count * size_of([4] u32), renderable.emissive_and_lightmap_texture_indices.data);


    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, 0);
    gl_bind_vertex_array(0);
}

render :: (using renderer : *Camera_Per_Object_Transform_Packed_Texture_Light_Baked_Renderer, primitive_mode: GLenum = GL_TRIANGLES) {

    // todo think about if we should be using temporary storage.

    gl_set_active_shader_program(shader_program_gl_handle);


    upload_to_gpu(*ltw_pool);



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
