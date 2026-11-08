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
