#version 330 core

uniform vec3 camera_position;
uniform float ambient_strength;
uniform int directional_light_count;
uniform vec3 directional_light_0_direction;
uniform vec3 directional_light_0_color;
uniform float directional_light_0_intensity;

// Material textures use the packed texture array. The baked lightmap is the
// baker's float irradiance output, uploaded separately as GL_RGBA32F.
uniform sampler2DArray packed_textures;
uniform sampler1D packed_texture_bounding_boxes;
uniform sampler1D pbr_material_table;
uniform sampler2D lightmap_texture;

in vec3 v_world_position;
in vec3 v_normal;
in vec3 v_tangent;
in vec2 v_uv;
in vec2 v_lightmap_uv;
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

vec4 material_table_texel(uint material_index, int slot) {
    int table_index = int(material_index) * 4 + slot;
    return texture(pbr_material_table, (float(table_index) + 0.5) / 256.0);
}

vec3 normal_from_packed_texture(vec3 n, vec3 tangent, vec2 uv, int texture_index, int bounding_box_index) {
    vec3 nn = normalize(n);
    vec3 t = normalize(tangent - nn * dot(tangent, nn));
    vec3 b = cross(nn, t);
    vec3 tangent_normal = sample_packed_texture_or(uv, texture_index, bounding_box_index, vec4(0.5, 0.5, 1.0, 1.0)).xyz * 2.0 - vec3(1.0);
    return normalize(t * tangent_normal.x + b * tangent_normal.y + nn * tangent_normal.z);
}

float pbr_distribution_ggx(vec3 n, vec3 h, float roughness) {
    float a = (roughness * roughness);
    float a2 = (a * a);
    float ndoth = max(dot(n, h), 0.0);
    float ndoth2 = (ndoth * ndoth);
    float denom = ((ndoth2 * (a2 - 1.0)) + 1.0);
    denom = ((3.14159265359 * denom) * denom);
    return (a2 / max(denom, float(0.0000001)));
}

float pbr_geometry_schlick_ggx(float ndotv, float roughness) {
    float r = (roughness + 1.0);
    float k = ((r * r) / 8.0);
    return (ndotv / ((ndotv * (1.0 - k)) + k));
}

float pbr_geometry_smith(vec3 n, vec3 v, vec3 l, float roughness) {
    float ndotv = max(dot(n, v), 0.0);
    float ndotl = max(dot(n, l), 0.0);
    return (pbr_geometry_schlick_ggx(ndotv, roughness) * pbr_geometry_schlick_ggx(ndotl, roughness));
}

vec3 pbr_fresnel_schlick(float cos_theta, vec3 f0) {
    float f = pow(clamp((1.0 - cos_theta), 0.0, 1.0), 5.0);
    return vec3((f0.x + ((1.0 - f0.x) * f)), (f0.y + ((1.0 - f0.y) * f)), (f0.z + ((1.0 - f0.z) * f)));
}

vec3 gpu_style_pbr_light_contribution(vec3 n, vec3 v, vec3 l, vec3 radiance, vec3 base_color, float metallic, float roughness, vec3 f0) {
    const float pi = float(3.14159265359);
    vec3 h = normalize((v + l));
    float ndotl = max(float(0.0), dot(n, l));
    float ndotv = max(float(0.0), dot(n, v));
    if (((ndotl <= 0.0) || (ndotv <= 0.0))) {
        return vec3(0.0);
    }
    float d = pbr_distribution_ggx(n, h, roughness);
    float g = pbr_geometry_smith(n, v, l, roughness);
    vec3 f = pbr_fresnel_schlick(max(dot(h, v), 0.0), f0);
    float denominator = (((4.0 * ndotv) * ndotl) + 0.0001);
    vec3 specular = (f * ((d * g) / denominator));
    vec3 kd = (vec3((1.0 - f.x), (1.0 - f.y), (1.0 - f.z)) * (1.0 - metallic));
    vec3 diffuse = ((kd * base_color) * (1.0 / pi));
    return (((diffuse + specular) * radiance) * ndotl);
}


vec3 gpu_style_pbr_specular_contribution(
    vec3 n,
    vec3 v,
    vec3 l,
    vec3 radiance,
    float roughness,
    vec3 f0
) {
    vec3 h = normalize(v + l);
    float ndotl = max(0.0, dot(n, l));
    float ndotv = max(0.0, dot(n, v));
    if (ndotl <= 0.0 || ndotv <= 0.0) return vec3(0.0);

    float d = pbr_distribution_ggx(n, h, roughness);
    float g = pbr_geometry_smith(n, v, l, roughness);
    vec3 f = pbr_fresnel_schlick(max(dot(h, v), 0.0), f0);
    vec3 specular = f * (d * g / (4.0 * ndotv * ndotl + 0.0001));
    return specular * radiance * ndotl;
}

void main() {
    vec4 base_color_texture_info = material_table_texel(v_material_index, 0);
    vec4 base_color_factor = material_table_texel(v_material_index, 1);
    vec4 normal_texture_info = material_table_texel(v_material_index, 2);
    vec4 metallic_roughness_texture_info = material_table_texel(v_material_index, 3);

    int base_color_texture_index = int(base_color_texture_info.x + 0.5);
    int base_color_bounding_box_index = int(base_color_texture_info.y + 0.5);
    vec4 sampled_base_color = sample_packed_texture_or(v_uv, base_color_texture_index, base_color_bounding_box_index, vec4(1.0));

    int normal_texture_index = int(normal_texture_info.x + 0.5);
    int normal_bounding_box_index = int(normal_texture_info.y + 0.5);

    int metallic_roughness_texture_index = int(metallic_roughness_texture_info.x + 0.5);
    int metallic_roughness_bounding_box_index = int(metallic_roughness_texture_info.y + 0.5);
    vec4 sampled_mr = sample_packed_texture_or(v_uv, metallic_roughness_texture_index, metallic_roughness_bounding_box_index, vec4(1.0));

    vec3 base_color = sampled_base_color.rgb * base_color_factor.rgb;
    float metallic = clamp(metallic_roughness_texture_info.z * sampled_mr.b, 0.0, 1.0);
    float roughness = clamp(metallic_roughness_texture_info.w * sampled_mr.g, 0.04, 1.0);

    vec3 n = normal_from_packed_texture(v_normal, v_tangent, v_uv, normal_texture_index, normal_bounding_box_index);
    vec3 v = normalize(camera_position - v_world_position);
    vec3 f0 = vec3(0.04) + (base_color - vec3(0.04)) * metallic;

    vec3 lightmap = texture(lightmap_texture, clamp(v_lightmap_uv, vec2(0.0), vec2(1.0))).rgb;

    vec3 baked_diffuse = base_color * lightmap;
    vec3 color = mix(baked_diffuse, lightmap, metallic);
    color += base_color * ambient_strength * 0.05;

    if (directional_light_count > 0) {
        vec3 l = normalize(-directional_light_0_direction);
        vec3 radiance = directional_light_0_color * directional_light_0_intensity;
        color += gpu_style_pbr_specular_contribution(n, v, l, radiance, roughness, f0);
    }

    color = color / (color + vec3(1.0));
    color = pow(max(color, vec3(0.0)), vec3(1.0 / 2.2));
    out_color = vec4(clamp(color, 0.0, 1.0), sampled_base_color.a * base_color_factor.a);
}
