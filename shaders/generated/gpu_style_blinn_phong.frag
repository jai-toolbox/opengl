#version 330 core

uniform vec3 camera_position;
uniform float ambient;
uniform float specular_strength;
uniform vec3 fallback_light_direction;

uniform int directional_light_count;
uniform vec3 directional_light_0_direction;
uniform vec3 directional_light_0_color;
uniform float directional_light_0_intensity;
uniform int point_light_count;
uniform vec3 point_light_0_position;
uniform vec3 point_light_0_color;
uniform float point_light_0_intensity;
uniform float point_light_0_range;
uniform int spot_light_count;
uniform vec3 spot_light_0_position;
uniform vec3 spot_light_0_direction;
uniform vec3 spot_light_0_color;
uniform float spot_light_0_intensity;
uniform float spot_light_0_range;
uniform float spot_light_0_inner_cos;
uniform float spot_light_0_outer_cos;

// Modular Blinn-Phong resource lowering:
// packed_textures is shared with the PBR lowering. Material texture indices
// select a sampler2DArray layer plus a source rectangle in the bbox table.
uniform sampler2DArray packed_textures;
uniform sampler1D packed_texture_bounding_boxes;

// blinn_phong_material_table contract:
//   texel 0: x = diffuse layer, y = diffuse bbox
//   texel 1: rgba = diffuse factor
//   texel 2: x = normal layer, y = normal bbox, z = normal scale
//   texel 3: x = spec-gloss layer, y = spec-gloss bbox, z = glossiness factor
//   texel 4: rgb = specular factor
uniform sampler1D blinn_phong_material_table;

in vec3 v_normal;
in vec3 v_tangent;
in vec2 v_uv;
in vec3 v_world_position;
flat in uint v_material_index;

out vec4 out_color;

vec4 get_bounding_box(int index) {
    return texture(packed_texture_bounding_boxes, (float(index) + 0.5) / 1024.0);
}

vec2 wrap_texture_coordinate(vec2 tc, vec4 bbox) {
    float tlx = bbox.x;
    float tly = bbox.y;
    float width = bbox.z;
    float height = bbox.w;
    vec2 wrapped = fract(tc);
    return vec2(tlx + wrapped.x * width, tly + wrapped.y * height);
}

vec4 sample_packed_texture(vec2 tex_coord, int texture_index, int bounding_box_index) {
    vec4 bbox = get_bounding_box(bounding_box_index);
    return texture(packed_textures, vec3(wrap_texture_coordinate(tex_coord, bbox), texture_index));
}

vec4 sample_packed_texture_or(vec2 tex_coord, int texture_index, int bounding_box_index, vec4 fallback) {
    if (texture_index < 0 || bounding_box_index < 0) return fallback;
    return sample_packed_texture(tex_coord, texture_index, bounding_box_index);
}

vec4 blinn_phong_material_table_texel(uint material_index, int slot) {
    int table_index = int(material_index) * 5 + slot;
    return texture(blinn_phong_material_table, (float(table_index) + 0.5) / 1280.0);
}

vec3 normal_from_packed_texture(vec3 n, vec3 tangent, vec2 uv, int texture_index, int bounding_box_index, float normal_scale) {
    vec3 nn = normalize(n);
    vec3 t = normalize(tangent - nn * dot(tangent, nn));
    vec3 b = cross(nn, t);
    vec3 tangent_normal = sample_packed_texture_or(uv, texture_index, bounding_box_index, vec4(0.5, 0.5, 1.0, 1.0)).xyz * 2.0 - vec3(1.0);
    tangent_normal.xy *= normal_scale;
    return normalize(t * tangent_normal.x + b * tangent_normal.y + nn * tangent_normal.z);
}

float range_attenuation(float distance_to_light, float range) {
    if (range <= 0.0) return 1.0;
    float t = clamp(1.0 - distance_to_light / range, 0.0, 1.0);
    return t * t;
}

float blinn_shininess(float glossiness) {
    float g = clamp(glossiness, 0.0, 1.0);
    return 2.0 + g * g * 254.0;
}

