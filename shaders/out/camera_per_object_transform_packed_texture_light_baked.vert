#version 330 core

// Begin include: local_to_world_1024_ubo.glsl
in uint local_to_world_index;

layout(std140, row_major) uniform LtwMatrices {
    mat4 local_to_world_matrices[1024];
};
// End include: local_to_world_1024_ubo.glsl

in vec3 position;
in vec3 passthrough_normal;
in vec4 passthrough_tangent;

// Pack pairs of vec2 values into vec4 attributes. OpenGL 3.3 guarantees only
// 16 vertex attribute locations, so each independent vec2 cannot have its own.
in vec4 passthrough_base_color_and_normal_texture_coordinates;
in vec4 passthrough_metallic_roughness_and_ambient_occlusion_texture_coordinates;
in vec4 passthrough_emissive_and_lightmap_texture_coordinates;

in vec4 passthrough_base_color_factor; // @constant_across_object
in vec4 passthrough_material_parameters; // @constant_across_object
in vec3 passthrough_emissive_factor; // @constant_across_object
in vec2 passthrough_alpha_parameters; // @constant_across_object

// Each pair is (texture-array layer, bounding-box index). UINT_MAX means that
// a material channel has no texture.
in uvec4 passthrough_base_color_and_normal_texture_indices; // @constant_across_object
in uvec4 passthrough_metallic_roughness_and_ambient_occlusion_texture_indices; // @constant_across_object
// (emissive layer, emissive bounding-box index, lightmap atlas, unused)
in uvec4 passthrough_emissive_and_lightmap_texture_indices; // @constant_across_object

out vec3 world_position;
out vec3 world_normal;
out vec4 world_tangent;

out vec2 base_color_texture_coordinate;
out vec2 normal_texture_coordinate;
out vec2 metallic_roughness_texture_coordinate;
out vec2 ambient_occlusion_texture_coordinate;
out vec2 emissive_texture_coordinate;
out vec2 lightmap_texture_coordinate;

flat out vec4 base_color_factor;
flat out vec4 material_parameters;
flat out vec3 emissive_factor;
flat out vec2 alpha_parameters;

flat out uint packed_texture_index_for_base_color;
flat out uint packed_texture_bounding_box_index_for_base_color;
flat out uint packed_texture_index_for_normal;
flat out uint packed_texture_bounding_box_index_for_normal;
flat out uint packed_texture_index_for_metallic_roughness;
flat out uint packed_texture_bounding_box_index_for_metallic_roughness;
flat out uint packed_texture_index_for_ambient_occlusion;
flat out uint packed_texture_bounding_box_index_for_ambient_occlusion;
flat out uint packed_texture_index_for_emissive;
flat out uint packed_texture_bounding_box_index_for_emissive;
flat out uint lightmap_atlas_index;

uniform mat4 world_to_camera;
uniform mat4 camera_to_clip;

void main() {
    mat4 local_to_world = local_to_world_matrices[local_to_world_index];
    vec4 world_position4 = local_to_world * vec4(position, 1.0);
    mat3 direction_to_world = mat3(local_to_world);

    world_position = world_position4.xyz;
    world_normal = normalize(direction_to_world * passthrough_normal);
    world_tangent = vec4(
        normalize(direction_to_world * passthrough_tangent.xyz),
        passthrough_tangent.w
    );

    base_color_texture_coordinate = passthrough_base_color_and_normal_texture_coordinates.xy;
    normal_texture_coordinate = passthrough_base_color_and_normal_texture_coordinates.zw;
    metallic_roughness_texture_coordinate =
        passthrough_metallic_roughness_and_ambient_occlusion_texture_coordinates.xy;
    ambient_occlusion_texture_coordinate =
        passthrough_metallic_roughness_and_ambient_occlusion_texture_coordinates.zw;
    emissive_texture_coordinate = passthrough_emissive_and_lightmap_texture_coordinates.xy;
    lightmap_texture_coordinate = passthrough_emissive_and_lightmap_texture_coordinates.zw;

    base_color_factor = passthrough_base_color_factor;
    material_parameters = passthrough_material_parameters;
    emissive_factor = passthrough_emissive_factor;
    alpha_parameters = passthrough_alpha_parameters;

    packed_texture_index_for_base_color = passthrough_base_color_and_normal_texture_indices.x;
    packed_texture_bounding_box_index_for_base_color = passthrough_base_color_and_normal_texture_indices.y;
    packed_texture_index_for_normal = passthrough_base_color_and_normal_texture_indices.z;
    packed_texture_bounding_box_index_for_normal = passthrough_base_color_and_normal_texture_indices.w;
    packed_texture_index_for_metallic_roughness =
        passthrough_metallic_roughness_and_ambient_occlusion_texture_indices.x;
    packed_texture_bounding_box_index_for_metallic_roughness =
        passthrough_metallic_roughness_and_ambient_occlusion_texture_indices.y;
    packed_texture_index_for_ambient_occlusion =
        passthrough_metallic_roughness_and_ambient_occlusion_texture_indices.z;
    packed_texture_bounding_box_index_for_ambient_occlusion =
        passthrough_metallic_roughness_and_ambient_occlusion_texture_indices.w;
    packed_texture_index_for_emissive = passthrough_emissive_and_lightmap_texture_indices.x;
    packed_texture_bounding_box_index_for_emissive =
        passthrough_emissive_and_lightmap_texture_indices.y;
    lightmap_atlas_index = passthrough_emissive_and_lightmap_texture_indices.z;

    gl_Position = camera_to_clip * world_to_camera * world_position4;
}
