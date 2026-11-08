// auto-generated renderer for shader: Blinn_Phong
// do not edit manually.

Blinn_Phong_Mesh_Vertex_Uniforms_Bindings :: struct {
    object_transforms: GLuint;
    world_to_camera: Matrix4;
    camera_to_clip: Matrix4;
}

Blinn_Phong_Packed_Material_Textures_Bindings :: struct {
    textures: GLuint;
    bounding_boxes: GLuint;
    materials: GLuint;
}

Blinn_Phong_Blinn_Phong_Fragment_Uniforms_Bindings :: struct {
    resources: Blinn_Phong_Packed_Material_Textures_Bindings;
    camera_position: Vector3;
    fallback_light_direction: Vector3;
    ambient: float32;
    specular_strength: float32;
    lights: Mesh_Lights;
}


Blinn_Phong_Renderable :: struct {
    indices : [..] u32;
    object_index : u32;

    positions: [..] Vector3;
    normals: [..] Vector3;
    tangents: [..] Vector3;
    uvs: [..] Vector2;
    material_indices: [..] s32;
    local_to_world_indices: [..] s32;

}


Blinn_Phong_Geometry :: struct {
    indices : [..] u32;
    positions: [..] Vector3;
    normals: [..] Vector3;
    tangents: [..] Vector3;
    uvs: [..] Vector2;
    material_indices: [..] s32;
    local_to_world_indices: [..] s32;
}

assign_geometry_copy :: (renderable: *Blinn_Phong_Renderable, geometry: $T/interface Blinn_Phong_Geometry) {
    array_copy(*renderable.indices, geometry.indices);
    array_copy(*renderable.positions, geometry.positions);
    array_copy(*renderable.normals, geometry.normals);
    array_copy(*renderable.tangents, geometry.tangents);
    array_copy(*renderable.uvs, geometry.uvs);
    array_copy(*renderable.material_indices, geometry.material_indices);
    array_copy(*renderable.local_to_world_indices, geometry.local_to_world_indices);
}

assign_geometry :: (renderable: *Blinn_Phong_Renderable, geometry: $T/interface Blinn_Phong_Geometry) {
    renderable.indices = geometry.indices;
    renderable.positions = geometry.positions;
    renderable.normals = geometry.normals;
    renderable.tangents = geometry.tangents;
    renderable.uvs = geometry.uvs;
    renderable.material_indices = geometry.material_indices;
    renderable.local_to_world_indices = geometry.local_to_world_indices;
}


deinit :: (renderable: *Blinn_Phong_Renderable) {
    array_free(renderable.indices);
    array_free(renderable.positions);
    array_free(renderable.normals);
    array_free(renderable.tangents);
    array_free(renderable.uvs);
    array_free(renderable.material_indices);
    array_free(renderable.local_to_world_indices);
}

/*

so deinit exists but also unbuffer object exists, the difference is that deinit takes in a renderable and frees its CPU-side arrays and resets its transform slot, whereas unbuffer_object only frees the GPU-side virtual allocation, leaving the CPU data intact for potential re-buffering later.

*/
deinit :: (renderable: *Blinn_Phong_Renderable, renderer: *Blinn_Phong_Renderer) {
    unbuffer_object(*renderer.psr, renderable.object_index);
    array_free(renderable.indices);
    array_free(renderable.positions);
    array_free(renderable.normals);
    array_free(renderable.tangents);
    array_free(renderable.uvs);
    array_free(renderable.material_indices);
    array_free(renderable.local_to_world_indices);
}


unbuffer_object :: (renderer: *Blinn_Phong_Renderer, renderable: *Blinn_Phong_Renderable) {
    unbuffer_object(*renderer.psr, renderable.object_index);
    renderable.object_index = 0;
}


queue_render :: (using renderer: *Blinn_Phong_Renderer, renderable: Blinn_Phong_Renderable) {
    queue_render(*renderer.psr, renderable.object_index);
}

// Indices are relative to this buffered object's first vertex.
update_object_indices :: (renderer : *Blinn_Phong_Renderer, object_index : u32, indices : [] u32) -> bool {
    return update_object_indices(*renderer.psr, object_index, indices);
}

update_object_indices :: (renderer : *Blinn_Phong_Renderer, renderable : $T/interface Blinn_Phong_Renderable, indices : [] u32) -> bool {
    return update_object_indices(renderer, renderable.object_index, indices);
}

queue_render :: (renderer : *Blinn_Phong_Renderer, object_index : u32) {
    queue_render(*renderer.psr, object_index);
}


unbuffer_object :: (renderer : *Blinn_Phong_Renderer, object_index : u32) {
    unbuffer_object(*renderer.psr, object_index);
}

buffer_object :: (renderer : *Blinn_Phong_Renderer, vertices : [] Mesh_Vertex, indices : [] u32) -> (object_index : u32, success : bool) {
    positions : [..] Vector3;
    defer array_free(positions);
    normals : [..] Vector3;
    defer array_free(normals);
    tangents : [..] Vector3;
    defer array_free(tangents);
    uvs : [..] Vector2;
    defer array_free(uvs);
    material_indices : [..] s32;
    defer array_free(material_indices);
    local_to_world_indices : [..] s32;
    defer array_free(local_to_world_indices);
    for vertex : vertices {
        array_add(*positions, vertex.position);
        array_add(*normals, vertex.normal);
        array_add(*tangents, vertex.tangent);
        array_add(*uvs, vertex.uv);
        array_add(*material_indices, vertex.material_index);
        array_add(*local_to_world_indices, vertex.local_to_world_index);
    }
    buffered_index, buffered := buffer_object(renderer, indices, positions, normals, tangents, uvs, material_indices, local_to_world_indices);
    return buffered_index, buffered;
}


