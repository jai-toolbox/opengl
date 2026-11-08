// auto-generated renderer for shader: Pbr_Directional_Shadows_Skeletal_Animation
// do not edit manually.

Pbr_Directional_Shadows_Skeletal_Animation_Mesh_Vertex_Uniforms_Bindings :: struct {
    object_transforms: GLuint;
    world_to_camera: Matrix4;
    camera_to_clip: Matrix4;
}

Pbr_Directional_Shadows_Skeletal_Animation_Skinned_Mesh_Vertex_Uniforms_Bindings :: struct {
    mesh: Pbr_Directional_Shadows_Skeletal_Animation_Mesh_Vertex_Uniforms_Bindings;
    bone_transforms: GLuint;
}

Pbr_Directional_Shadows_Skeletal_Animation_Packed_Material_Textures_Bindings :: struct {
    textures: GLuint;
    bounding_boxes: GLuint;
    materials: GLuint;
}

Pbr_Directional_Shadows_Skeletal_Animation_PBR_Fragment_Uniforms_Bindings :: struct {
    resources: Pbr_Directional_Shadows_Skeletal_Animation_Packed_Material_Textures_Bindings;
    camera_position: Vector3;
    ambient_strength: float32;
    lights: Mesh_Lights;
}

Pbr_Directional_Shadows_Skeletal_Animation_PBR_Shadow_Fragment_Uniforms_Bindings :: struct {
    pbr: Pbr_Directional_Shadows_Skeletal_Animation_PBR_Fragment_Uniforms_Bindings;
    world_to_light_clip: Matrix4;
    shadow_map: GLuint;
    shadow_enabled: bool;
}


Pbr_Directional_Shadows_Skeletal_Animation_Renderable :: struct {
    indices : [..] u32;
    object_index : u32;

    positions: [..] Vector3;
    normals: [..] Vector3;
    tangents: [..] Vector3;
    uvs: [..] Vector2;
    material_indices: [..] s32;
    local_to_world_indices: [..] s32;
    bone_indices: [..] Shader_UInt4;
    bone_weights: [..] Vector4;

}


Pbr_Directional_Shadows_Skeletal_Animation_Geometry :: struct {
    indices : [..] u32;
    positions: [..] Vector3;
    normals: [..] Vector3;
    tangents: [..] Vector3;
    uvs: [..] Vector2;
    material_indices: [..] s32;
    local_to_world_indices: [..] s32;
    bone_indices: [..] Shader_UInt4;
    bone_weights: [..] Vector4;
}

assign_geometry_copy :: (renderable: *Pbr_Directional_Shadows_Skeletal_Animation_Renderable, geometry: $T/interface Pbr_Directional_Shadows_Skeletal_Animation_Geometry) {
    array_copy(*renderable.indices, geometry.indices);
    array_copy(*renderable.positions, geometry.positions);
    array_copy(*renderable.normals, geometry.normals);
    array_copy(*renderable.tangents, geometry.tangents);
    array_copy(*renderable.uvs, geometry.uvs);
    array_copy(*renderable.material_indices, geometry.material_indices);
    array_copy(*renderable.local_to_world_indices, geometry.local_to_world_indices);
    array_copy(*renderable.bone_indices, geometry.bone_indices);
    array_copy(*renderable.bone_weights, geometry.bone_weights);
}

assign_geometry :: (renderable: *Pbr_Directional_Shadows_Skeletal_Animation_Renderable, geometry: $T/interface Pbr_Directional_Shadows_Skeletal_Animation_Geometry) {
    renderable.indices = geometry.indices;
    renderable.positions = geometry.positions;
    renderable.normals = geometry.normals;
    renderable.tangents = geometry.tangents;
    renderable.uvs = geometry.uvs;
    renderable.material_indices = geometry.material_indices;
    renderable.local_to_world_indices = geometry.local_to_world_indices;
    renderable.bone_indices = geometry.bone_indices;
    renderable.bone_weights = geometry.bone_weights;
}


deinit :: (renderable: *Pbr_Directional_Shadows_Skeletal_Animation_Renderable) {
    array_free(renderable.indices);
    array_free(renderable.positions);
    array_free(renderable.normals);
    array_free(renderable.tangents);
    array_free(renderable.uvs);
    array_free(renderable.material_indices);
    array_free(renderable.local_to_world_indices);
    array_free(renderable.bone_indices);
    array_free(renderable.bone_weights);
}

/*

so deinit exists but also unbuffer object exists, the difference is that deinit takes in a renderable and frees its CPU-side arrays and resets its transform slot, whereas unbuffer_object only frees the GPU-side virtual allocation, leaving the CPU data intact for potential re-buffering later.

*/
deinit :: (renderable: *Pbr_Directional_Shadows_Skeletal_Animation_Renderable, renderer: *Pbr_Directional_Shadows_Skeletal_Animation_Renderer) {
    unbuffer_object(*renderer.psr, renderable.object_index);
    array_free(renderable.indices);
    array_free(renderable.positions);
    array_free(renderable.normals);
    array_free(renderable.tangents);
    array_free(renderable.uvs);
    array_free(renderable.material_indices);
    array_free(renderable.local_to_world_indices);
    array_free(renderable.bone_indices);
    array_free(renderable.bone_weights);
}


unbuffer_object :: (renderer: *Pbr_Directional_Shadows_Skeletal_Animation_Renderer, renderable: *Pbr_Directional_Shadows_Skeletal_Animation_Renderable) {
    unbuffer_object(*renderer.psr, renderable.object_index);
    renderable.object_index = 0;
}


queue_render :: (using renderer: *Pbr_Directional_Shadows_Skeletal_Animation_Renderer, renderable: Pbr_Directional_Shadows_Skeletal_Animation_Renderable) {
    queue_render(*renderer.psr, renderable.object_index);
}

// Indices are relative to this buffered object's first vertex.
update_object_indices :: (renderer : *Pbr_Directional_Shadows_Skeletal_Animation_Renderer, object_index : u32, indices : [] u32) -> bool {
    return update_object_indices(*renderer.psr, object_index, indices);
}

update_object_indices :: (renderer : *Pbr_Directional_Shadows_Skeletal_Animation_Renderer, renderable : $T/interface Pbr_Directional_Shadows_Skeletal_Animation_Renderable, indices : [] u32) -> bool {
    return update_object_indices(renderer, renderable.object_index, indices);
}

queue_render :: (renderer : *Pbr_Directional_Shadows_Skeletal_Animation_Renderer, object_index : u32) {
    queue_render(*renderer.psr, object_index);
}


unbuffer_object :: (renderer : *Pbr_Directional_Shadows_Skeletal_Animation_Renderer, object_index : u32) {
    unbuffer_object(*renderer.psr, object_index);
}

buffer_object :: (renderer : *Pbr_Directional_Shadows_Skeletal_Animation_Renderer, vertices : [] Skinned_Mesh_Vertex, indices : [] u32) -> (object_index : u32, success : bool) {
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
    bone_indices : [..] Shader_UInt4;
    defer array_free(bone_indices);
    bone_weights : [..] Vector4;
    defer array_free(bone_weights);
    for vertex : vertices {
        array_add(*positions, vertex.mesh.position);
        array_add(*normals, vertex.mesh.normal);
        array_add(*tangents, vertex.mesh.tangent);
        array_add(*uvs, vertex.mesh.uv);
        array_add(*material_indices, vertex.mesh.material_index);
        array_add(*local_to_world_indices, vertex.mesh.local_to_world_index);
        array_add(*bone_indices, vertex.bone_indices);
        array_add(*bone_weights, vertex.bone_weights);
    }
    buffered_index, buffered := buffer_object(renderer, indices, positions, normals, tangents, uvs, material_indices, local_to_world_indices, bone_indices, bone_weights);
    return buffered_index, buffered;
}


Pbr_Directional_Shadows_Skeletal_Animation_Renderer :: struct {
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
    typed_237_uniform_location : GLint = -1;
    typed_238_uniform_location : GLint = -1;

    positions_buffer_gl_handle: GLuint;
    normals_buffer_gl_handle: GLuint;
    tangents_buffer_gl_handle: GLuint;
    uvs_buffer_gl_handle: GLuint;
    material_indices_buffer_gl_handle: GLuint;
    local_to_world_indices_buffer_gl_handle: GLuint;
    bone_indices_buffer_gl_handle: GLuint;
    bone_weights_buffer_gl_handle: GLuint;


}

