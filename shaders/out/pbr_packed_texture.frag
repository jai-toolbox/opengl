#version 330 core

// Begin include: packed_texture_sampling.glsl
// Resource contract:
// packed_textures is an OpenGL 3.3 bindless-texture workaround. It is a texture
// array whose layers are power-of-two container textures. Each container layer
// may itself hold many smaller source textures packed into rectangular regions.
// The runtime texture packer owns creating and uploading this array.
//
// Geometry does not bind a different texture per object. Instead, vertex
// attributes carry integer indices that select a packed container layer and a
// bounding-box entry. This lets many objects draw together without one draw call
// per texture bind.
uniform sampler2DArray packed_textures;

// the next lines are really bad and cause stuff to break 
// because running out of uniform space, instead 
// use a texture thing: https://stackoverflow.com/questions/51781227/estimate-number-of-registers-required-in-glsl-shader

// packed_texture_bounding_boxes stores vec4 entries in the form:
//   x = top-left u, y = top-left v, z = width, w = height
// Each entry describes the sub-rectangle for one packed source texture inside a
// container layer of packed_textures. Vertex attributes choose which entry to
// use for each object/material channel.
uniform sampler1D packed_texture_bounding_boxes;
//
// note that before we used to do this, but it caused an array about using up too many constant registers
// which come from using too many uniforms, so we no longer do the below, but instead the above.
// 
#define MAX_NUM_TEXTURES 1024
// uniform vec4 packed_texture_bounding_boxes[MAX_NUM_TEXTURES];


vec4 get_bounding_box(int index) {
    // this is the definition of how bounding boxes are stored in textures, as vector4s
    return texture( packed_texture_bounding_boxes, float(index) / float(MAX_NUM_TEXTURES));
}

/*

Wraps a texture coordinate (tc) to stay within the given bounding box. 

We assume that the tc is in the packed texture space (not local uvs)

 */
vec2 wrap_texture_coordinate(vec2 tc, vec4 bbox) {
    float tlx = bbox.x;      // top-left x
    float tly = bbox.y;      // top-left y
    float width = bbox.z;    
    float height = bbox.w;   

    // calculate deltas from the top-left corner
    float dx = tc.x - tlx;
    float dy = tc.y - tly;

    // wrap the coordinates using modulo and shift back into the bounding box
    float wrapped_x = mod(dx, width) + tlx;
    float wrapped_y = mod(dy, height) + tly;

    return vec2(wrapped_x, wrapped_y);
}

/**
 * @brief Samples from a 2D texture array.
 * 
 * @param texture_array The sampler2DArray containing the packed textures.
 * @param tex_coord The 2D texture coordinates for sampling.
 * @param texture_index The index of the texture in the array.
 * @param bounding_boxes The array of bounding boxes for the textures.
 * @param bounding_box_index The index of the bounding box for the current texture.
 * @return vec4 The sampled color from the texture.
 */
vec4 sample_packed_texture(
    sampler2DArray texture_array,
    vec2 tex_coord,
    int texture_index,
    int bounding_box_index
) {
    vec4 bbox = get_bounding_box(bounding_box_index);
    return texture(texture_array, vec3(wrap_texture_coordinate(tex_coord, bbox), texture_index));
}
// End include: packed_texture_sampling.glsl

in vec3 world_position;
in vec3 world_normal;
in vec3 world_tangent;
in vec2 texture_coordinate;
flat in vec4 base_color_factor;
flat in vec2 alpha_parameters;
in vec4 light_clip_position;

flat in int packed_texture_index_for_base_color;
flat in int packed_texture_bounding_box_index_for_base_color;

flat in int packed_texture_index_for_normal;
flat in int packed_texture_bounding_box_index_for_normal;

flat in int packed_texture_index_for_metallic_roughness;
flat in int packed_texture_bounding_box_index_for_metallic_roughness;

flat in int packed_texture_index_for_ambient_occlusion;
flat in int packed_texture_bounding_box_index_for_ambient_occlusion;

#define MAX_LIGHTS 16
#define MAX_SPOT_LIGHTS 16

struct Light {
    vec3 position;
    vec3 color;
};

struct SpotLight {
    vec3 position;
    vec3 direction;
    vec3 color;
    float inner_cos;
    float outer_cos;
    float range;
};

uniform Light lights[MAX_LIGHTS];
uniform int num_active_lights;
uniform SpotLight spot_lights[MAX_SPOT_LIGHTS];
uniform int num_active_spot_lights;

uniform vec3 camera_position;
uniform samplerCube reflection_cubemap;
uniform bool use_reflection_cubemap = false;
uniform float reflection_strength = 1.0;
uniform sampler2D directional_shadow_map;
uniform bool use_directional_shadow_map = false;

struct DirectionalLight {
    vec3 direction;
    vec3 color;
    float intensity;
    bool enabled;
};

uniform DirectionalLight directional_light;