Blinn_Phong_Renderer :: struct {
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
    typed_11_uniform_location : GLint = -1;
    typed_12_uniform_location : GLint = -1;
    typed_13_uniform_location : GLint = -1;
    typed_14_uniform_location : GLint = -1;
    typed_15_uniform_location : GLint = -1;
    typed_16_uniform_location : GLint = -1;
    typed_17_uniform_location : GLint = -1;
    typed_18_uniform_location : GLint = -1;
    typed_19_uniform_location : GLint = -1;
    typed_20_uniform_location : GLint = -1;
    typed_21_uniform_location : GLint = -1;
    typed_22_uniform_location : GLint = -1;
    typed_23_uniform_location : GLint = -1;
    typed_24_uniform_location : GLint = -1;
    typed_25_uniform_location : GLint = -1;
    typed_26_uniform_location : GLint = -1;
    typed_27_uniform_location : GLint = -1;
    typed_28_uniform_location : GLint = -1;
    typed_29_uniform_location : GLint = -1;
    typed_30_uniform_location : GLint = -1;
    typed_31_uniform_location : GLint = -1;
    typed_32_uniform_location : GLint = -1;
    typed_33_uniform_location : GLint = -1;
    typed_34_uniform_location : GLint = -1;
    typed_35_uniform_location : GLint = -1;
    typed_36_uniform_location : GLint = -1;
    typed_37_uniform_location : GLint = -1;
    typed_38_uniform_location : GLint = -1;
    typed_39_uniform_location : GLint = -1;
    typed_40_uniform_location : GLint = -1;
    typed_41_uniform_location : GLint = -1;
    typed_42_uniform_location : GLint = -1;
    typed_43_uniform_location : GLint = -1;
    typed_44_uniform_location : GLint = -1;
    typed_45_uniform_location : GLint = -1;
    typed_46_uniform_location : GLint = -1;
    typed_47_uniform_location : GLint = -1;
    typed_48_uniform_location : GLint = -1;
    typed_49_uniform_location : GLint = -1;
    typed_50_uniform_location : GLint = -1;
    typed_51_uniform_location : GLint = -1;
    typed_52_uniform_location : GLint = -1;
    typed_53_uniform_location : GLint = -1;
    typed_54_uniform_location : GLint = -1;
    typed_55_uniform_location : GLint = -1;
    typed_56_uniform_location : GLint = -1;
    typed_57_uniform_location : GLint = -1;
    typed_58_uniform_location : GLint = -1;
    typed_59_uniform_location : GLint = -1;
    typed_60_uniform_location : GLint = -1;
    typed_61_uniform_location : GLint = -1;
    typed_62_uniform_location : GLint = -1;
    typed_63_uniform_location : GLint = -1;
    typed_64_uniform_location : GLint = -1;
    typed_65_uniform_location : GLint = -1;
    typed_66_uniform_location : GLint = -1;
    typed_67_uniform_location : GLint = -1;
    typed_68_uniform_location : GLint = -1;
    typed_69_uniform_location : GLint = -1;
    typed_70_uniform_location : GLint = -1;
    typed_71_uniform_location : GLint = -1;
    typed_72_uniform_location : GLint = -1;
    typed_73_uniform_location : GLint = -1;
    typed_74_uniform_location : GLint = -1;
    typed_75_uniform_location : GLint = -1;
    typed_76_uniform_location : GLint = -1;
    typed_77_uniform_location : GLint = -1;
    typed_78_uniform_location : GLint = -1;
    typed_79_uniform_location : GLint = -1;
    typed_80_uniform_location : GLint = -1;
    typed_81_uniform_location : GLint = -1;
    typed_82_uniform_location : GLint = -1;
    typed_83_uniform_location : GLint = -1;
    typed_84_uniform_location : GLint = -1;
    typed_85_uniform_location : GLint = -1;
    typed_86_uniform_location : GLint = -1;
    typed_87_uniform_location : GLint = -1;
    typed_88_uniform_location : GLint = -1;
    typed_89_uniform_location : GLint = -1;
    typed_90_uniform_location : GLint = -1;
    typed_91_uniform_location : GLint = -1;
    typed_92_uniform_location : GLint = -1;
    typed_93_uniform_location : GLint = -1;
    typed_94_uniform_location : GLint = -1;
    typed_95_uniform_location : GLint = -1;
    typed_96_uniform_location : GLint = -1;
    typed_97_uniform_location : GLint = -1;
    typed_98_uniform_location : GLint = -1;
    typed_99_uniform_location : GLint = -1;
    typed_100_uniform_location : GLint = -1;
    typed_101_uniform_location : GLint = -1;
    typed_102_uniform_location : GLint = -1;
    typed_103_uniform_location : GLint = -1;
    typed_104_uniform_location : GLint = -1;
    typed_105_uniform_location : GLint = -1;
    typed_106_uniform_location : GLint = -1;
    typed_107_uniform_location : GLint = -1;
    typed_108_uniform_location : GLint = -1;
    typed_109_uniform_location : GLint = -1;
    typed_110_uniform_location : GLint = -1;
    typed_111_uniform_location : GLint = -1;
    typed_112_uniform_location : GLint = -1;
    typed_113_uniform_location : GLint = -1;
    typed_114_uniform_location : GLint = -1;
    typed_115_uniform_location : GLint = -1;
    typed_116_uniform_location : GLint = -1;
    typed_117_uniform_location : GLint = -1;
    typed_118_uniform_location : GLint = -1;
    typed_119_uniform_location : GLint = -1;
    typed_120_uniform_location : GLint = -1;
    typed_121_uniform_location : GLint = -1;
    typed_122_uniform_location : GLint = -1;
    typed_123_uniform_location : GLint = -1;
    typed_124_uniform_location : GLint = -1;
    typed_125_uniform_location : GLint = -1;
    typed_126_uniform_location : GLint = -1;
    typed_127_uniform_location : GLint = -1;
    typed_128_uniform_location : GLint = -1;
    typed_129_uniform_location : GLint = -1;
    typed_130_uniform_location : GLint = -1;
    typed_131_uniform_location : GLint = -1;
    typed_132_uniform_location : GLint = -1;
    typed_133_uniform_location : GLint = -1;
    typed_134_uniform_location : GLint = -1;
    typed_135_uniform_location : GLint = -1;
    typed_136_uniform_location : GLint = -1;
    typed_137_uniform_location : GLint = -1;
    typed_138_uniform_location : GLint = -1;
    typed_139_uniform_location : GLint = -1;
    typed_140_uniform_location : GLint = -1;
    typed_141_uniform_location : GLint = -1;
    typed_142_uniform_location : GLint = -1;
    typed_143_uniform_location : GLint = -1;
    typed_144_uniform_location : GLint = -1;
    typed_145_uniform_location : GLint = -1;
    typed_146_uniform_location : GLint = -1;
    typed_147_uniform_location : GLint = -1;
    typed_148_uniform_location : GLint = -1;
    typed_149_uniform_location : GLint = -1;
    typed_150_uniform_location : GLint = -1;
    typed_151_uniform_location : GLint = -1;
    typed_152_uniform_location : GLint = -1;
    typed_153_uniform_location : GLint = -1;
    typed_154_uniform_location : GLint = -1;
    typed_155_uniform_location : GLint = -1;
    typed_156_uniform_location : GLint = -1;
    typed_157_uniform_location : GLint = -1;
    typed_158_uniform_location : GLint = -1;
    typed_159_uniform_location : GLint = -1;
    typed_160_uniform_location : GLint = -1;
    typed_161_uniform_location : GLint = -1;
    typed_162_uniform_location : GLint = -1;
    typed_163_uniform_location : GLint = -1;
    typed_164_uniform_location : GLint = -1;
    typed_165_uniform_location : GLint = -1;
    typed_166_uniform_location : GLint = -1;
    typed_167_uniform_location : GLint = -1;
    typed_168_uniform_location : GLint = -1;
    typed_169_uniform_location : GLint = -1;
    typed_170_uniform_location : GLint = -1;
    typed_171_uniform_location : GLint = -1;
    typed_172_uniform_location : GLint = -1;
    typed_173_uniform_location : GLint = -1;
    typed_174_uniform_location : GLint = -1;
    typed_175_uniform_location : GLint = -1;
    typed_176_uniform_location : GLint = -1;
    typed_177_uniform_location : GLint = -1;
    typed_178_uniform_location : GLint = -1;
    typed_179_uniform_location : GLint = -1;
    typed_180_uniform_location : GLint = -1;
    typed_181_uniform_location : GLint = -1;
    typed_182_uniform_location : GLint = -1;
    typed_183_uniform_location : GLint = -1;
    typed_184_uniform_location : GLint = -1;
    typed_185_uniform_location : GLint = -1;
    typed_186_uniform_location : GLint = -1;
    typed_187_uniform_location : GLint = -1;
    typed_188_uniform_location : GLint = -1;
    typed_189_uniform_location : GLint = -1;
    typed_190_uniform_location : GLint = -1;
    typed_191_uniform_location : GLint = -1;
    typed_192_uniform_location : GLint = -1;
    typed_193_uniform_location : GLint = -1;
    typed_194_uniform_location : GLint = -1;
    typed_195_uniform_location : GLint = -1;
    typed_196_uniform_location : GLint = -1;
    typed_197_uniform_location : GLint = -1;
    typed_198_uniform_location : GLint = -1;
    typed_199_uniform_location : GLint = -1;
    typed_200_uniform_location : GLint = -1;
    typed_201_uniform_location : GLint = -1;
    typed_202_uniform_location : GLint = -1;
    typed_203_uniform_location : GLint = -1;
    typed_204_uniform_location : GLint = -1;
    typed_205_uniform_location : GLint = -1;
    typed_206_uniform_location : GLint = -1;
    typed_207_uniform_location : GLint = -1;
    typed_208_uniform_location : GLint = -1;
    typed_209_uniform_location : GLint = -1;
    typed_210_uniform_location : GLint = -1;
    typed_211_uniform_location : GLint = -1;
    typed_212_uniform_location : GLint = -1;
    typed_213_uniform_location : GLint = -1;
    typed_214_uniform_location : GLint = -1;
    typed_215_uniform_location : GLint = -1;
    typed_216_uniform_location : GLint = -1;
    typed_217_uniform_location : GLint = -1;
    typed_218_uniform_location : GLint = -1;
    typed_219_uniform_location : GLint = -1;
    typed_220_uniform_location : GLint = -1;
    typed_221_uniform_location : GLint = -1;
    typed_222_uniform_location : GLint = -1;
    typed_223_uniform_location : GLint = -1;
    typed_224_uniform_location : GLint = -1;
    typed_225_uniform_location : GLint = -1;
    typed_226_uniform_location : GLint = -1;
    typed_227_uniform_location : GLint = -1;
    typed_228_uniform_location : GLint = -1;
    typed_229_uniform_location : GLint = -1;
    typed_230_uniform_location : GLint = -1;
    typed_231_uniform_location : GLint = -1;
    typed_232_uniform_location : GLint = -1;
    typed_233_uniform_location : GLint = -1;
    typed_234_uniform_location : GLint = -1;
    typed_235_uniform_location : GLint = -1;
    typed_236_uniform_location : GLint = -1;

    positions_buffer_gl_handle: GLuint;
    normals_buffer_gl_handle: GLuint;
    tangents_buffer_gl_handle: GLuint;
    uvs_buffer_gl_handle: GLuint;
    material_indices_buffer_gl_handle: GLuint;
    local_to_world_indices_buffer_gl_handle: GLuint;


}