set_uniforms :: (renderer: *Pbr_Directional_Shadows_Skeletal_Animation_Renderer, ctx: Pbr_Directional_Shadows_Skeletal_Animation_Skinned_Mesh_Vertex_Uniforms_Bindings) {
    gl_set_active_shader_program(renderer.shader_program_gl_handle);
    gl_set_active_texture_unit(GL_TEXTURE0 + 0);
    gl_bind_texture_to_binding_target_of_active_texture_unit(GL_TEXTURE_2D,ctx.mesh.object_transforms);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_0_uniform_location,0);
    gl_set_uniform_matrix_4fv_on_active_shader_program(renderer.typed_1_uniform_location, 1, GL_TRUE, *ctx.mesh.world_to_camera.coef[0][0]);
    gl_set_uniform_matrix_4fv_on_active_shader_program(renderer.typed_2_uniform_location, 1, GL_TRUE, *ctx.mesh.camera_to_clip.coef[0][0]);
    gl_set_active_texture_unit(GL_TEXTURE0 + 1);
    gl_bind_texture_to_binding_target_of_active_texture_unit(GL_TEXTURE_2D,ctx.bone_transforms);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_3_uniform_location,1);
    gl_set_active_texture_unit(GL_TEXTURE0);
    gl_clear_active_shader_program();
}