uniform vec3  default_base_color        = vec3(0.8, 0.8, 0.8);
uniform float default_metallic          = 0.0;
uniform float default_roughness         = 0.5;
uniform float default_ambient_occlusion = 1.0;

out vec4 frag_color;

const float PI = 3.14159265359;
const float ALPHA_MODE_OPAQUE = 0.0;
const float ALPHA_MODE_MASK = 1.0;
const float ALPHA_MODE_BLEND = 2.0;

// potentially we can move these out of here in the future

float distribution_ggx(vec3 N, vec3 H, float roughness) {
    float a  = roughness * roughness;
    float a2 = a * a;
    float NdotH  = max(dot(N, H), 0.0);
    float NdotH2 = NdotH * NdotH;

    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom;

    return a2 / max(denom, 0.0000001);
}

float geometry_schlick_ggx(float NdotV, float roughness) {
    float r = roughness + 1.0;
    float k = (r * r) / 8.0;
    return NdotV / (NdotV * (1.0 - k) + k);
}

float geometry_smith(vec3 N, vec3 V, vec3 L, float roughness) {
    float NdotV = max(dot(N, V), 0.0);
    float NdotL = max(dot(N, L), 0.0);
    return geometry_schlick_ggx(NdotV, roughness) * geometry_schlick_ggx(NdotL, roughness);
}

vec3 fresnel_schlick(float cos_theta, vec3 F0) {
    return F0 + (1.0 - F0) * pow(clamp(1.0 - cos_theta, 0.0, 1.0), 5.0);
}

float sample_directional_shadow(vec4 light_clip, vec3 N, vec3 L) {
    if (!use_directional_shadow_map) return 1.0;

    vec3 proj = light_clip.xyz / light_clip.w;
    proj = proj * 0.5 + 0.5;

    if (proj.x < 0.0 || proj.x > 1.0 || proj.y < 0.0 || proj.y > 1.0 || proj.z > 1.0) {
        return 1.0;
    }

    float bias = max(0.0015 * (1.0 - dot(N, L)), 0.0004);
    vec2 texel_size = 1.0 / textureSize(directional_shadow_map, 0);
    float visibility = 0.0;

    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            float closest_depth = texture(directional_shadow_map, proj.xy + vec2(x, y) * texel_size).r;
            visibility += (proj.z - bias <= closest_depth) ? 1.0 : 0.0;
        }
    }

    return visibility / 9.0;
}

vec3 get_normal_from_map(vec3 sampled_normal) {
    vec3 N = normalize(world_normal);
    vec3 T = normalize(world_tangent - dot(world_tangent, N) * N);
    vec3 B = cross(N, T);
    mat3 TBN = mat3(T, B, N);

    vec3 tangent_normal = sampled_normal * 2.0 - 1.0;
    return normalize(TBN * tangent_normal);
}

vec4 sample_channel(vec2 tc, int tex_idx, int bb_idx, vec4 fallback) {
    if (tex_idx < 0) return fallback;
    return sample_packed_texture(packed_textures, tc, tex_idx, bb_idx);
}