set_uniforms :: (renderer: *Blinn_Phong_Renderer, ctx: Blinn_Phong_Mesh_Vertex_Uniforms_Bindings) {
    gl_set_active_shader_program(renderer.shader_program_gl_handle);
    gl_set_active_texture_unit(GL_TEXTURE0 + 0);
    gl_bind_texture_to_binding_target_of_active_texture_unit(GL_TEXTURE_2D,ctx.object_transforms);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_0_uniform_location,0);
    gl_set_uniform_matrix_4fv_on_active_shader_program(renderer.typed_1_uniform_location, 1, GL_TRUE, *ctx.world_to_camera.coef[0][0]);
    gl_set_uniform_matrix_4fv_on_active_shader_program(renderer.typed_2_uniform_location, 1, GL_TRUE, *ctx.camera_to_clip.coef[0][0]);
    gl_set_active_texture_unit(GL_TEXTURE0);
    gl_clear_active_shader_program();
}

set_uniforms :: (renderer: *Blinn_Phong_Renderer, ctx: Blinn_Phong_Blinn_Phong_Fragment_Uniforms_Bindings) {
    gl_set_active_shader_program(renderer.shader_program_gl_handle);
    gl_set_active_texture_unit(GL_TEXTURE0 + 1);
    gl_bind_texture_to_binding_target_of_active_texture_unit(GL_TEXTURE_2D_ARRAY,ctx.resources.textures);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_3_uniform_location,1);
    gl_set_active_texture_unit(GL_TEXTURE0 + 2);
    gl_bind_texture_to_binding_target_of_active_texture_unit(GL_TEXTURE_1D,ctx.resources.bounding_boxes);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_4_uniform_location,2);
    gl_set_active_texture_unit(GL_TEXTURE0 + 3);
    gl_bind_texture_to_binding_target_of_active_texture_unit(GL_TEXTURE_1D,ctx.resources.materials);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_5_uniform_location,3);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_6_uniform_location, ctx.camera_position.x, ctx.camera_position.y, ctx.camera_position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_7_uniform_location, ctx.fallback_light_direction.x, ctx.fallback_light_direction.y, ctx.fallback_light_direction.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_8_uniform_location, ctx.ambient);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_9_uniform_location, ctx.specular_strength);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_10_uniform_location, ctx.lights.directional_count);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_11_uniform_location, ctx.lights.point_count);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_12_uniform_location, ctx.lights.spot_count);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_13_uniform_location, ctx.lights.directional[0].direction.x, ctx.lights.directional[0].direction.y, ctx.lights.directional[0].direction.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_14_uniform_location, ctx.lights.directional[0].color.x, ctx.lights.directional[0].color.y, ctx.lights.directional[0].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_15_uniform_location, ctx.lights.directional[0].intensity);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_16_uniform_location, xx ctx.lights.directional[0].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_17_uniform_location, ctx.lights.directional[1].direction.x, ctx.lights.directional[1].direction.y, ctx.lights.directional[1].direction.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_18_uniform_location, ctx.lights.directional[1].color.x, ctx.lights.directional[1].color.y, ctx.lights.directional[1].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_19_uniform_location, ctx.lights.directional[1].intensity);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_20_uniform_location, xx ctx.lights.directional[1].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_21_uniform_location, ctx.lights.directional[2].direction.x, ctx.lights.directional[2].direction.y, ctx.lights.directional[2].direction.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_22_uniform_location, ctx.lights.directional[2].color.x, ctx.lights.directional[2].color.y, ctx.lights.directional[2].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_23_uniform_location, ctx.lights.directional[2].intensity);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_24_uniform_location, xx ctx.lights.directional[2].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_25_uniform_location, ctx.lights.directional[3].direction.x, ctx.lights.directional[3].direction.y, ctx.lights.directional[3].direction.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_26_uniform_location, ctx.lights.directional[3].color.x, ctx.lights.directional[3].color.y, ctx.lights.directional[3].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_27_uniform_location, ctx.lights.directional[3].intensity);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_28_uniform_location, xx ctx.lights.directional[3].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_29_uniform_location, ctx.lights.point[0].position.x, ctx.lights.point[0].position.y, ctx.lights.point[0].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_30_uniform_location, ctx.lights.point[0].color.x, ctx.lights.point[0].color.y, ctx.lights.point[0].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_31_uniform_location, ctx.lights.point[0].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_32_uniform_location, ctx.lights.point[0].range);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_33_uniform_location, xx ctx.lights.point[0].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_34_uniform_location, ctx.lights.point[1].position.x, ctx.lights.point[1].position.y, ctx.lights.point[1].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_35_uniform_location, ctx.lights.point[1].color.x, ctx.lights.point[1].color.y, ctx.lights.point[1].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_36_uniform_location, ctx.lights.point[1].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_37_uniform_location, ctx.lights.point[1].range);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_38_uniform_location, xx ctx.lights.point[1].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_39_uniform_location, ctx.lights.point[2].position.x, ctx.lights.point[2].position.y, ctx.lights.point[2].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_40_uniform_location, ctx.lights.point[2].color.x, ctx.lights.point[2].color.y, ctx.lights.point[2].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_41_uniform_location, ctx.lights.point[2].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_42_uniform_location, ctx.lights.point[2].range);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_43_uniform_location, xx ctx.lights.point[2].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_44_uniform_location, ctx.lights.point[3].position.x, ctx.lights.point[3].position.y, ctx.lights.point[3].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_45_uniform_location, ctx.lights.point[3].color.x, ctx.lights.point[3].color.y, ctx.lights.point[3].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_46_uniform_location, ctx.lights.point[3].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_47_uniform_location, ctx.lights.point[3].range);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_48_uniform_location, xx ctx.lights.point[3].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_49_uniform_location, ctx.lights.point[4].position.x, ctx.lights.point[4].position.y, ctx.lights.point[4].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_50_uniform_location, ctx.lights.point[4].color.x, ctx.lights.point[4].color.y, ctx.lights.point[4].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_51_uniform_location, ctx.lights.point[4].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_52_uniform_location, ctx.lights.point[4].range);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_53_uniform_location, xx ctx.lights.point[4].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_54_uniform_location, ctx.lights.point[5].position.x, ctx.lights.point[5].position.y, ctx.lights.point[5].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_55_uniform_location, ctx.lights.point[5].color.x, ctx.lights.point[5].color.y, ctx.lights.point[5].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_56_uniform_location, ctx.lights.point[5].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_57_uniform_location, ctx.lights.point[5].range);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_58_uniform_location, xx ctx.lights.point[5].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_59_uniform_location, ctx.lights.point[6].position.x, ctx.lights.point[6].position.y, ctx.lights.point[6].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_60_uniform_location, ctx.lights.point[6].color.x, ctx.lights.point[6].color.y, ctx.lights.point[6].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_61_uniform_location, ctx.lights.point[6].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_62_uniform_location, ctx.lights.point[6].range);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_63_uniform_location, xx ctx.lights.point[6].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_64_uniform_location, ctx.lights.point[7].position.x, ctx.lights.point[7].position.y, ctx.lights.point[7].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_65_uniform_location, ctx.lights.point[7].color.x, ctx.lights.point[7].color.y, ctx.lights.point[7].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_66_uniform_location, ctx.lights.point[7].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_67_uniform_location, ctx.lights.point[7].range);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_68_uniform_location, xx ctx.lights.point[7].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_69_uniform_location, ctx.lights.point[8].position.x, ctx.lights.point[8].position.y, ctx.lights.point[8].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_70_uniform_location, ctx.lights.point[8].color.x, ctx.lights.point[8].color.y, ctx.lights.point[8].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_71_uniform_location, ctx.lights.point[8].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_72_uniform_location, ctx.lights.point[8].range);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_73_uniform_location, xx ctx.lights.point[8].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_74_uniform_location, ctx.lights.point[9].position.x, ctx.lights.point[9].position.y, ctx.lights.point[9].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_75_uniform_location, ctx.lights.point[9].color.x, ctx.lights.point[9].color.y, ctx.lights.point[9].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_76_uniform_location, ctx.lights.point[9].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_77_uniform_location, ctx.lights.point[9].range);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_78_uniform_location, xx ctx.lights.point[9].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_79_uniform_location, ctx.lights.point[10].position.x, ctx.lights.point[10].position.y, ctx.lights.point[10].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_80_uniform_location, ctx.lights.point[10].color.x, ctx.lights.point[10].color.y, ctx.lights.point[10].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_81_uniform_location, ctx.lights.point[10].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_82_uniform_location, ctx.lights.point[10].range);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_83_uniform_location, xx ctx.lights.point[10].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_84_uniform_location, ctx.lights.point[11].position.x, ctx.lights.point[11].position.y, ctx.lights.point[11].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_85_uniform_location, ctx.lights.point[11].color.x, ctx.lights.point[11].color.y, ctx.lights.point[11].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_86_uniform_location, ctx.lights.point[11].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_87_uniform_location, ctx.lights.point[11].range);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_88_uniform_location, xx ctx.lights.point[11].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_89_uniform_location, ctx.lights.point[12].position.x, ctx.lights.point[12].position.y, ctx.lights.point[12].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_90_uniform_location, ctx.lights.point[12].color.x, ctx.lights.point[12].color.y, ctx.lights.point[12].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_91_uniform_location, ctx.lights.point[12].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_92_uniform_location, ctx.lights.point[12].range);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_93_uniform_location, xx ctx.lights.point[12].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_94_uniform_location, ctx.lights.point[13].position.x, ctx.lights.point[13].position.y, ctx.lights.point[13].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_95_uniform_location, ctx.lights.point[13].color.x, ctx.lights.point[13].color.y, ctx.lights.point[13].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_96_uniform_location, ctx.lights.point[13].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_97_uniform_location, ctx.lights.point[13].range);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_98_uniform_location, xx ctx.lights.point[13].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_99_uniform_location, ctx.lights.point[14].position.x, ctx.lights.point[14].position.y, ctx.lights.point[14].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_100_uniform_location, ctx.lights.point[14].color.x, ctx.lights.point[14].color.y, ctx.lights.point[14].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_101_uniform_location, ctx.lights.point[14].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_102_uniform_location, ctx.lights.point[14].range);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_103_uniform_location, xx ctx.lights.point[14].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_104_uniform_location, ctx.lights.point[15].position.x, ctx.lights.point[15].position.y, ctx.lights.point[15].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_105_uniform_location, ctx.lights.point[15].color.x, ctx.lights.point[15].color.y, ctx.lights.point[15].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_106_uniform_location, ctx.lights.point[15].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_107_uniform_location, ctx.lights.point[15].range);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_108_uniform_location, xx ctx.lights.point[15].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_109_uniform_location, ctx.lights.spot[0].position.x, ctx.lights.spot[0].position.y, ctx.lights.spot[0].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_110_uniform_location, ctx.lights.spot[0].direction.x, ctx.lights.spot[0].direction.y, ctx.lights.spot[0].direction.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_111_uniform_location, ctx.lights.spot[0].color.x, ctx.lights.spot[0].color.y, ctx.lights.spot[0].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_112_uniform_location, ctx.lights.spot[0].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_113_uniform_location, ctx.lights.spot[0].range);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_114_uniform_location, ctx.lights.spot[0].inner_cos);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_115_uniform_location, ctx.lights.spot[0].outer_cos);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_116_uniform_location, xx ctx.lights.spot[0].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_117_uniform_location, ctx.lights.spot[1].position.x, ctx.lights.spot[1].position.y, ctx.lights.spot[1].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_118_uniform_location, ctx.lights.spot[1].direction.x, ctx.lights.spot[1].direction.y, ctx.lights.spot[1].direction.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_119_uniform_location, ctx.lights.spot[1].color.x, ctx.lights.spot[1].color.y, ctx.lights.spot[1].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_120_uniform_location, ctx.lights.spot[1].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_121_uniform_location, ctx.lights.spot[1].range);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_122_uniform_location, ctx.lights.spot[1].inner_cos);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_123_uniform_location, ctx.lights.spot[1].outer_cos);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_124_uniform_location, xx ctx.lights.spot[1].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_125_uniform_location, ctx.lights.spot[2].position.x, ctx.lights.spot[2].position.y, ctx.lights.spot[2].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_126_uniform_location, ctx.lights.spot[2].direction.x, ctx.lights.spot[2].direction.y, ctx.lights.spot[2].direction.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_127_uniform_location, ctx.lights.spot[2].color.x, ctx.lights.spot[2].color.y, ctx.lights.spot[2].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_128_uniform_location, ctx.lights.spot[2].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_129_uniform_location, ctx.lights.spot[2].range);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_130_uniform_location, ctx.lights.spot[2].inner_cos);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_131_uniform_location, ctx.lights.spot[2].outer_cos);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_132_uniform_location, xx ctx.lights.spot[2].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_133_uniform_location, ctx.lights.spot[3].position.x, ctx.lights.spot[3].position.y, ctx.lights.spot[3].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_134_uniform_location, ctx.lights.spot[3].direction.x, ctx.lights.spot[3].direction.y, ctx.lights.spot[3].direction.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_135_uniform_location, ctx.lights.spot[3].color.x, ctx.lights.spot[3].color.y, ctx.lights.spot[3].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_136_uniform_location, ctx.lights.spot[3].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_137_uniform_location, ctx.lights.spot[3].range);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_138_uniform_location, ctx.lights.spot[3].inner_cos);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_139_uniform_location, ctx.lights.spot[3].outer_cos);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_140_uniform_location, xx ctx.lights.spot[3].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_141_uniform_location, ctx.lights.spot[4].position.x, ctx.lights.spot[4].position.y, ctx.lights.spot[4].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_142_uniform_location, ctx.lights.spot[4].direction.x, ctx.lights.spot[4].direction.y, ctx.lights.spot[4].direction.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_143_uniform_location, ctx.lights.spot[4].color.x, ctx.lights.spot[4].color.y, ctx.lights.spot[4].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_144_uniform_location, ctx.lights.spot[4].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_145_uniform_location, ctx.lights.spot[4].range);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_146_uniform_location, ctx.lights.spot[4].inner_cos);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_147_uniform_location, ctx.lights.spot[4].outer_cos);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_148_uniform_location, xx ctx.lights.spot[4].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_149_uniform_location, ctx.lights.spot[5].position.x, ctx.lights.spot[5].position.y, ctx.lights.spot[5].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_150_uniform_location, ctx.lights.spot[5].direction.x, ctx.lights.spot[5].direction.y, ctx.lights.spot[5].direction.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_151_uniform_location, ctx.lights.spot[5].color.x, ctx.lights.spot[5].color.y, ctx.lights.spot[5].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_152_uniform_location, ctx.lights.spot[5].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_153_uniform_location, ctx.lights.spot[5].range);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_154_uniform_location, ctx.lights.spot[5].inner_cos);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_155_uniform_location, ctx.lights.spot[5].outer_cos);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_156_uniform_location, xx ctx.lights.spot[5].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_157_uniform_location, ctx.lights.spot[6].position.x, ctx.lights.spot[6].position.y, ctx.lights.spot[6].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_158_uniform_location, ctx.lights.spot[6].direction.x, ctx.lights.spot[6].direction.y, ctx.lights.spot[6].direction.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_159_uniform_location, ctx.lights.spot[6].color.x, ctx.lights.spot[6].color.y, ctx.lights.spot[6].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_160_uniform_location, ctx.lights.spot[6].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_161_uniform_location, ctx.lights.spot[6].range);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_162_uniform_location, ctx.lights.spot[6].inner_cos);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_163_uniform_location, ctx.lights.spot[6].outer_cos);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_164_uniform_location, xx ctx.lights.spot[6].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_165_uniform_location, ctx.lights.spot[7].position.x, ctx.lights.spot[7].position.y, ctx.lights.spot[7].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_166_uniform_location, ctx.lights.spot[7].direction.x, ctx.lights.spot[7].direction.y, ctx.lights.spot[7].direction.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_167_uniform_location, ctx.lights.spot[7].color.x, ctx.lights.spot[7].color.y, ctx.lights.spot[7].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_168_uniform_location, ctx.lights.spot[7].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_169_uniform_location, ctx.lights.spot[7].range);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_170_uniform_location, ctx.lights.spot[7].inner_cos);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_171_uniform_location, ctx.lights.spot[7].outer_cos);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_172_uniform_location, xx ctx.lights.spot[7].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_173_uniform_location, ctx.lights.spot[8].position.x, ctx.lights.spot[8].position.y, ctx.lights.spot[8].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_174_uniform_location, ctx.lights.spot[8].direction.x, ctx.lights.spot[8].direction.y, ctx.lights.spot[8].direction.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_175_uniform_location, ctx.lights.spot[8].color.x, ctx.lights.spot[8].color.y, ctx.lights.spot[8].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_176_uniform_location, ctx.lights.spot[8].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_177_uniform_location, ctx.lights.spot[8].range);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_178_uniform_location, ctx.lights.spot[8].inner_cos);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_179_uniform_location, ctx.lights.spot[8].outer_cos);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_180_uniform_location, xx ctx.lights.spot[8].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_181_uniform_location, ctx.lights.spot[9].position.x, ctx.lights.spot[9].position.y, ctx.lights.spot[9].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_182_uniform_location, ctx.lights.spot[9].direction.x, ctx.lights.spot[9].direction.y, ctx.lights.spot[9].direction.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_183_uniform_location, ctx.lights.spot[9].color.x, ctx.lights.spot[9].color.y, ctx.lights.spot[9].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_184_uniform_location, ctx.lights.spot[9].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_185_uniform_location, ctx.lights.spot[9].range);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_186_uniform_location, ctx.lights.spot[9].inner_cos);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_187_uniform_location, ctx.lights.spot[9].outer_cos);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_188_uniform_location, xx ctx.lights.spot[9].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_189_uniform_location, ctx.lights.spot[10].position.x, ctx.lights.spot[10].position.y, ctx.lights.spot[10].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_190_uniform_location, ctx.lights.spot[10].direction.x, ctx.lights.spot[10].direction.y, ctx.lights.spot[10].direction.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_191_uniform_location, ctx.lights.spot[10].color.x, ctx.lights.spot[10].color.y, ctx.lights.spot[10].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_192_uniform_location, ctx.lights.spot[10].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_193_uniform_location, ctx.lights.spot[10].range);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_194_uniform_location, ctx.lights.spot[10].inner_cos);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_195_uniform_location, ctx.lights.spot[10].outer_cos);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_196_uniform_location, xx ctx.lights.spot[10].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_197_uniform_location, ctx.lights.spot[11].position.x, ctx.lights.spot[11].position.y, ctx.lights.spot[11].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_198_uniform_location, ctx.lights.spot[11].direction.x, ctx.lights.spot[11].direction.y, ctx.lights.spot[11].direction.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_199_uniform_location, ctx.lights.spot[11].color.x, ctx.lights.spot[11].color.y, ctx.lights.spot[11].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_200_uniform_location, ctx.lights.spot[11].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_201_uniform_location, ctx.lights.spot[11].range);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_202_uniform_location, ctx.lights.spot[11].inner_cos);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_203_uniform_location, ctx.lights.spot[11].outer_cos);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_204_uniform_location, xx ctx.lights.spot[11].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_205_uniform_location, ctx.lights.spot[12].position.x, ctx.lights.spot[12].position.y, ctx.lights.spot[12].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_206_uniform_location, ctx.lights.spot[12].direction.x, ctx.lights.spot[12].direction.y, ctx.lights.spot[12].direction.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_207_uniform_location, ctx.lights.spot[12].color.x, ctx.lights.spot[12].color.y, ctx.lights.spot[12].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_208_uniform_location, ctx.lights.spot[12].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_209_uniform_location, ctx.lights.spot[12].range);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_210_uniform_location, ctx.lights.spot[12].inner_cos);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_211_uniform_location, ctx.lights.spot[12].outer_cos);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_212_uniform_location, xx ctx.lights.spot[12].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_213_uniform_location, ctx.lights.spot[13].position.x, ctx.lights.spot[13].position.y, ctx.lights.spot[13].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_214_uniform_location, ctx.lights.spot[13].direction.x, ctx.lights.spot[13].direction.y, ctx.lights.spot[13].direction.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_215_uniform_location, ctx.lights.spot[13].color.x, ctx.lights.spot[13].color.y, ctx.lights.spot[13].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_216_uniform_location, ctx.lights.spot[13].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_217_uniform_location, ctx.lights.spot[13].range);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_218_uniform_location, ctx.lights.spot[13].inner_cos);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_219_uniform_location, ctx.lights.spot[13].outer_cos);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_220_uniform_location, xx ctx.lights.spot[13].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_221_uniform_location, ctx.lights.spot[14].position.x, ctx.lights.spot[14].position.y, ctx.lights.spot[14].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_222_uniform_location, ctx.lights.spot[14].direction.x, ctx.lights.spot[14].direction.y, ctx.lights.spot[14].direction.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_223_uniform_location, ctx.lights.spot[14].color.x, ctx.lights.spot[14].color.y, ctx.lights.spot[14].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_224_uniform_location, ctx.lights.spot[14].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_225_uniform_location, ctx.lights.spot[14].range);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_226_uniform_location, ctx.lights.spot[14].inner_cos);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_227_uniform_location, ctx.lights.spot[14].outer_cos);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_228_uniform_location, xx ctx.lights.spot[14].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_229_uniform_location, ctx.lights.spot[15].position.x, ctx.lights.spot[15].position.y, ctx.lights.spot[15].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_230_uniform_location, ctx.lights.spot[15].direction.x, ctx.lights.spot[15].direction.y, ctx.lights.spot[15].direction.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_231_uniform_location, ctx.lights.spot[15].color.x, ctx.lights.spot[15].color.y, ctx.lights.spot[15].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_232_uniform_location, ctx.lights.spot[15].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_233_uniform_location, ctx.lights.spot[15].range);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_234_uniform_location, ctx.lights.spot[15].inner_cos);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_235_uniform_location, ctx.lights.spot[15].outer_cos);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_236_uniform_location, xx ctx.lights.spot[15].enabled);
    gl_set_active_texture_unit(GL_TEXTURE0);
    gl_clear_active_shader_program();
}