set_uniforms :: (renderer: *Pbr_Directional_Shadows_Skeletal_Animation_Renderer, ctx: Pbr_Directional_Shadows_Skeletal_Animation_PBR_Shadow_Fragment_Uniforms_Bindings) {
    gl_set_active_shader_program(renderer.shader_program_gl_handle);
    gl_set_active_texture_unit(GL_TEXTURE0 + 2);
    gl_bind_texture_to_binding_target_of_active_texture_unit(GL_TEXTURE_2D_ARRAY,ctx.pbr.resources.textures);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_4_uniform_location,2);
    gl_set_active_texture_unit(GL_TEXTURE0 + 3);
    gl_bind_texture_to_binding_target_of_active_texture_unit(GL_TEXTURE_1D,ctx.pbr.resources.bounding_boxes);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_5_uniform_location,3);
    gl_set_active_texture_unit(GL_TEXTURE0 + 4);
    gl_bind_texture_to_binding_target_of_active_texture_unit(GL_TEXTURE_1D,ctx.pbr.resources.materials);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_6_uniform_location,4);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_7_uniform_location, ctx.pbr.camera_position.x, ctx.pbr.camera_position.y, ctx.pbr.camera_position.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_8_uniform_location, ctx.pbr.ambient_strength);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_9_uniform_location, ctx.pbr.lights.directional_count);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_10_uniform_location, ctx.pbr.lights.point_count);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_11_uniform_location, ctx.pbr.lights.spot_count);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_12_uniform_location, ctx.pbr.lights.directional[0].direction.x, ctx.pbr.lights.directional[0].direction.y, ctx.pbr.lights.directional[0].direction.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_13_uniform_location, ctx.pbr.lights.directional[0].color.x, ctx.pbr.lights.directional[0].color.y, ctx.pbr.lights.directional[0].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_14_uniform_location, ctx.pbr.lights.directional[0].intensity);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_15_uniform_location, xx ctx.pbr.lights.directional[0].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_16_uniform_location, ctx.pbr.lights.directional[1].direction.x, ctx.pbr.lights.directional[1].direction.y, ctx.pbr.lights.directional[1].direction.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_17_uniform_location, ctx.pbr.lights.directional[1].color.x, ctx.pbr.lights.directional[1].color.y, ctx.pbr.lights.directional[1].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_18_uniform_location, ctx.pbr.lights.directional[1].intensity);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_19_uniform_location, xx ctx.pbr.lights.directional[1].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_20_uniform_location, ctx.pbr.lights.directional[2].direction.x, ctx.pbr.lights.directional[2].direction.y, ctx.pbr.lights.directional[2].direction.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_21_uniform_location, ctx.pbr.lights.directional[2].color.x, ctx.pbr.lights.directional[2].color.y, ctx.pbr.lights.directional[2].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_22_uniform_location, ctx.pbr.lights.directional[2].intensity);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_23_uniform_location, xx ctx.pbr.lights.directional[2].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_24_uniform_location, ctx.pbr.lights.directional[3].direction.x, ctx.pbr.lights.directional[3].direction.y, ctx.pbr.lights.directional[3].direction.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_25_uniform_location, ctx.pbr.lights.directional[3].color.x, ctx.pbr.lights.directional[3].color.y, ctx.pbr.lights.directional[3].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_26_uniform_location, ctx.pbr.lights.directional[3].intensity);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_27_uniform_location, xx ctx.pbr.lights.directional[3].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_28_uniform_location, ctx.pbr.lights.point[0].position.x, ctx.pbr.lights.point[0].position.y, ctx.pbr.lights.point[0].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_29_uniform_location, ctx.pbr.lights.point[0].color.x, ctx.pbr.lights.point[0].color.y, ctx.pbr.lights.point[0].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_30_uniform_location, ctx.pbr.lights.point[0].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_31_uniform_location, ctx.pbr.lights.point[0].range);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_32_uniform_location, xx ctx.pbr.lights.point[0].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_33_uniform_location, ctx.pbr.lights.point[1].position.x, ctx.pbr.lights.point[1].position.y, ctx.pbr.lights.point[1].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_34_uniform_location, ctx.pbr.lights.point[1].color.x, ctx.pbr.lights.point[1].color.y, ctx.pbr.lights.point[1].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_35_uniform_location, ctx.pbr.lights.point[1].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_36_uniform_location, ctx.pbr.lights.point[1].range);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_37_uniform_location, xx ctx.pbr.lights.point[1].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_38_uniform_location, ctx.pbr.lights.point[2].position.x, ctx.pbr.lights.point[2].position.y, ctx.pbr.lights.point[2].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_39_uniform_location, ctx.pbr.lights.point[2].color.x, ctx.pbr.lights.point[2].color.y, ctx.pbr.lights.point[2].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_40_uniform_location, ctx.pbr.lights.point[2].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_41_uniform_location, ctx.pbr.lights.point[2].range);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_42_uniform_location, xx ctx.pbr.lights.point[2].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_43_uniform_location, ctx.pbr.lights.point[3].position.x, ctx.pbr.lights.point[3].position.y, ctx.pbr.lights.point[3].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_44_uniform_location, ctx.pbr.lights.point[3].color.x, ctx.pbr.lights.point[3].color.y, ctx.pbr.lights.point[3].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_45_uniform_location, ctx.pbr.lights.point[3].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_46_uniform_location, ctx.pbr.lights.point[3].range);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_47_uniform_location, xx ctx.pbr.lights.point[3].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_48_uniform_location, ctx.pbr.lights.point[4].position.x, ctx.pbr.lights.point[4].position.y, ctx.pbr.lights.point[4].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_49_uniform_location, ctx.pbr.lights.point[4].color.x, ctx.pbr.lights.point[4].color.y, ctx.pbr.lights.point[4].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_50_uniform_location, ctx.pbr.lights.point[4].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_51_uniform_location, ctx.pbr.lights.point[4].range);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_52_uniform_location, xx ctx.pbr.lights.point[4].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_53_uniform_location, ctx.pbr.lights.point[5].position.x, ctx.pbr.lights.point[5].position.y, ctx.pbr.lights.point[5].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_54_uniform_location, ctx.pbr.lights.point[5].color.x, ctx.pbr.lights.point[5].color.y, ctx.pbr.lights.point[5].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_55_uniform_location, ctx.pbr.lights.point[5].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_56_uniform_location, ctx.pbr.lights.point[5].range);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_57_uniform_location, xx ctx.pbr.lights.point[5].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_58_uniform_location, ctx.pbr.lights.point[6].position.x, ctx.pbr.lights.point[6].position.y, ctx.pbr.lights.point[6].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_59_uniform_location, ctx.pbr.lights.point[6].color.x, ctx.pbr.lights.point[6].color.y, ctx.pbr.lights.point[6].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_60_uniform_location, ctx.pbr.lights.point[6].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_61_uniform_location, ctx.pbr.lights.point[6].range);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_62_uniform_location, xx ctx.pbr.lights.point[6].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_63_uniform_location, ctx.pbr.lights.point[7].position.x, ctx.pbr.lights.point[7].position.y, ctx.pbr.lights.point[7].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_64_uniform_location, ctx.pbr.lights.point[7].color.x, ctx.pbr.lights.point[7].color.y, ctx.pbr.lights.point[7].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_65_uniform_location, ctx.pbr.lights.point[7].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_66_uniform_location, ctx.pbr.lights.point[7].range);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_67_uniform_location, xx ctx.pbr.lights.point[7].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_68_uniform_location, ctx.pbr.lights.point[8].position.x, ctx.pbr.lights.point[8].position.y, ctx.pbr.lights.point[8].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_69_uniform_location, ctx.pbr.lights.point[8].color.x, ctx.pbr.lights.point[8].color.y, ctx.pbr.lights.point[8].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_70_uniform_location, ctx.pbr.lights.point[8].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_71_uniform_location, ctx.pbr.lights.point[8].range);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_72_uniform_location, xx ctx.pbr.lights.point[8].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_73_uniform_location, ctx.pbr.lights.point[9].position.x, ctx.pbr.lights.point[9].position.y, ctx.pbr.lights.point[9].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_74_uniform_location, ctx.pbr.lights.point[9].color.x, ctx.pbr.lights.point[9].color.y, ctx.pbr.lights.point[9].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_75_uniform_location, ctx.pbr.lights.point[9].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_76_uniform_location, ctx.pbr.lights.point[9].range);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_77_uniform_location, xx ctx.pbr.lights.point[9].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_78_uniform_location, ctx.pbr.lights.point[10].position.x, ctx.pbr.lights.point[10].position.y, ctx.pbr.lights.point[10].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_79_uniform_location, ctx.pbr.lights.point[10].color.x, ctx.pbr.lights.point[10].color.y, ctx.pbr.lights.point[10].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_80_uniform_location, ctx.pbr.lights.point[10].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_81_uniform_location, ctx.pbr.lights.point[10].range);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_82_uniform_location, xx ctx.pbr.lights.point[10].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_83_uniform_location, ctx.pbr.lights.point[11].position.x, ctx.pbr.lights.point[11].position.y, ctx.pbr.lights.point[11].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_84_uniform_location, ctx.pbr.lights.point[11].color.x, ctx.pbr.lights.point[11].color.y, ctx.pbr.lights.point[11].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_85_uniform_location, ctx.pbr.lights.point[11].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_86_uniform_location, ctx.pbr.lights.point[11].range);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_87_uniform_location, xx ctx.pbr.lights.point[11].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_88_uniform_location, ctx.pbr.lights.point[12].position.x, ctx.pbr.lights.point[12].position.y, ctx.pbr.lights.point[12].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_89_uniform_location, ctx.pbr.lights.point[12].color.x, ctx.pbr.lights.point[12].color.y, ctx.pbr.lights.point[12].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_90_uniform_location, ctx.pbr.lights.point[12].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_91_uniform_location, ctx.pbr.lights.point[12].range);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_92_uniform_location, xx ctx.pbr.lights.point[12].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_93_uniform_location, ctx.pbr.lights.point[13].position.x, ctx.pbr.lights.point[13].position.y, ctx.pbr.lights.point[13].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_94_uniform_location, ctx.pbr.lights.point[13].color.x, ctx.pbr.lights.point[13].color.y, ctx.pbr.lights.point[13].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_95_uniform_location, ctx.pbr.lights.point[13].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_96_uniform_location, ctx.pbr.lights.point[13].range);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_97_uniform_location, xx ctx.pbr.lights.point[13].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_98_uniform_location, ctx.pbr.lights.point[14].position.x, ctx.pbr.lights.point[14].position.y, ctx.pbr.lights.point[14].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_99_uniform_location, ctx.pbr.lights.point[14].color.x, ctx.pbr.lights.point[14].color.y, ctx.pbr.lights.point[14].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_100_uniform_location, ctx.pbr.lights.point[14].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_101_uniform_location, ctx.pbr.lights.point[14].range);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_102_uniform_location, xx ctx.pbr.lights.point[14].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_103_uniform_location, ctx.pbr.lights.point[15].position.x, ctx.pbr.lights.point[15].position.y, ctx.pbr.lights.point[15].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_104_uniform_location, ctx.pbr.lights.point[15].color.x, ctx.pbr.lights.point[15].color.y, ctx.pbr.lights.point[15].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_105_uniform_location, ctx.pbr.lights.point[15].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_106_uniform_location, ctx.pbr.lights.point[15].range);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_107_uniform_location, xx ctx.pbr.lights.point[15].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_108_uniform_location, ctx.pbr.lights.spot[0].position.x, ctx.pbr.lights.spot[0].position.y, ctx.pbr.lights.spot[0].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_109_uniform_location, ctx.pbr.lights.spot[0].direction.x, ctx.pbr.lights.spot[0].direction.y, ctx.pbr.lights.spot[0].direction.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_110_uniform_location, ctx.pbr.lights.spot[0].color.x, ctx.pbr.lights.spot[0].color.y, ctx.pbr.lights.spot[0].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_111_uniform_location, ctx.pbr.lights.spot[0].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_112_uniform_location, ctx.pbr.lights.spot[0].range);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_113_uniform_location, ctx.pbr.lights.spot[0].inner_cos);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_114_uniform_location, ctx.pbr.lights.spot[0].outer_cos);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_115_uniform_location, xx ctx.pbr.lights.spot[0].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_116_uniform_location, ctx.pbr.lights.spot[1].position.x, ctx.pbr.lights.spot[1].position.y, ctx.pbr.lights.spot[1].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_117_uniform_location, ctx.pbr.lights.spot[1].direction.x, ctx.pbr.lights.spot[1].direction.y, ctx.pbr.lights.spot[1].direction.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_118_uniform_location, ctx.pbr.lights.spot[1].color.x, ctx.pbr.lights.spot[1].color.y, ctx.pbr.lights.spot[1].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_119_uniform_location, ctx.pbr.lights.spot[1].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_120_uniform_location, ctx.pbr.lights.spot[1].range);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_121_uniform_location, ctx.pbr.lights.spot[1].inner_cos);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_122_uniform_location, ctx.pbr.lights.spot[1].outer_cos);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_123_uniform_location, xx ctx.pbr.lights.spot[1].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_124_uniform_location, ctx.pbr.lights.spot[2].position.x, ctx.pbr.lights.spot[2].position.y, ctx.pbr.lights.spot[2].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_125_uniform_location, ctx.pbr.lights.spot[2].direction.x, ctx.pbr.lights.spot[2].direction.y, ctx.pbr.lights.spot[2].direction.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_126_uniform_location, ctx.pbr.lights.spot[2].color.x, ctx.pbr.lights.spot[2].color.y, ctx.pbr.lights.spot[2].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_127_uniform_location, ctx.pbr.lights.spot[2].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_128_uniform_location, ctx.pbr.lights.spot[2].range);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_129_uniform_location, ctx.pbr.lights.spot[2].inner_cos);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_130_uniform_location, ctx.pbr.lights.spot[2].outer_cos);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_131_uniform_location, xx ctx.pbr.lights.spot[2].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_132_uniform_location, ctx.pbr.lights.spot[3].position.x, ctx.pbr.lights.spot[3].position.y, ctx.pbr.lights.spot[3].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_133_uniform_location, ctx.pbr.lights.spot[3].direction.x, ctx.pbr.lights.spot[3].direction.y, ctx.pbr.lights.spot[3].direction.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_134_uniform_location, ctx.pbr.lights.spot[3].color.x, ctx.pbr.lights.spot[3].color.y, ctx.pbr.lights.spot[3].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_135_uniform_location, ctx.pbr.lights.spot[3].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_136_uniform_location, ctx.pbr.lights.spot[3].range);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_137_uniform_location, ctx.pbr.lights.spot[3].inner_cos);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_138_uniform_location, ctx.pbr.lights.spot[3].outer_cos);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_139_uniform_location, xx ctx.pbr.lights.spot[3].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_140_uniform_location, ctx.pbr.lights.spot[4].position.x, ctx.pbr.lights.spot[4].position.y, ctx.pbr.lights.spot[4].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_141_uniform_location, ctx.pbr.lights.spot[4].direction.x, ctx.pbr.lights.spot[4].direction.y, ctx.pbr.lights.spot[4].direction.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_142_uniform_location, ctx.pbr.lights.spot[4].color.x, ctx.pbr.lights.spot[4].color.y, ctx.pbr.lights.spot[4].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_143_uniform_location, ctx.pbr.lights.spot[4].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_144_uniform_location, ctx.pbr.lights.spot[4].range);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_145_uniform_location, ctx.pbr.lights.spot[4].inner_cos);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_146_uniform_location, ctx.pbr.lights.spot[4].outer_cos);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_147_uniform_location, xx ctx.pbr.lights.spot[4].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_148_uniform_location, ctx.pbr.lights.spot[5].position.x, ctx.pbr.lights.spot[5].position.y, ctx.pbr.lights.spot[5].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_149_uniform_location, ctx.pbr.lights.spot[5].direction.x, ctx.pbr.lights.spot[5].direction.y, ctx.pbr.lights.spot[5].direction.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_150_uniform_location, ctx.pbr.lights.spot[5].color.x, ctx.pbr.lights.spot[5].color.y, ctx.pbr.lights.spot[5].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_151_uniform_location, ctx.pbr.lights.spot[5].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_152_uniform_location, ctx.pbr.lights.spot[5].range);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_153_uniform_location, ctx.pbr.lights.spot[5].inner_cos);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_154_uniform_location, ctx.pbr.lights.spot[5].outer_cos);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_155_uniform_location, xx ctx.pbr.lights.spot[5].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_156_uniform_location, ctx.pbr.lights.spot[6].position.x, ctx.pbr.lights.spot[6].position.y, ctx.pbr.lights.spot[6].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_157_uniform_location, ctx.pbr.lights.spot[6].direction.x, ctx.pbr.lights.spot[6].direction.y, ctx.pbr.lights.spot[6].direction.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_158_uniform_location, ctx.pbr.lights.spot[6].color.x, ctx.pbr.lights.spot[6].color.y, ctx.pbr.lights.spot[6].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_159_uniform_location, ctx.pbr.lights.spot[6].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_160_uniform_location, ctx.pbr.lights.spot[6].range);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_161_uniform_location, ctx.pbr.lights.spot[6].inner_cos);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_162_uniform_location, ctx.pbr.lights.spot[6].outer_cos);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_163_uniform_location, xx ctx.pbr.lights.spot[6].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_164_uniform_location, ctx.pbr.lights.spot[7].position.x, ctx.pbr.lights.spot[7].position.y, ctx.pbr.lights.spot[7].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_165_uniform_location, ctx.pbr.lights.spot[7].direction.x, ctx.pbr.lights.spot[7].direction.y, ctx.pbr.lights.spot[7].direction.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_166_uniform_location, ctx.pbr.lights.spot[7].color.x, ctx.pbr.lights.spot[7].color.y, ctx.pbr.lights.spot[7].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_167_uniform_location, ctx.pbr.lights.spot[7].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_168_uniform_location, ctx.pbr.lights.spot[7].range);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_169_uniform_location, ctx.pbr.lights.spot[7].inner_cos);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_170_uniform_location, ctx.pbr.lights.spot[7].outer_cos);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_171_uniform_location, xx ctx.pbr.lights.spot[7].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_172_uniform_location, ctx.pbr.lights.spot[8].position.x, ctx.pbr.lights.spot[8].position.y, ctx.pbr.lights.spot[8].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_173_uniform_location, ctx.pbr.lights.spot[8].direction.x, ctx.pbr.lights.spot[8].direction.y, ctx.pbr.lights.spot[8].direction.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_174_uniform_location, ctx.pbr.lights.spot[8].color.x, ctx.pbr.lights.spot[8].color.y, ctx.pbr.lights.spot[8].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_175_uniform_location, ctx.pbr.lights.spot[8].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_176_uniform_location, ctx.pbr.lights.spot[8].range);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_177_uniform_location, ctx.pbr.lights.spot[8].inner_cos);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_178_uniform_location, ctx.pbr.lights.spot[8].outer_cos);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_179_uniform_location, xx ctx.pbr.lights.spot[8].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_180_uniform_location, ctx.pbr.lights.spot[9].position.x, ctx.pbr.lights.spot[9].position.y, ctx.pbr.lights.spot[9].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_181_uniform_location, ctx.pbr.lights.spot[9].direction.x, ctx.pbr.lights.spot[9].direction.y, ctx.pbr.lights.spot[9].direction.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_182_uniform_location, ctx.pbr.lights.spot[9].color.x, ctx.pbr.lights.spot[9].color.y, ctx.pbr.lights.spot[9].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_183_uniform_location, ctx.pbr.lights.spot[9].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_184_uniform_location, ctx.pbr.lights.spot[9].range);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_185_uniform_location, ctx.pbr.lights.spot[9].inner_cos);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_186_uniform_location, ctx.pbr.lights.spot[9].outer_cos);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_187_uniform_location, xx ctx.pbr.lights.spot[9].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_188_uniform_location, ctx.pbr.lights.spot[10].position.x, ctx.pbr.lights.spot[10].position.y, ctx.pbr.lights.spot[10].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_189_uniform_location, ctx.pbr.lights.spot[10].direction.x, ctx.pbr.lights.spot[10].direction.y, ctx.pbr.lights.spot[10].direction.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_190_uniform_location, ctx.pbr.lights.spot[10].color.x, ctx.pbr.lights.spot[10].color.y, ctx.pbr.lights.spot[10].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_191_uniform_location, ctx.pbr.lights.spot[10].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_192_uniform_location, ctx.pbr.lights.spot[10].range);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_193_uniform_location, ctx.pbr.lights.spot[10].inner_cos);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_194_uniform_location, ctx.pbr.lights.spot[10].outer_cos);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_195_uniform_location, xx ctx.pbr.lights.spot[10].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_196_uniform_location, ctx.pbr.lights.spot[11].position.x, ctx.pbr.lights.spot[11].position.y, ctx.pbr.lights.spot[11].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_197_uniform_location, ctx.pbr.lights.spot[11].direction.x, ctx.pbr.lights.spot[11].direction.y, ctx.pbr.lights.spot[11].direction.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_198_uniform_location, ctx.pbr.lights.spot[11].color.x, ctx.pbr.lights.spot[11].color.y, ctx.pbr.lights.spot[11].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_199_uniform_location, ctx.pbr.lights.spot[11].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_200_uniform_location, ctx.pbr.lights.spot[11].range);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_201_uniform_location, ctx.pbr.lights.spot[11].inner_cos);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_202_uniform_location, ctx.pbr.lights.spot[11].outer_cos);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_203_uniform_location, xx ctx.pbr.lights.spot[11].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_204_uniform_location, ctx.pbr.lights.spot[12].position.x, ctx.pbr.lights.spot[12].position.y, ctx.pbr.lights.spot[12].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_205_uniform_location, ctx.pbr.lights.spot[12].direction.x, ctx.pbr.lights.spot[12].direction.y, ctx.pbr.lights.spot[12].direction.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_206_uniform_location, ctx.pbr.lights.spot[12].color.x, ctx.pbr.lights.spot[12].color.y, ctx.pbr.lights.spot[12].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_207_uniform_location, ctx.pbr.lights.spot[12].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_208_uniform_location, ctx.pbr.lights.spot[12].range);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_209_uniform_location, ctx.pbr.lights.spot[12].inner_cos);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_210_uniform_location, ctx.pbr.lights.spot[12].outer_cos);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_211_uniform_location, xx ctx.pbr.lights.spot[12].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_212_uniform_location, ctx.pbr.lights.spot[13].position.x, ctx.pbr.lights.spot[13].position.y, ctx.pbr.lights.spot[13].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_213_uniform_location, ctx.pbr.lights.spot[13].direction.x, ctx.pbr.lights.spot[13].direction.y, ctx.pbr.lights.spot[13].direction.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_214_uniform_location, ctx.pbr.lights.spot[13].color.x, ctx.pbr.lights.spot[13].color.y, ctx.pbr.lights.spot[13].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_215_uniform_location, ctx.pbr.lights.spot[13].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_216_uniform_location, ctx.pbr.lights.spot[13].range);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_217_uniform_location, ctx.pbr.lights.spot[13].inner_cos);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_218_uniform_location, ctx.pbr.lights.spot[13].outer_cos);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_219_uniform_location, xx ctx.pbr.lights.spot[13].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_220_uniform_location, ctx.pbr.lights.spot[14].position.x, ctx.pbr.lights.spot[14].position.y, ctx.pbr.lights.spot[14].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_221_uniform_location, ctx.pbr.lights.spot[14].direction.x, ctx.pbr.lights.spot[14].direction.y, ctx.pbr.lights.spot[14].direction.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_222_uniform_location, ctx.pbr.lights.spot[14].color.x, ctx.pbr.lights.spot[14].color.y, ctx.pbr.lights.spot[14].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_223_uniform_location, ctx.pbr.lights.spot[14].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_224_uniform_location, ctx.pbr.lights.spot[14].range);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_225_uniform_location, ctx.pbr.lights.spot[14].inner_cos);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_226_uniform_location, ctx.pbr.lights.spot[14].outer_cos);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_227_uniform_location, xx ctx.pbr.lights.spot[14].enabled);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_228_uniform_location, ctx.pbr.lights.spot[15].position.x, ctx.pbr.lights.spot[15].position.y, ctx.pbr.lights.spot[15].position.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_229_uniform_location, ctx.pbr.lights.spot[15].direction.x, ctx.pbr.lights.spot[15].direction.y, ctx.pbr.lights.spot[15].direction.z);
    gl_set_uniform_3f_on_active_shader_program(renderer.typed_230_uniform_location, ctx.pbr.lights.spot[15].color.x, ctx.pbr.lights.spot[15].color.y, ctx.pbr.lights.spot[15].color.z);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_231_uniform_location, ctx.pbr.lights.spot[15].intensity);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_232_uniform_location, ctx.pbr.lights.spot[15].range);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_233_uniform_location, ctx.pbr.lights.spot[15].inner_cos);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_234_uniform_location, ctx.pbr.lights.spot[15].outer_cos);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_235_uniform_location, xx ctx.pbr.lights.spot[15].enabled);
    gl_set_uniform_matrix_4fv_on_active_shader_program(renderer.typed_236_uniform_location, 1, GL_TRUE, *ctx.world_to_light_clip.coef[0][0]);
    gl_set_active_texture_unit(GL_TEXTURE0 + 5);
    gl_bind_texture_to_binding_target_of_active_texture_unit(GL_TEXTURE_2D,ctx.shadow_map);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_237_uniform_location,5);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_238_uniform_location, xx ctx.shadow_enabled);
    gl_set_active_texture_unit(GL_TEXTURE0);
    gl_clear_active_shader_program();
}