void main() {

    vec4 base_color_sample = sample_channel(
        texture_coordinate,
        packed_texture_index_for_base_color,
        packed_texture_bounding_box_index_for_base_color,
        vec4(default_base_color, 1.0)
    );

    vec4 normal_sample = sample_channel(
        texture_coordinate,
        packed_texture_index_for_normal,
        packed_texture_bounding_box_index_for_normal,
        vec4(0.5, 0.5, 1.0, 1.0)
    );

    // glTF metallicRoughness: G = roughness, B = metallic
    vec4 mr_sample = sample_channel(
        texture_coordinate,
        packed_texture_index_for_metallic_roughness,
        packed_texture_bounding_box_index_for_metallic_roughness,
        vec4(0.0, default_roughness, 0.0, default_metallic)
    );

    vec4 ao_sample = sample_channel(
        texture_coordinate,
        packed_texture_index_for_ambient_occlusion,
        packed_texture_bounding_box_index_for_ambient_occlusion,
        vec4(default_ambient_occlusion)
    );

    vec3  base_color = base_color_sample.rgb * base_color_factor.rgb;
    float alpha      = base_color_sample.a * base_color_factor.a;
    float alpha_mode = alpha_parameters.x;
    float alpha_cutoff = alpha_parameters.y;
    float metallic   = mr_sample.b;
    float roughness  = clamp(mr_sample.g, 0.04, 1.0);
    float ao         = ao_sample.r;

    if (alpha_mode == ALPHA_MODE_MASK && alpha < alpha_cutoff) {
        discard;
    }

    vec3 N = get_normal_from_map(normal_sample.rgb);
    vec3 V = normalize(camera_position - world_position);

    vec3 F0 = mix(vec3(0.04), base_color, metallic);

    vec3 diffuse_lighting = vec3(0.0);
    vec3 specular_lighting = vec3(0.0);

    for (int i = 0; i < MAX_LIGHTS; i++) {
        if (i >= num_active_lights) break;

        vec3 L = normalize(lights[i].position - world_position);
        vec3 H = normalize(V + L);

        float distance    = length(lights[i].position - world_position);
        float attenuation = 1.0 / (distance * distance);
        vec3  radiance    = lights[i].color * attenuation;

        float D = distribution_ggx(N, H, roughness);
        float G = geometry_smith(N, V, L, roughness);
        vec3  F = fresnel_schlick(max(dot(H, V), 0.0), F0);

        vec3  numerator   = D * G * F;
        float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0) + 0.0001;
        vec3  specular    = numerator / denominator;

        vec3 kS = F;
        vec3 kD = (vec3(1.0) - kS) * (1.0 - metallic);

        float NdotL = max(dot(N, L), 0.0);

        diffuse_lighting += (kD * base_color / PI) * radiance * NdotL;
        specular_lighting += specular * radiance * NdotL;
    }

    for (int i = 0; i < MAX_SPOT_LIGHTS; i++) {
        if (i >= num_active_spot_lights) break;

        vec3 L_unorm = spot_lights[i].position - world_position;
        float distance = length(L_unorm);
        vec3 L = L_unorm / max(distance, 0.0001);

        float spot_cos = dot(normalize(spot_lights[i].direction), -L);
        float spot_fade = clamp((spot_cos - spot_lights[i].outer_cos) / max(spot_lights[i].inner_cos - spot_lights[i].outer_cos, 0.0001), 0.0, 1.0);

        float range_fade = 1.0;
        if (spot_lights[i].range > 0.0) {
            range_fade = clamp(1.0 - pow(distance / spot_lights[i].range, 4.0), 0.0, 1.0);
        }

        vec3 H = normalize(V + L);
        float D = distribution_ggx(N, H, roughness);
        float G = geometry_smith(N, V, L, roughness);
        vec3  F = fresnel_schlick(max(dot(H, V), 0.0), F0);

        vec3  numerator   = D * G * F;
        float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0) + 0.0001;
        vec3  specular    = numerator / denominator;

        vec3 kS = F;
        vec3 kD = (vec3(1.0) - kS) * (1.0 - metallic);

        float attenuation = 1.0 / max(distance * distance, 0.0001);
        vec3 radiance = spot_lights[i].color * attenuation * spot_fade * range_fade;
        float NdotL = max(dot(N, L), 0.0);

        diffuse_lighting += (kD * base_color / PI) * radiance * NdotL;
        specular_lighting += specular * radiance * NdotL;
    }

    if (directional_light.enabled) {
        vec3 L = normalize(-directional_light.direction);
        vec3 H = normalize(V + L);

        float D = distribution_ggx(N, H, roughness);
        float G = geometry_smith(N, V, L, roughness);
        vec3  F = fresnel_schlick(max(dot(H, V), 0.0), F0);

        vec3  numerator   = D * G * F;
        float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0) + 0.0001;
        vec3  specular    = numerator / denominator;

        vec3 kS = F;
        vec3 kD = (vec3(1.0) - kS) * (1.0 - metallic);

        float NdotL = max(dot(N, L), 0.0);
        float shadow_visibility = sample_directional_shadow(light_clip_position, N, L);
        vec3 radiance = directional_light.color * directional_light.intensity;

        diffuse_lighting += (kD * base_color / PI) * radiance * NdotL * shadow_visibility;
        specular_lighting += specular * radiance * NdotL * shadow_visibility;
    }

    vec3 ambient = vec3(0.03) * base_color * ao;
    vec3 env_specular = vec3(0.0);

    if (use_reflection_cubemap) {
        vec3 R = reflect(-V, N);
        vec3 env_color = textureLod(reflection_cubemap, R, roughness * 4.0).rgb;
        vec3 F = fresnel_schlick(max(dot(N, V), 0.0), F0);
        env_specular = env_color * F * (1.0 - roughness * 0.65) * reflection_strength * ao;
    }

    vec3 color;
    float output_alpha = alpha;
    if (alpha_mode == ALPHA_MODE_BLEND) {
        vec3 F = fresnel_schlick(max(dot(N, V), 0.0), F0);
        float fresnel_alpha = clamp(max(max(F.r, F.g), F.b) * 0.35, 0.0, 0.35);
        output_alpha = clamp(max(alpha, fresnel_alpha), 0.0, 0.95);
        color = (ambient + diffuse_lighting) * alpha + specular_lighting + env_specular;
    } else {
        output_alpha = 1.0;
        color = ambient + diffuse_lighting + specular_lighting + env_specular;
    }

    color = color / (color + vec3(1.0));
    color = pow(color, vec3(1.0 / 2.2));

    frag_color = vec4(color, output_alpha);
}