init :: (using renderer : *Blinn_Phong_Renderer) -> bool {
    vertex_shader_source := Blinn_Phong_Vertex_Source;
    fragment_shader_source := Blinn_Phong_Fragment_Source;

    if !init(*renderer.psr, vertex_shader_source, fragment_shader_source, max_num_elements_in_each_buffer) return false;
    init_buffers_no_data(renderer);


    typed_0_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "vertex_uniforms.object_transforms");
    typed_1_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "vertex_uniforms.world_to_camera");
    typed_2_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "vertex_uniforms.camera_to_clip");
    typed_3_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "resources.textures");
    typed_4_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "resources.bounding_boxes");
    typed_5_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "resources.materials");
    typed_6_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "camera_position");
    typed_7_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fallback_light_direction");
    typed_8_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "ambient");
    typed_9_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "specular_strength");
    typed_10_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.directional_count");
    typed_11_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point_count");
    typed_12_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot_count");
    typed_13_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.directional[0].direction");
    typed_14_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.directional[0].color");
    typed_15_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.directional[0].intensity");
    typed_16_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.directional[0].enabled");
    typed_17_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.directional[1].direction");
    typed_18_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.directional[1].color");
    typed_19_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.directional[1].intensity");
    typed_20_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.directional[1].enabled");
    typed_21_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.directional[2].direction");
    typed_22_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.directional[2].color");
    typed_23_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.directional[2].intensity");
    typed_24_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.directional[2].enabled");
    typed_25_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.directional[3].direction");
    typed_26_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.directional[3].color");
    typed_27_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.directional[3].intensity");
    typed_28_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.directional[3].enabled");
    typed_29_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[0].position");
    typed_30_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[0].color");
    typed_31_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[0].intensity");
    typed_32_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[0].range");
    typed_33_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[0].enabled");
    typed_34_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[1].position");
    typed_35_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[1].color");
    typed_36_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[1].intensity");
    typed_37_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[1].range");
    typed_38_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[1].enabled");
    typed_39_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[2].position");
    typed_40_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[2].color");
    typed_41_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[2].intensity");
    typed_42_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[2].range");
    typed_43_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[2].enabled");
    typed_44_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[3].position");
    typed_45_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[3].color");
    typed_46_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[3].intensity");
    typed_47_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[3].range");
    typed_48_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[3].enabled");
    typed_49_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[4].position");
    typed_50_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[4].color");
    typed_51_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[4].intensity");
    typed_52_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[4].range");
    typed_53_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[4].enabled");
    typed_54_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[5].position");
    typed_55_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[5].color");
    typed_56_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[5].intensity");
    typed_57_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[5].range");
    typed_58_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[5].enabled");
    typed_59_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[6].position");
    typed_60_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[6].color");
    typed_61_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[6].intensity");
    typed_62_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[6].range");
    typed_63_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[6].enabled");
    typed_64_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[7].position");
    typed_65_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[7].color");
    typed_66_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[7].intensity");
    typed_67_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[7].range");
    typed_68_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[7].enabled");
    typed_69_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[8].position");
    typed_70_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[8].color");
    typed_71_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[8].intensity");
    typed_72_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[8].range");
    typed_73_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[8].enabled");
    typed_74_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[9].position");
    typed_75_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[9].color");
    typed_76_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[9].intensity");
    typed_77_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[9].range");
    typed_78_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[9].enabled");
    typed_79_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[10].position");
    typed_80_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[10].color");
    typed_81_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[10].intensity");
    typed_82_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[10].range");
    typed_83_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[10].enabled");
    typed_84_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[11].position");
    typed_85_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[11].color");
    typed_86_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[11].intensity");
    typed_87_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[11].range");
    typed_88_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[11].enabled");
    typed_89_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[12].position");
    typed_90_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[12].color");
    typed_91_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[12].intensity");
    typed_92_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[12].range");
    typed_93_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[12].enabled");
    typed_94_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[13].position");
    typed_95_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[13].color");
    typed_96_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[13].intensity");
    typed_97_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[13].range");
    typed_98_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[13].enabled");
    typed_99_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[14].position");
    typed_100_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[14].color");
    typed_101_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[14].intensity");
    typed_102_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[14].range");
    typed_103_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[14].enabled");
    typed_104_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[15].position");
    typed_105_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[15].color");
    typed_106_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[15].intensity");
    typed_107_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[15].range");
    typed_108_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.point[15].enabled");
    typed_109_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[0].position");
    typed_110_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[0].direction");
    typed_111_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[0].color");
    typed_112_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[0].intensity");
    typed_113_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[0].range");
    typed_114_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[0].inner_cos");
    typed_115_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[0].outer_cos");
    typed_116_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[0].enabled");
    typed_117_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[1].position");
    typed_118_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[1].direction");
    typed_119_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[1].color");
    typed_120_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[1].intensity");
    typed_121_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[1].range");
    typed_122_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[1].inner_cos");
    typed_123_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[1].outer_cos");
    typed_124_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[1].enabled");
    typed_125_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[2].position");
    typed_126_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[2].direction");
    typed_127_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[2].color");
    typed_128_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[2].intensity");
    typed_129_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[2].range");
    typed_130_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[2].inner_cos");
    typed_131_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[2].outer_cos");
    typed_132_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[2].enabled");
    typed_133_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[3].position");
    typed_134_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[3].direction");
    typed_135_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[3].color");
    typed_136_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[3].intensity");
    typed_137_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[3].range");
    typed_138_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[3].inner_cos");
    typed_139_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[3].outer_cos");
    typed_140_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[3].enabled");
    typed_141_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[4].position");
    typed_142_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[4].direction");
    typed_143_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[4].color");
    typed_144_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[4].intensity");
    typed_145_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[4].range");
    typed_146_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[4].inner_cos");
    typed_147_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[4].outer_cos");
    typed_148_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[4].enabled");
    typed_149_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[5].position");
    typed_150_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[5].direction");
    typed_151_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[5].color");
    typed_152_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[5].intensity");
    typed_153_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[5].range");
    typed_154_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[5].inner_cos");
    typed_155_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[5].outer_cos");
    typed_156_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[5].enabled");
    typed_157_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[6].position");
    typed_158_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[6].direction");
    typed_159_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[6].color");
    typed_160_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[6].intensity");
    typed_161_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[6].range");
    typed_162_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[6].inner_cos");
    typed_163_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[6].outer_cos");
    typed_164_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[6].enabled");
    typed_165_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[7].position");
    typed_166_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[7].direction");
    typed_167_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[7].color");
    typed_168_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[7].intensity");
    typed_169_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[7].range");
    typed_170_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[7].inner_cos");
    typed_171_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[7].outer_cos");
    typed_172_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[7].enabled");
    typed_173_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[8].position");
    typed_174_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[8].direction");
    typed_175_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[8].color");
    typed_176_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[8].intensity");
    typed_177_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[8].range");
    typed_178_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[8].inner_cos");
    typed_179_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[8].outer_cos");
    typed_180_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[8].enabled");
    typed_181_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[9].position");
    typed_182_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[9].direction");
    typed_183_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[9].color");
    typed_184_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[9].intensity");
    typed_185_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[9].range");
    typed_186_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[9].inner_cos");
    typed_187_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[9].outer_cos");
    typed_188_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[9].enabled");
    typed_189_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[10].position");
    typed_190_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[10].direction");
    typed_191_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[10].color");
    typed_192_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[10].intensity");
    typed_193_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[10].range");
    typed_194_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[10].inner_cos");
    typed_195_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[10].outer_cos");
    typed_196_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[10].enabled");
    typed_197_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[11].position");
    typed_198_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[11].direction");
    typed_199_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[11].color");
    typed_200_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[11].intensity");
    typed_201_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[11].range");
    typed_202_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[11].inner_cos");
    typed_203_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[11].outer_cos");
    typed_204_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[11].enabled");
    typed_205_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[12].position");
    typed_206_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[12].direction");
    typed_207_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[12].color");
    typed_208_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[12].intensity");
    typed_209_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[12].range");
    typed_210_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[12].inner_cos");
    typed_211_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[12].outer_cos");
    typed_212_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[12].enabled");
    typed_213_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[13].position");
    typed_214_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[13].direction");
    typed_215_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[13].color");
    typed_216_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[13].intensity");
    typed_217_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[13].range");
    typed_218_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[13].inner_cos");
    typed_219_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[13].outer_cos");
    typed_220_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[13].enabled");
    typed_221_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[14].position");
    typed_222_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[14].direction");
    typed_223_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[14].color");
    typed_224_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[14].intensity");
    typed_225_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[14].range");
    typed_226_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[14].inner_cos");
    typed_227_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[14].outer_cos");
    typed_228_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[14].enabled");
    typed_229_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[15].position");
    typed_230_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[15].direction");
    typed_231_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[15].color");
    typed_232_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[15].intensity");
    typed_233_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[15].range");
    typed_234_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[15].inner_cos");
    typed_235_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[15].outer_cos");
    typed_236_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "lights.spot[15].enabled");

    return true;
}