init :: (using renderer : *Pbr_Directional_Shadows_Skeletal_Animation_Renderer) -> bool {
    vertex_shader_source := Pbr_Directional_Shadows_Skeletal_Animation_Vertex_Source;
    fragment_shader_source := Pbr_Directional_Shadows_Skeletal_Animation_Fragment_Source;

    if !init(*renderer.psr, vertex_shader_source, fragment_shader_source, max_num_elements_in_each_buffer) return false;
    init_buffers_no_data(renderer);


    typed_0_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "vertex_uniforms.mesh.object_transforms");
    typed_1_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "vertex_uniforms.mesh.world_to_camera");
    typed_2_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "vertex_uniforms.mesh.camera_to_clip");
    typed_3_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "vertex_uniforms.bone_transforms");
    typed_4_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.resources.textures");
    typed_5_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.resources.bounding_boxes");
    typed_6_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.resources.materials");
    typed_7_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.camera_position");
    typed_8_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.ambient_strength");
    typed_9_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.directional_count");
    typed_10_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point_count");
    typed_11_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot_count");
    typed_12_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.directional[0].direction");
    typed_13_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.directional[0].color");
    typed_14_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.directional[0].intensity");
    typed_15_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.directional[0].enabled");
    typed_16_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.directional[1].direction");
    typed_17_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.directional[1].color");
    typed_18_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.directional[1].intensity");
    typed_19_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.directional[1].enabled");
    typed_20_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.directional[2].direction");
    typed_21_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.directional[2].color");
    typed_22_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.directional[2].intensity");
    typed_23_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.directional[2].enabled");
    typed_24_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.directional[3].direction");
    typed_25_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.directional[3].color");
    typed_26_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.directional[3].intensity");
    typed_27_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.directional[3].enabled");
    typed_28_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[0].position");
    typed_29_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[0].color");
    typed_30_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[0].intensity");
    typed_31_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[0].range");
    typed_32_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[0].enabled");
    typed_33_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[1].position");
    typed_34_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[1].color");
    typed_35_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[1].intensity");
    typed_36_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[1].range");
    typed_37_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[1].enabled");
    typed_38_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[2].position");
    typed_39_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[2].color");
    typed_40_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[2].intensity");
    typed_41_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[2].range");
    typed_42_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[2].enabled");
    typed_43_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[3].position");
    typed_44_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[3].color");
    typed_45_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[3].intensity");
    typed_46_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[3].range");
    typed_47_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[3].enabled");
    typed_48_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[4].position");
    typed_49_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[4].color");
    typed_50_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[4].intensity");
    typed_51_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[4].range");
    typed_52_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[4].enabled");
    typed_53_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[5].position");
    typed_54_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[5].color");
    typed_55_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[5].intensity");
    typed_56_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[5].range");
    typed_57_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[5].enabled");
    typed_58_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[6].position");
    typed_59_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[6].color");
    typed_60_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[6].intensity");
    typed_61_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[6].range");
    typed_62_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[6].enabled");
    typed_63_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[7].position");
    typed_64_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[7].color");
    typed_65_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[7].intensity");
    typed_66_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[7].range");
    typed_67_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[7].enabled");
    typed_68_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[8].position");
    typed_69_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[8].color");
    typed_70_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[8].intensity");
    typed_71_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[8].range");
    typed_72_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[8].enabled");
    typed_73_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[9].position");
    typed_74_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[9].color");
    typed_75_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[9].intensity");
    typed_76_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[9].range");
    typed_77_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[9].enabled");
    typed_78_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[10].position");
    typed_79_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[10].color");
    typed_80_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[10].intensity");
    typed_81_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[10].range");
    typed_82_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[10].enabled");
    typed_83_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[11].position");
    typed_84_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[11].color");
    typed_85_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[11].intensity");
    typed_86_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[11].range");
    typed_87_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[11].enabled");
    typed_88_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[12].position");
    typed_89_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[12].color");
    typed_90_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[12].intensity");
    typed_91_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[12].range");
    typed_92_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[12].enabled");
    typed_93_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[13].position");
    typed_94_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[13].color");
    typed_95_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[13].intensity");
    typed_96_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[13].range");
    typed_97_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[13].enabled");
    typed_98_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[14].position");
    typed_99_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[14].color");
    typed_100_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[14].intensity");
    typed_101_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[14].range");
    typed_102_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[14].enabled");
    typed_103_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[15].position");
    typed_104_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[15].color");
    typed_105_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[15].intensity");
    typed_106_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[15].range");
    typed_107_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.point[15].enabled");
    typed_108_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[0].position");
    typed_109_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[0].direction");
    typed_110_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[0].color");
    typed_111_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[0].intensity");
    typed_112_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[0].range");
    typed_113_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[0].inner_cos");
    typed_114_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[0].outer_cos");
    typed_115_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[0].enabled");
    typed_116_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[1].position");
    typed_117_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[1].direction");
    typed_118_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[1].color");
    typed_119_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[1].intensity");
    typed_120_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[1].range");
    typed_121_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[1].inner_cos");
    typed_122_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[1].outer_cos");
    typed_123_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[1].enabled");
    typed_124_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[2].position");
    typed_125_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[2].direction");
    typed_126_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[2].color");
    typed_127_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[2].intensity");
    typed_128_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[2].range");
    typed_129_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[2].inner_cos");
    typed_130_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[2].outer_cos");
    typed_131_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[2].enabled");
    typed_132_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[3].position");
    typed_133_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[3].direction");
    typed_134_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[3].color");
    typed_135_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[3].intensity");
    typed_136_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[3].range");
    typed_137_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[3].inner_cos");
    typed_138_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[3].outer_cos");
    typed_139_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[3].enabled");
    typed_140_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[4].position");
    typed_141_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[4].direction");
    typed_142_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[4].color");
    typed_143_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[4].intensity");
    typed_144_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[4].range");
    typed_145_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[4].inner_cos");
    typed_146_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[4].outer_cos");
    typed_147_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[4].enabled");
    typed_148_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[5].position");
    typed_149_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[5].direction");
    typed_150_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[5].color");
    typed_151_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[5].intensity");
    typed_152_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[5].range");
    typed_153_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[5].inner_cos");
    typed_154_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[5].outer_cos");
    typed_155_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[5].enabled");
    typed_156_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[6].position");
    typed_157_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[6].direction");
    typed_158_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[6].color");
    typed_159_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[6].intensity");
    typed_160_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[6].range");
    typed_161_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[6].inner_cos");
    typed_162_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[6].outer_cos");
    typed_163_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[6].enabled");
    typed_164_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[7].position");
    typed_165_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[7].direction");
    typed_166_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[7].color");
    typed_167_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[7].intensity");
    typed_168_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[7].range");
    typed_169_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[7].inner_cos");
    typed_170_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[7].outer_cos");
    typed_171_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[7].enabled");
    typed_172_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[8].position");
    typed_173_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[8].direction");
    typed_174_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[8].color");
    typed_175_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[8].intensity");
    typed_176_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[8].range");
    typed_177_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[8].inner_cos");
    typed_178_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[8].outer_cos");
    typed_179_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[8].enabled");
    typed_180_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[9].position");
    typed_181_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[9].direction");
    typed_182_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[9].color");
    typed_183_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[9].intensity");
    typed_184_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[9].range");
    typed_185_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[9].inner_cos");
    typed_186_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[9].outer_cos");
    typed_187_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[9].enabled");
    typed_188_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[10].position");
    typed_189_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[10].direction");
    typed_190_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[10].color");
    typed_191_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[10].intensity");
    typed_192_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[10].range");
    typed_193_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[10].inner_cos");
    typed_194_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[10].outer_cos");
    typed_195_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[10].enabled");
    typed_196_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[11].position");
    typed_197_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[11].direction");
    typed_198_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[11].color");
    typed_199_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[11].intensity");
    typed_200_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[11].range");
    typed_201_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[11].inner_cos");
    typed_202_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[11].outer_cos");
    typed_203_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[11].enabled");
    typed_204_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[12].position");
    typed_205_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[12].direction");
    typed_206_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[12].color");
    typed_207_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[12].intensity");
    typed_208_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[12].range");
    typed_209_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[12].inner_cos");
    typed_210_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[12].outer_cos");
    typed_211_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[12].enabled");
    typed_212_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[13].position");
    typed_213_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[13].direction");
    typed_214_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[13].color");
    typed_215_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[13].intensity");
    typed_216_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[13].range");
    typed_217_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[13].inner_cos");
    typed_218_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[13].outer_cos");
    typed_219_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[13].enabled");
    typed_220_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[14].position");
    typed_221_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[14].direction");
    typed_222_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[14].color");
    typed_223_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[14].intensity");
    typed_224_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[14].range");
    typed_225_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[14].inner_cos");
    typed_226_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[14].outer_cos");
    typed_227_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[14].enabled");
    typed_228_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[15].position");
    typed_229_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[15].direction");
    typed_230_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[15].color");
    typed_231_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[15].intensity");
    typed_232_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[15].range");
    typed_233_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[15].inner_cos");
    typed_234_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[15].outer_cos");
    typed_235_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.pbr.lights.spot[15].enabled");
    typed_236_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.world_to_light_clip");
    typed_237_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.shadow_map");
    typed_238_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "fragment_uniforms.shadow_enabled");

    return true;
}