vec3 blinn_light(vec3 albedo, vec3 specular_color, float glossiness, vec3 n, vec3 v, vec3 l, vec3 light_color, float intensity) {
    float diffuse = max(0.0, dot(n, l));
    vec3 h = normalize(l + v);
    float specular = pow(max(0.0, dot(n, h)), blinn_shininess(glossiness)) * specular_strength;
    return albedo * light_color * diffuse * intensity + specular_color * light_color * specular * intensity;
}

void main() {
    vec4 diffuse_texture_info = blinn_phong_material_table_texel(v_material_index, 0);
    vec4 diffuse_factor = blinn_phong_material_table_texel(v_material_index, 1);
    vec4 normal_texture_info = blinn_phong_material_table_texel(v_material_index, 2);
    vec4 specular_glossiness_texture_info = blinn_phong_material_table_texel(v_material_index, 3);
    vec4 specular_factor_info = blinn_phong_material_table_texel(v_material_index, 4);

    int diffuse_texture_index = int(diffuse_texture_info.x + 0.5);
    int diffuse_bounding_box_index = int(diffuse_texture_info.y + 0.5);
    vec4 sampled_diffuse = sample_packed_texture_or(v_uv, diffuse_texture_index, diffuse_bounding_box_index, vec4(1.0));

    int normal_texture_index = int(normal_texture_info.x + 0.5);
    int normal_bounding_box_index = int(normal_texture_info.y + 0.5);
    float normal_scale = normal_texture_info.z;

    int specular_glossiness_texture_index = int(specular_glossiness_texture_info.x + 0.5);
    int specular_glossiness_bounding_box_index = int(specular_glossiness_texture_info.y + 0.5);
    vec4 sampled_specular_glossiness = sample_packed_texture_or(v_uv, specular_glossiness_texture_index, specular_glossiness_bounding_box_index, vec4(1.0));

    vec3 albedo = diffuse_factor.rgb * sampled_diffuse.rgb;
    vec3 specular_color = specular_factor_info.rgb * sampled_specular_glossiness.rgb;
    float glossiness = clamp(specular_glossiness_texture_info.z * sampled_specular_glossiness.a, 0.0, 1.0);

    vec3 n = normal_from_packed_texture(v_normal, v_tangent, v_uv, normal_texture_index, normal_bounding_box_index, normal_scale);
    vec3 v = normalize(camera_position - v_world_position);
    vec3 color = albedo * ambient;

    if (directional_light_count > 0) {
        color += blinn_light(albedo, specular_color, glossiness, n, v, normalize(directional_light_0_direction), directional_light_0_color, directional_light_0_intensity);
    }

    if (point_light_count > 0) {
        vec3 to_light = point_light_0_position - v_world_position;
        float distance_to_light = length(to_light);
        color += blinn_light(albedo, specular_color, glossiness, n, v, normalize(to_light), point_light_0_color, point_light_0_intensity * range_attenuation(distance_to_light, point_light_0_range));
    }

    if (spot_light_count > 0) {
        vec3 to_light = spot_light_0_position - v_world_position;
        float distance_to_light = length(to_light);
        vec3 l = normalize(to_light);
        float spot_cos = dot(normalize(spot_light_0_direction), -l);
        float spot_fade = clamp((spot_cos - spot_light_0_outer_cos) / max(spot_light_0_inner_cos - spot_light_0_outer_cos, 0.0001), 0.0, 1.0);
        color += blinn_light(albedo, specular_color, glossiness, n, v, l, spot_light_0_color, spot_light_0_intensity * range_attenuation(distance_to_light, spot_light_0_range) * spot_fade);
    }

    if (directional_light_count == 0 && point_light_count == 0 && spot_light_count == 0) {
        color += blinn_light(albedo, specular_color, glossiness, n, v, normalize(fallback_light_direction), vec3(1.0), 1.0);
    }

    out_color = vec4(clamp(color, 0.0, 1.0), diffuse_factor.a * sampled_diffuse.a);
}