deinit :: (using renderer : *Blinn_Phong_Renderer) {
    deinit(*psr);

    gl_delete_buffer(positions_buffer_gl_handle);
    gl_delete_buffer(normals_buffer_gl_handle);
    gl_delete_buffer(tangents_buffer_gl_handle);
    gl_delete_buffer(uvs_buffer_gl_handle);
    gl_delete_buffer(material_indices_buffer_gl_handle);
    gl_delete_buffer(local_to_world_indices_buffer_gl_handle);
}



init_buffers_no_data :: (using apcr : *Blinn_Phong_Renderer) { // todo change renderer name

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

    generate_buffer_for_vertex_attribute(*tangents_buffer_gl_handle, Vector3, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, tangents_buffer_gl_handle, "tangent", 3, GL_FLOAT, GL_FALSE, 0, null);

    generate_buffer_for_vertex_attribute(*uvs_buffer_gl_handle, Vector2, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, uvs_buffer_gl_handle, "uv", 2, GL_FLOAT, GL_FALSE, 0, null);

    generate_buffer_for_vertex_attribute(*material_indices_buffer_gl_handle, s32, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, material_indices_buffer_gl_handle, "material_index", 1, GL_INT, GL_FALSE, 0, null);

    generate_buffer_for_vertex_attribute(*local_to_world_indices_buffer_gl_handle, s32, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, local_to_world_indices_buffer_gl_handle, "local_to_world_index", 1, GL_INT, GL_FALSE, 0, null);



	gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, 0);
}