deinit :: (using renderer : *Pbr_Directional_Shadows_Skeletal_Animation_Renderer) {
    deinit(*psr);

    gl_delete_buffer(positions_buffer_gl_handle);
    gl_delete_buffer(normals_buffer_gl_handle);
    gl_delete_buffer(tangents_buffer_gl_handle);
    gl_delete_buffer(uvs_buffer_gl_handle);
    gl_delete_buffer(material_indices_buffer_gl_handle);
    gl_delete_buffer(local_to_world_indices_buffer_gl_handle);
    gl_delete_buffer(bone_indices_buffer_gl_handle);
    gl_delete_buffer(bone_weights_buffer_gl_handle);
}



init_buffers_no_data :: (using apcr : *Pbr_Directional_Shadows_Skeletal_Animation_Renderer) { // todo change renderer name

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

    generate_buffer_for_vertex_attribute(*bone_indices_buffer_gl_handle, Shader_UInt4, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, bone_indices_buffer_gl_handle, "bone_indices", 4, GL_UNSIGNED_INT, GL_FALSE, 0, null);

    generate_buffer_for_vertex_attribute(*bone_weights_buffer_gl_handle, Vector4, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, bone_weights_buffer_gl_handle, "bone_weights", 4, GL_FLOAT, GL_FALSE, 0, null);



	gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, 0);
}


