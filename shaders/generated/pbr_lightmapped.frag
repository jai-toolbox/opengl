#version 330 core
// Generated from Jai procedure pbr_lightmapped_fragment_shader.
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
struct Lightmapped_Mesh_Fragment_Input {
    Mesh_Fragment_Input mesh;
    vec2 lightmap_uv;
};
in vec3 passthrough_world_position;
in vec3 passthrough_normal;
in vec3 passthrough_tangent;
in vec2 passthrough_uv;
flat in int passthrough_material_index;
in vec2 passthrough_lightmap_uv;
layout(location=0) out vec4 gpu_rendering_pipeline_stage_attachment_color;
uniform PBR_Fragment_Uniforms pbr;
uniform sampler2D lightmap;

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

vec3 jai_mesh_multiply(vec3 a, vec3 b) {
    return vec3((a.x * b.x), (a.y * b.y), (a.z * b.z));
}

vec3 jai_pbr_fresnel(float cosine, vec3 f0) {
    return (f0 + ((vec3(1.0, 1.0, 1.0) - f0) * pow(clamp((1.0 - cosine), 0.0, 1.0), 5.0)));
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
    for (int i = 0, jai_glsl_range_end_0 = (clamp(uniforms.lights.directional_count, 0, 4) - 1); i <= jai_glsl_range_end_0; ++i) {
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
    for (int i = 0, jai_glsl_range_end_1 = (clamp(uniforms.lights.point_count, 0, 16) - 1); i <= jai_glsl_range_end_1; ++i) {
        Mesh_Point_Light light = uniforms.lights.point[i];
        if (!(light.enabled)) {
            continue;
        }
        vec3 delta = (light.position - jai_var_input.world_position);
        float distance = sqrt(max(dot(delta, delta), 0.0001));
        vec3 radiance = (light.color * ((light.intensity * jai_mesh_range_fade(distance, light.range)) / max((distance * distance), 0.01)));
        color += jai_pbr_light(surface, view, (delta / distance), radiance, specular_only);
    }
    for (int i = 0, jai_glsl_range_end_2 = (clamp(uniforms.lights.spot_count, 0, 16) - 1); i <= jai_glsl_range_end_2; ++i) {
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
    Lightmapped_Mesh_Fragment_Input jai_var_input;
    jai_var_input.mesh.gpu.fragment_coord = gl_FragCoord;
    jai_var_input.mesh.gpu.front_facing = gl_FrontFacing;
    jai_var_input.mesh.gpu.point_coord = gl_PointCoord;
    jai_var_input.mesh.world_position = passthrough_world_position;
    jai_var_input.mesh.normal = passthrough_normal;
    jai_var_input.mesh.tangent = passthrough_tangent;
    jai_var_input.mesh.uv = passthrough_uv;
    jai_var_input.mesh.material_index = passthrough_material_index;
    jai_var_input.lightmap_uv = passthrough_lightmap_uv;
    PBR_Surface surface = jai_pbr_surface(pbr.resources, jai_var_input.mesh);
    vec4 sample = texture(lightmap, clamp(jai_var_input.lightmap_uv, 0.0, 1.0));
    vec3 irradiance = vec3(sample.x, sample.y, sample.z);
    vec3 diffuse = ((jai_mesh_multiply(surface.base_color, irradiance) * (1.0 - surface.metallic)) + (irradiance * surface.metallic));
    vec3 color = ((diffuse + (surface.base_color * (pbr.ambient_strength * 0.05))) + jai_pbr_lighting(pbr, jai_var_input.mesh, surface, 1.0, true));
    gpu_rendering_pipeline_stage_attachment_color = jai_pbr_display_color(color, surface.alpha);
}