buffer_object :: (
    using renderer : *Blinn_Phong_Renderer,
    renderable : *$T/interface Blinn_Phong_Renderable,
    budgeter: *GL_Budgeter = null,
) -> success: bool {


    object_index, success := buffer_object(renderer,
            renderable.indices,

            renderable.positions,
            renderable.normals,
            renderable.tangents,
            renderable.uvs,
            renderable.material_indices,
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
        using renderer: *Blinn_Phong_Renderer,
        indices : [] u32,
        positions : [] Vector3,
        normals : [] Vector3,
        tangents : [] Vector3,
        uvs : [] Vector2,
        material_indices : [] s32,
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



    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, normals_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(budgeter, GL_ARRAY_BUFFER, index * size_of(Vector3), normals.count * size_of(Vector3), normals.data);



    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, tangents_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(budgeter, GL_ARRAY_BUFFER, index * size_of(Vector3), tangents.count * size_of(Vector3), tangents.data);



    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, uvs_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(budgeter, GL_ARRAY_BUFFER, index * size_of(Vector2), uvs.count * size_of(Vector2), uvs.data);



    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, material_indices_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(budgeter, GL_ARRAY_BUFFER, index * size_of(s32), material_indices.count * size_of(s32), material_indices.data);



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
rebuffer_object :: (using renderer : *Blinn_Phong_Renderer, renderable : $T/interface Blinn_Phong_Renderable) {

    gl_bind_vertex_array(vertex_attribute_array_gl_handle);

    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, positions_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, renderable.object_index * size_of(Vector3), renderable.positions.count * size_of(Vector3), renderable.positions.data);

    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, normals_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, renderable.object_index * size_of(Vector3), renderable.normals.count * size_of(Vector3), renderable.normals.data);

    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, tangents_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, renderable.object_index * size_of(Vector3), renderable.tangents.count * size_of(Vector3), renderable.tangents.data);

    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, uvs_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, renderable.object_index * size_of(Vector2), renderable.uvs.count * size_of(Vector2), renderable.uvs.data);

    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, material_indices_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, renderable.object_index * size_of(s32), renderable.material_indices.count * size_of(s32), renderable.material_indices.data);

    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, local_to_world_indices_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, renderable.object_index * size_of(s32), renderable.local_to_world_indices.count * size_of(s32), renderable.local_to_world_indices.data);


    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, 0);
    gl_bind_vertex_array(0);
}