buffer_object :: (
    using renderer : *Pbr_Directional_Shadows_Skeletal_Animation_Renderer,
    renderable : *$T/interface Pbr_Directional_Shadows_Skeletal_Animation_Renderable,
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
            renderable.bone_indices,
            renderable.bone_weights,
            budgeter
    );

    if success {
        renderable.object_index = object_index;

    };
    return success;
}

// todo ability to specify the transform matrix upon buffering?
buffer_object :: (
        using renderer: *Pbr_Directional_Shadows_Skeletal_Animation_Renderer,
        indices : [] u32,
        positions : [] Vector3,
        normals : [] Vector3,
        tangents : [] Vector3,
        uvs : [] Vector2,
        material_indices : [] s32,
        local_to_world_indices : [] s32,
        bone_indices : [] Shader_UInt4,
        bone_weights : [] Vector4,

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



    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, bone_indices_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(budgeter, GL_ARRAY_BUFFER, index * size_of(Shader_UInt4), bone_indices.count * size_of(Shader_UInt4), bone_indices.data);



    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, bone_weights_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(budgeter, GL_ARRAY_BUFFER, index * size_of(Vector4), bone_weights.count * size_of(Vector4), bone_weights.data);




    gl_bind_vertex_array(0);

    return index, true;
}

/*

so this function is kinda sketchy right now, you can only rebuffer an object if it takes up the exact same size,
if you're rebuffering things and using up more space then you did before you'll start having undefined behavior in rendering and things
will go off the rails.

*/
rebuffer_object :: (using renderer : *Pbr_Directional_Shadows_Skeletal_Animation_Renderer, renderable : $T/interface Pbr_Directional_Shadows_Skeletal_Animation_Renderable) {

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

    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, bone_indices_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, renderable.object_index * size_of(Shader_UInt4), renderable.bone_indices.count * size_of(Shader_UInt4), renderable.bone_indices.data);

    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, bone_weights_buffer_gl_handle);
    gl_update_subdata_in_buffer_bound_to_binding_target(GL_ARRAY_BUFFER, renderable.object_index * size_of(Vector4), renderable.bone_weights.count * size_of(Vector4), renderable.bone_weights.data);


    gl_bind_buffer_to_binding_target(GL_ARRAY_BUFFER, 0);
    gl_bind_vertex_array(0);
}