render :: (using renderer : *Blinn_Phong_Renderer, primitive_mode: GLenum = GL_TRIANGLES) {

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

Blinn_Phong_Vertex_Source :: #string END_Blinn_Phong_Vertex_Source
#version 330 core
// Generated from Jai procedure mesh_vertex_shader.
struct Mesh_Transform_Result {
    vec4 position;
    vec3 normal;
    vec3 tangent;
};
struct Mesh_Vertex_Uniforms {
    sampler2D object_transforms;
    mat4 world_to_camera;
    mat4 camera_to_clip;
};
struct GLSL_Vertex_Shader_Input_Built_In_Variables {
    int vertex_index;
    int instance_index;
};
struct Mesh_Vertex {
    vec3 position;
    vec3 normal;
    vec3 tangent;
    vec2 uv;
    int material_index;
    int local_to_world_index;
    GLSL_Vertex_Shader_Input_Built_In_Variables gpu;
};
in vec3 position;
in vec3 normal;
in vec3 tangent;
in vec2 uv;
in int material_index;
in int local_to_world_index;
out vec3 passthrough_world_position;
out vec3 passthrough_normal;
out vec3 passthrough_tangent;
out vec2 passthrough_uv;
flat out int passthrough_material_index;
uniform Mesh_Vertex_Uniforms vertex_uniforms;

vec4 jai_mesh_transform(sampler2D table, int index, vec4 value) {
    return vec4(dot(texelFetch(table, ivec2(0, index), 0), value), dot(texelFetch(table, ivec2(1, index), 0), value), dot(texelFetch(table, ivec2(2, index), 0), value), dot(texelFetch(table, ivec2(3, index), 0), value));
}

Mesh_Transform_Result jai_mesh_world_geometry(Mesh_Vertex_Uniforms uniforms, Mesh_Vertex jai_var_input) {
    vec4 p = jai_mesh_transform(uniforms.object_transforms, jai_var_input.local_to_world_index, vec4(jai_var_input.position.x, jai_var_input.position.y, jai_var_input.position.z, 1.0));
    vec4 n = jai_mesh_transform(uniforms.object_transforms, jai_var_input.local_to_world_index, vec4(jai_var_input.normal.x, jai_var_input.normal.y, jai_var_input.normal.z, 0.0));
    vec4 t = jai_mesh_transform(uniforms.object_transforms, jai_var_input.local_to_world_index, vec4(jai_var_input.tangent.x, jai_var_input.tangent.y, jai_var_input.tangent.z, 0.0));
    return Mesh_Transform_Result(p, normalize(vec3(n.x, n.y, n.z)), normalize(vec3(t.x, t.y, t.z)));
}

void main() {
    Mesh_Vertex jai_var_input;
    jai_var_input.position = position;
    jai_var_input.normal = normal;
    jai_var_input.tangent = tangent;
    jai_var_input.uv = uv;
    jai_var_input.material_index = material_index;
    jai_var_input.local_to_world_index = local_to_world_index;
    jai_var_input.gpu.vertex_index = gl_VertexID;
    jai_var_input.gpu.instance_index = gl_InstanceID;
    Mesh_Transform_Result world = jai_mesh_world_geometry(vertex_uniforms, jai_var_input);
    gl_Position = ((vertex_uniforms.camera_to_clip * vertex_uniforms.world_to_camera) * world.position);
    passthrough_world_position = vec3(world.position.x, world.position.y, world.position.z);
    passthrough_normal = world.normal;
    passthrough_tangent = world.tangent;
    passthrough_uv = jai_var_input.uv;
    passthrough_material_index = jai_var_input.material_index;
}

END_Blinn_Phong_Vertex_Source

Blinn_Phong_Fragment_Source :: #string END_Blinn_Phong_Fragment_Source
#version 330 core
// Generated from Jai procedure blinn_phong_fragment_shader.
struct Packed_Material_Textures {
    sampler2DArray textures;
    sampler1D bounding_boxes;
    sampler1D materials;
};
struct Blinn_Phong_Surface {
    vec3 diffuse;
    vec3 specular;
    vec3 normal;
    float alpha;
    float shininess;
};
struct Mesh_Directional_Light {
    vec3 direction;
    vec3 color;
    float intensity;
    bool enabled;
};
struct Mesh_Point_Light {
    vec3 position;
    vec3 color;
    float intensity;
    float range;
    bool enabled;
};
struct Mesh_Spot_Light {
    vec3 position;
    vec3 direction;
    vec3 color;
    float intensity;
    float range;
    float inner_cos;
    float outer_cos;
    bool enabled;
};
struct Mesh_Lights {
    int directional_count;
    int point_count;
    int spot_count;
    Mesh_Directional_Light directional[4];
    Mesh_Point_Light point[16];
    Mesh_Spot_Light spot[16];
};
in vec3 passthrough_world_position;
in vec3 passthrough_normal;
in vec3 passthrough_tangent;
in vec2 passthrough_uv;
flat in int passthrough_material_index;
layout(location=0) out vec4 gpu_rendering_pipeline_stage_attachment_color;
uniform Packed_Material_Textures resources;
uniform vec3 camera_position;
uniform vec3 fallback_light_direction;
uniform float ambient;
uniform float specular_strength;
uniform Mesh_Lights lights;

vec4 jai_packed_material_sample(Packed_Material_Textures resources, vec2 uv, float layer, float box_index, vec4 fallback) {
    if (((layer < 0.0) || (box_index < 0.0))) {
        return fallback;
    }
    vec4 box = texelFetch(resources.bounding_boxes, int(box_index), 0);
    return texture(resources.textures, vec3((box.x + (fract(uv.x) * box.z)), (box.y + (fract(uv.y) * box.w)), layer));
}

vec3 jai_mesh_normal_map(vec3 normal, vec3 tangent, vec4 sample, float scale) {
    vec3 n = normalize(normal);
    vec3 t = normalize((tangent - (n * dot(n, tangent))));
    vec3 b = normalize(cross(n, t));
    return normalize((((t * (((sample.x * 2.0) - 1.0) * scale)) + (b * (((sample.y * 2.0) - 1.0) * scale))) + (n * ((sample.z * 2.0) - 1.0))));
}

vec3 jai_mesh_multiply(vec3 a, vec3 b) {
    return vec3((a.x * b.x), (a.y * b.y), (a.z * b.z));
}

vec3 jai_blinn_phong_light(Blinn_Phong_Surface surface, vec3 view, vec3 light, vec3 radiance, float strength) {
    float diffuse = max(dot(surface.normal, light), 0.0);
    float specular = (pow(max(dot(surface.normal, normalize((light + view))), 0.0), surface.shininess) * strength);
    return jai_mesh_multiply(((surface.diffuse * diffuse) + (surface.specular * specular)), radiance);
}

void main() {
    int index = (passthrough_material_index * 5);
    vec4 slot = texelFetch(resources.materials, index, 0);
    vec4 factor = texelFetch(resources.materials, (index + 1), 0);
    vec4 normal_slot = texelFetch(resources.materials, (index + 2), 0);
    vec4 specular_slot = texelFetch(resources.materials, (index + 3), 0);
    vec4 specular_factor = texelFetch(resources.materials, (index + 4), 0);
    vec4 base = jai_packed_material_sample(resources, passthrough_uv, slot.x, slot.y, vec4(1.0, 1.0, 1.0, 1.0));
    vec4 sg = jai_packed_material_sample(resources, passthrough_uv, specular_slot.x, specular_slot.y, vec4(1.0, 1.0, 1.0, 1.0));
    vec3 normal = normalize(passthrough_normal);
    if (((normal_slot.x >= 0.0) && (normal_slot.y >= 0.0))) {
        vec4 sample = jai_packed_material_sample(resources, passthrough_uv, normal_slot.x, normal_slot.y, vec4(0.5, 0.5, 1.0, 1.0));
        normal = jai_mesh_normal_map(normal, passthrough_tangent, sample, normal_slot.z);
    }
    float gloss = clamp((sg.w * specular_slot.z), 0.0, 1.0);
    Blinn_Phong_Surface surface = Blinn_Phong_Surface(vec3((base.x * factor.x), (base.y * factor.y), (base.z * factor.z)), vec3((sg.x * specular_factor.x), (sg.y * specular_factor.y), (sg.z * specular_factor.z)), normal, (base.w * factor.w), (2.0 + ((gloss * gloss) * 254.0)));
    vec3 view = normalize((camera_position - passthrough_world_position));
    vec3 color = (surface.diffuse * ambient);
    for (int i = 0, jai_glsl_range_end_0 = (clamp(lights.directional_count, 0, 4) - 1); i <= jai_glsl_range_end_0; ++i) {
        Mesh_Directional_Light light = lights.directional[i];
        if (!(light.enabled)) {
            continue;
        }
        color += jai_blinn_phong_light(surface, view, normalize(light.direction), (light.color * light.intensity), specular_strength);
    }
    for (int i = 0, jai_glsl_range_end_1 = (clamp(lights.point_count, 0, 16) - 1); i <= jai_glsl_range_end_1; ++i) {
        Mesh_Point_Light light = lights.point[i];
        if (!(light.enabled)) {
            continue;
        }
        vec3 delta = (light.position - passthrough_world_position);
        float distance = sqrt(max(dot(delta, delta), 0.0001));
        float fade = 1.0;
        if ((light.range > 0.0)) {
            fade = clamp((1.0 - (distance / light.range)), 0.0, 1.0);
        }
        color += jai_blinn_phong_light(surface, view, (delta / distance), (light.color * ((light.intensity * fade) * fade)), specular_strength);
    }
    for (int i = 0, jai_glsl_range_end_2 = (clamp(lights.spot_count, 0, 16) - 1); i <= jai_glsl_range_end_2; ++i) {
        Mesh_Spot_Light light = lights.spot[i];
        if (!(light.enabled)) {
            continue;
        }
        vec3 delta = (light.position - passthrough_world_position);
        float distance = sqrt(max(dot(delta, delta), 0.0001));
        vec3 direction = (delta / distance);
        float cone = clamp(((dot(normalize(light.direction), -(direction)) - light.outer_cos) / max((light.inner_cos - light.outer_cos), 0.0001)), 0.0, 1.0);
        float fade = 1.0;
        if ((light.range > 0.0)) {
            fade = clamp((1.0 - (distance / light.range)), 0.0, 1.0);
        }
        color += jai_blinn_phong_light(surface, view, direction, (light.color * (((light.intensity * cone) * fade) * fade)), specular_strength);
    }
    if ((((lights.directional_count == 0) && (lights.point_count == 0)) && (lights.spot_count == 0))) {
        color += jai_blinn_phong_light(surface, view, normalize(fallback_light_direction), vec3(1.0, 1.0, 1.0), specular_strength);
    }
    gpu_rendering_pipeline_stage_attachment_color = vec4(clamp(color.x, 0.0, 1.0), clamp(color.y, 0.0, 1.0), clamp(color.z, 0.0, 1.0), surface.alpha);
}

END_Blinn_Phong_Fragment_Source