render :: (using renderer : *Pbr_Directional_Shadows_Skeletal_Animation_Renderer, primitive_mode: GLenum = GL_TRIANGLES) {

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

Pbr_Directional_Shadows_Skeletal_Animation_Vertex_Source :: #string END_Pbr_Directional_Shadows_Skeletal_Animation_Vertex_Source
#version 330 core
// Generated from Jai procedure mesh_skinned_vertex_shader.
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
struct Skinned_Mesh_Vertex_Uniforms {
    Mesh_Vertex_Uniforms mesh;
    sampler2D bone_transforms;
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
struct Skinned_Mesh_Vertex {
    Mesh_Vertex mesh;
    uvec4 bone_indices;
    vec4 bone_weights;
};
in vec3 position;
in vec3 normal;
in vec3 tangent;
in vec2 uv;
in int material_index;
in int local_to_world_index;
in uvec4 bone_indices;
in vec4 bone_weights;
out vec3 passthrough_world_position;
out vec3 passthrough_normal;
out vec3 passthrough_tangent;
out vec2 passthrough_uv;
flat out int passthrough_material_index;
uniform Skinned_Mesh_Vertex_Uniforms vertex_uniforms;

vec4 jai_mesh_transform(sampler2D table, int index, vec4 value) {
    return vec4(dot(texelFetch(table, ivec2(0, index), 0), value), dot(texelFetch(table, ivec2(1, index), 0), value), dot(texelFetch(table, ivec2(2, index), 0), value), dot(texelFetch(table, ivec2(3, index), 0), value));
}

vec4 jai_mesh_skin_contribution(sampler2D table, uint index, float weight, vec4 value) {
    if (((index >= 100u) || (weight <= 0.0))) {
        return vec4(0.0);
    }
    return (jai_mesh_transform(table, int(index), value) * weight);
}

vec4 jai_mesh_skin(sampler2D table, uvec4 indices, vec4 weights, vec4 value) {
    float total = 0.0;
    if (((indices.x < 100u) && (weights.x > 0.0))) {
        total += weights.x;
    }
    if (((indices.y < 100u) && (weights.y > 0.0))) {
        total += weights.y;
    }
    if (((indices.z < 100u) && (weights.z > 0.0))) {
        total += weights.z;
    }
    if (((indices.w < 100u) && (weights.w > 0.0))) {
        total += weights.w;
    }
    if ((total <= 0.0)) {
        return value;
    }
    return (((jai_mesh_skin_contribution(table, indices.x, weights.x, value) + jai_mesh_skin_contribution(table, indices.y, weights.y, value)) + jai_mesh_skin_contribution(table, indices.z, weights.z, value)) + jai_mesh_skin_contribution(table, indices.w, weights.w, value));
}

Mesh_Transform_Result jai_mesh_skinned_geometry(Skinned_Mesh_Vertex_Uniforms uniforms, Skinned_Mesh_Vertex jai_var_input) {
    vec4 p = jai_mesh_skin(uniforms.bone_transforms, jai_var_input.bone_indices, jai_var_input.bone_weights, vec4(jai_var_input.mesh.position.x, jai_var_input.mesh.position.y, jai_var_input.mesh.position.z, 1.0));
    vec4 n = jai_mesh_skin(uniforms.bone_transforms, jai_var_input.bone_indices, jai_var_input.bone_weights, vec4(jai_var_input.mesh.normal.x, jai_var_input.mesh.normal.y, jai_var_input.mesh.normal.z, 0.0));
    vec4 t = jai_mesh_skin(uniforms.bone_transforms, jai_var_input.bone_indices, jai_var_input.bone_weights, vec4(jai_var_input.mesh.tangent.x, jai_var_input.mesh.tangent.y, jai_var_input.mesh.tangent.z, 0.0));
    p.w = 1.0;
    p = jai_mesh_transform(uniforms.mesh.object_transforms, jai_var_input.mesh.local_to_world_index, p);
    n = jai_mesh_transform(uniforms.mesh.object_transforms, jai_var_input.mesh.local_to_world_index, n);
    t = jai_mesh_transform(uniforms.mesh.object_transforms, jai_var_input.mesh.local_to_world_index, t);
    return Mesh_Transform_Result(p, normalize(vec3(n.x, n.y, n.z)), normalize(vec3(t.x, t.y, t.z)));
}

void main() {
    Skinned_Mesh_Vertex jai_var_input;
    jai_var_input.mesh.position = position;
    jai_var_input.mesh.normal = normal;
    jai_var_input.mesh.tangent = tangent;
    jai_var_input.mesh.uv = uv;
    jai_var_input.mesh.material_index = material_index;
    jai_var_input.mesh.local_to_world_index = local_to_world_index;
    jai_var_input.mesh.gpu.vertex_index = gl_VertexID;
    jai_var_input.mesh.gpu.instance_index = gl_InstanceID;
    jai_var_input.bone_indices = bone_indices;
    jai_var_input.bone_weights = bone_weights;
    Mesh_Transform_Result world = jai_mesh_skinned_geometry(vertex_uniforms, jai_var_input);
    gl_Position = ((vertex_uniforms.mesh.camera_to_clip * vertex_uniforms.mesh.world_to_camera) * world.position);
    passthrough_world_position = vec3(world.position.x, world.position.y, world.position.z);
    passthrough_normal = world.normal;
    passthrough_tangent = world.tangent;
    passthrough_uv = jai_var_input.mesh.uv;
    passthrough_material_index = jai_var_input.mesh.material_index;
}

END_Pbr_Directional_Shadows_Skeletal_Animation_Vertex_Source

Pbr_Directional_Shadows_Skeletal_Animation_Fragment_Source :: #string END_Pbr_Directional_Shadows_Skeletal_Animation_Fragment_Source
#version 330 core
// Generated from Jai procedure pbr_shadow_fragment_shader.
struct PBR_Surface {
    vec3 base_color;
    float alpha;
    float metallic;
    float roughness;
    vec3 normal;
};
struct Packed_Material_Textures {
    sampler2DArray textures;
    sampler1D bounding_boxes;
    sampler1D materials;
};
struct GLSL_Fragment_Shader_Input_Built_In_Variables {
    vec4 fragment_coord;
    bool front_facing;
    vec2 point_coord;
};
struct Mesh_Fragment_Input {
    GLSL_Fragment_Shader_Input_Built_In_Variables gpu;
    vec3 world_position;
    vec3 normal;
    vec3 tangent;
    vec2 uv;
    int material_index;
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
struct PBR_Fragment_Uniforms {
    Packed_Material_Textures resources;
    vec3 camera_position;
    float ambient_strength;
    Mesh_Lights lights;
};
struct PBR_Shadow_Fragment_Uniforms {
    PBR_Fragment_Uniforms pbr;
    mat4 world_to_light_clip;
    sampler2D shadow_map;
    bool shadow_enabled;
};
in vec3 passthrough_world_position;
in vec3 passthrough_normal;
in vec3 passthrough_tangent;
in vec2 passthrough_uv;
flat in int passthrough_material_index;
layout(location=0) out vec4 gpu_rendering_pipeline_stage_attachment_color;
uniform PBR_Shadow_Fragment_Uniforms fragment_uniforms;

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

PBR_Surface jai_pbr_surface(Packed_Material_Textures resources, Mesh_Fragment_Input jai_var_input) {
    int index = (jai_var_input.material_index * 4);
    vec4 base_slot = texelFetch(resources.materials, index, 0);
    vec4 factor = texelFetch(resources.materials, (index + 1), 0);
    vec4 normal_slot = texelFetch(resources.materials, (index + 2), 0);
    vec4 mr_slot = texelFetch(resources.materials, (index + 3), 0);
    vec4 base = jai_packed_material_sample(resources, jai_var_input.uv, base_slot.x, base_slot.y, vec4(1.0, 1.0, 1.0, 1.0));
    vec4 mr = jai_packed_material_sample(resources, jai_var_input.uv, mr_slot.x, mr_slot.y, vec4(1.0, 1.0, 1.0, 1.0));
    vec3 n = normalize(jai_var_input.normal);
    if (((normal_slot.x >= 0.0) && (normal_slot.y >= 0.0))) {
        vec4 sample = jai_packed_material_sample(resources, jai_var_input.uv, normal_slot.x, normal_slot.y, vec4(0.5, 0.5, 1.0, 1.0));
        n = jai_mesh_normal_map(n, jai_var_input.tangent, sample, 1.0);
    }
    return PBR_Surface(vec3((base.x * factor.x), (base.y * factor.y), (base.z * factor.z)), (base.w * factor.w), clamp((mr.z * mr_slot.z), 0.0, 1.0), clamp((mr.y * mr_slot.w), 0.04, 1.0), n);
}

float jai_pbr_shadow_visibility(PBR_Shadow_Fragment_Uniforms uniforms, Mesh_Fragment_Input jai_var_input, vec3 normal) {
    if (!(uniforms.shadow_enabled)) {
        return 1.0;
    }
    vec4 clip = (uniforms.world_to_light_clip * vec4(jai_var_input.world_position.x, jai_var_input.world_position.y, jai_var_input.world_position.z, 1.0));
    if ((clip.w <= 0.0)) {
        return 1.0;
    }
    vec3 p = vec3((((clip.x / clip.w) * 0.5) + 0.5), (((clip.y / clip.w) * 0.5) + 0.5), (((clip.z / clip.w) * 0.5) + 0.5));
    if (((((((p.x < 0.0) || (p.x > 1.0)) || (p.y < 0.0)) || (p.y > 1.0)) || (p.z < 0.0)) || (p.z > 1.0))) {
        return 1.0;
    }
    vec3 direction = normalize(vec3(0.35, 0.8, 0.45));
    if ((uniforms.pbr.lights.directional_count > 0)) {
        direction = normalize(-(uniforms.pbr.lights.directional[0].direction));
    }
    float bias = max((0.003 * (1.0 - dot(normal, direction))), 0.001);
    ivec2 size = textureSize(uniforms.shadow_map, 0);
    float visible = 0.0;
    for (int y = -(1), jai_glsl_range_end_0 = 1; y <= jai_glsl_range_end_0; ++y) {
        for (int x = -(1), jai_glsl_range_end_1 = 1; x <= jai_glsl_range_end_1; ++x) {
            vec4 sample = texture(uniforms.shadow_map, vec2((p.x + (float(x) / float(size.x))), (p.y + (float(y) / float(size.y)))));
            if (((p.z - bias) <= sample.x)) {
                visible += 1.0;
            }
        }
    }
    return (visible / 9.0);
}

vec3 jai_pbr_fresnel(float cosine, vec3 f0) {
    return (f0 + ((vec3(1.0, 1.0, 1.0) - f0) * pow(clamp((1.0 - cosine), 0.0, 1.0), 5.0)));
}

vec3 jai_mesh_multiply(vec3 a, vec3 b) {
    return vec3((a.x * b.x), (a.y * b.y), (a.z * b.z));
}

vec3 jai_pbr_light(PBR_Surface surface, vec3 view, vec3 light, vec3 radiance, bool specular_only) {
    vec3 n = surface.normal;
    float nl = max(dot(n, light), 0.0);
    float nv = max(dot(n, view), 0.0);
    if (((nl <= 0.0) || (nv <= 0.0))) {
        return vec3(0.0);
    }
    vec3 h = normalize((view + light));
    float a = (surface.roughness * surface.roughness);
    float a2 = (a * a);
    float nh = max(dot(n, h), 0.0);
    float denominator = (((nh * nh) * (a2 - 1.0)) + 1.0);
    float distribution = (a2 / max(((float(3.14159265359) * denominator) * denominator), 0.0000001));
    float k = (((surface.roughness + 1.0) * (surface.roughness + 1.0)) / 8.0);
    float geometry = ((nl / ((nl * (1.0 - k)) + k)) * (nv / ((nv * (1.0 - k)) + k)));
    vec3 f0 = ((vec3(0.04, 0.04, 0.04) * (1.0 - surface.metallic)) + (surface.base_color * surface.metallic));
    vec3 fresnel = jai_pbr_fresnel(max(dot(h, view), 0.0), f0);
    vec3 specular = (fresnel * ((distribution * geometry) / (((4.0 * nv) * nl) + 0.0001)));
    vec3 diffuse = (jai_mesh_multiply((vec3(1.0, 1.0, 1.0) - fresnel), surface.base_color) * ((1.0 - surface.metallic) / float(3.14159265359)));
    if (specular_only) {
        diffuse = vec3(0.0);
    }
    return (jai_mesh_multiply((diffuse + specular), radiance) * nl);
}

float jai_mesh_range_fade(float distance, float range) {
    if ((range <= 0.0)) {
        return 1.0;
    }
    return clamp((1.0 - pow((distance / range), 4.0)), 0.0, 1.0);
}

vec3 jai_pbr_lighting(PBR_Fragment_Uniforms uniforms, Mesh_Fragment_Input jai_var_input, PBR_Surface surface, float visibility, bool specular_only) {
    vec3 view = normalize((uniforms.camera_position - jai_var_input.world_position));
    vec3 color = vec3(0.0);
    for (int i = 0, jai_glsl_range_end_2 = (clamp(uniforms.lights.directional_count, 0, 4) - 1); i <= jai_glsl_range_end_2; ++i) {
        Mesh_Directional_Light light = uniforms.lights.directional[i];
        if (!(light.enabled)) {
            continue;
        }
        float shadow = 1.0;
        if ((i == 0)) {
            shadow = visibility;
        }
        color += jai_pbr_light(surface, view, normalize(-(light.direction)), (light.color * (light.intensity * shadow)), specular_only);
    }
    for (int i = 0, jai_glsl_range_end_3 = (clamp(uniforms.lights.point_count, 0, 16) - 1); i <= jai_glsl_range_end_3; ++i) {
        Mesh_Point_Light light = uniforms.lights.point[i];
        if (!(light.enabled)) {
            continue;
        }
        vec3 delta = (light.position - jai_var_input.world_position);
        float distance = sqrt(max(dot(delta, delta), 0.0001));
        vec3 radiance = (light.color * ((light.intensity * jai_mesh_range_fade(distance, light.range)) / max((distance * distance), 0.01)));
        color += jai_pbr_light(surface, view, (delta / distance), radiance, specular_only);
    }
    for (int i = 0, jai_glsl_range_end_4 = (clamp(uniforms.lights.spot_count, 0, 16) - 1); i <= jai_glsl_range_end_4; ++i) {
        Mesh_Spot_Light light = uniforms.lights.spot[i];
        if (!(light.enabled)) {
            continue;
        }
        vec3 delta = (light.position - jai_var_input.world_position);
        float distance = sqrt(max(dot(delta, delta), 0.0001));
        vec3 direction = (delta / distance);
        float cone = clamp(((dot(normalize(light.direction), -(direction)) - light.outer_cos) / max((light.inner_cos - light.outer_cos), 0.0001)), 0.0, 1.0);
        vec3 radiance = (light.color * (((light.intensity * cone) * jai_mesh_range_fade(distance, light.range)) / max((distance * distance), 0.01)));
        color += jai_pbr_light(surface, view, direction, radiance, specular_only);
    }
    if (((uniforms.lights.directional_count == 0) && !(specular_only))) {
        color += (surface.base_color * (max(dot(surface.normal, normalize(vec3(0.35, 0.8, 0.45))), 0.0) * visibility));
    }
    return color;
}

vec4 jai_pbr_display_color(vec3 color, float alpha) {
    vec3 mapped = vec3((color.x / (color.x + 1.0)), (color.y / (color.y + 1.0)), (color.z / (color.z + 1.0)));
    return vec4(pow(max(mapped.x, 0.0), (1.0 / 2.2)), pow(max(mapped.y, 0.0), (1.0 / 2.2)), pow(max(mapped.z, 0.0), (1.0 / 2.2)), alpha);
}

void main() {
    Mesh_Fragment_Input jai_var_input;
    jai_var_input.gpu.fragment_coord = gl_FragCoord;
    jai_var_input.gpu.front_facing = gl_FrontFacing;
    jai_var_input.gpu.point_coord = gl_PointCoord;
    jai_var_input.world_position = passthrough_world_position;
    jai_var_input.normal = passthrough_normal;
    jai_var_input.tangent = passthrough_tangent;
    jai_var_input.uv = passthrough_uv;
    jai_var_input.material_index = passthrough_material_index;
    PBR_Surface surface = jai_pbr_surface(fragment_uniforms.pbr.resources, jai_var_input);
    float visibility = jai_pbr_shadow_visibility(fragment_uniforms, jai_var_input, surface.normal);
    vec3 color = ((surface.base_color * fragment_uniforms.pbr.ambient_strength) + jai_pbr_lighting(fragment_uniforms.pbr, jai_var_input, surface, visibility, false));
    gpu_rendering_pipeline_stage_attachment_color = jai_pbr_display_color(color, surface.alpha);
}

END_Pbr_Directional_Shadows_Skeletal_Animation_Fragment_Source
