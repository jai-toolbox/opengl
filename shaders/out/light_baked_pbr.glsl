#define MAX_STATIC_POINT_LIGHTS 16
#define MAX_DYNAMIC_POINT_LIGHTS 16
#define MAX_REFLECTION_PROBES 64

#extension GL_ARB_texture_cube_map_array : require

struct PointLight {
    vec3 position;
    vec3 color;
    float intensity;
    float range;
};

struct ReflectionProbe {
    vec3 position;
    float influence_radius;
    float average_brightness;
};

uniform PointLight static_point_lights[MAX_STATIC_POINT_LIGHTS];
uniform int static_point_light_count;
uniform int can_static_point_light_reach_surface_group_indices[MAX_STATIC_POINT_LIGHTS / 4];
uniform bool use_can_static_point_light_reach_surface_texture;
uniform sampler2DArray can_static_point_light_reach_surface_textures;
uniform int can_static_point_light_reach_surface_rgba_group_count;
uniform PointLight dynamic_point_lights[MAX_DYNAMIC_POINT_LIGHTS];
uniform int dynamic_point_light_count;

uniform samplerCubeArray reflection_probe_cubemaps;
uniform ReflectionProbe reflection_probes[MAX_REFLECTION_PROBES];
uniform int reflection_probe_count;
uniform float reflection_probe_max_mip;

uniform vec3 camera_position;

const float PI = 3.14159265359;

vec4 sample_can_static_point_lights_reach_surface(int group_index) {
    int texture_layer = int(lightmap_atlas_index)
        * can_static_point_light_reach_surface_rgba_group_count
        + group_index;
    return texture(
        can_static_point_light_reach_surface_textures,
        vec3(lightmap_texture_coordinate, float(texture_layer)));
}

vec3 linear_to_srgb(vec3 value) {
    value = max(value, vec3(0.0));
    vec3 lower = value * 12.92;
    vec3 upper = 1.055 * pow(value, vec3(1.0 / 2.4)) - 0.055;
    return mix(upper, lower, lessThanEqual(value, vec3(0.0031308)));
}

float distribution_ggx(
    float normal_dot_halfway,
    float alpha_squared
) {
    float denominator = normal_dot_halfway * normal_dot_halfway
        * (alpha_squared - 1.0) + 1.0;
    return alpha_squared / max(PI * denominator * denominator, 0.0000001);
}

float geometry_schlick_ggx(float normal_dot_direction, float k) {
    return normal_dot_direction
        / max(normal_dot_direction * (1.0 - k) + k, 0.0001);
}

vec3 fresnel_schlick(float cosine, vec3 f0) {
    float one_minus_cosine = clamp(1.0 - cosine, 0.0, 1.0);
    float one_minus_cosine_squared = one_minus_cosine * one_minus_cosine;
    float one_minus_cosine_fifth = one_minus_cosine_squared
        * one_minus_cosine_squared * one_minus_cosine;
    return f0 + (vec3(1.0) - f0) * one_minus_cosine_fifth;
}

vec3 normal_from_material_texture(vec3 sampled_normal) {
    vec3 normal = normalize(world_normal);
    vec3 tangent = normalize(
        world_tangent.xyz - normal * dot(normal, world_tangent.xyz)
    );
    vec3 bitangent = normalize(cross(normal, tangent)) * world_tangent.w;
    vec3 tangent_normal = sampled_normal * 2.0 - 1.0;
    tangent_normal.xy *= material_parameters.z;
    return normalize(mat3(tangent, bitangent, normal) * tangent_normal);
}

vec3 point_light_specular(
    PointLight light,
    float light_reaches_surface_factor,
    vec3 normal,
    vec3 view_direction,
    vec3 f0,
    float normal_dot_view,
    float alpha_squared,
    float geometry_k,
    float geometry_view
) {
    vec3 to_light = light.position - world_position;
    float distance_squared = dot(to_light, to_light);
    if (distance_squared <= 0.00000001) return vec3(0.0);

    float range_squared = light.range * light.range;
    if (distance_squared >= range_squared) return vec3(0.0);

    vec3 light_direction = to_light * inversesqrt(distance_squared);
    float normal_dot_light = max(dot(normal, light_direction), 0.0);
    if (normal_dot_light <= 0.0) return vec3(0.0);

    float normalized_distance_squared = distance_squared / range_squared;
    float range_fade = 1.0
        - normalized_distance_squared * normalized_distance_squared;
    range_fade *= range_fade;
    vec3 radiance = light.color * light.intensity
        * range_fade / (distance_squared + 0.0001);

    float view_dot_light = dot(view_direction, light_direction);
    float inverse_halfway_length = inversesqrt(
        max(2.0 + 2.0 * view_dot_light, 0.00000001));
    float normal_dot_halfway = max(
        (normal_dot_view + normal_dot_light) * inverse_halfway_length,
        0.0);
    float halfway_dot_view = max(
        (1.0 + view_dot_light) * inverse_halfway_length,
        0.0);
    float distribution = distribution_ggx(
        normal_dot_halfway, alpha_squared);
    float geometry = geometry_view
        * geometry_schlick_ggx(normal_dot_light, geometry_k);
    vec3 fresnel = fresnel_schlick(
        halfway_dot_view,
        f0
    );
    float denominator = 4.0
        * normal_dot_view * normal_dot_light
        + 0.0001;
    return distribution * geometry * fresnel
        / denominator * radiance * normal_dot_light * light_reaches_surface_factor;
}

vec3 dynamic_point_light_direct(
    PointLight light,
    vec3 normal,
    vec3 view_direction,
    vec3 base_color,
    float metallic,
    vec3 f0,
    float normal_dot_view,
    float alpha_squared,
    float geometry_k,
    float geometry_view
) {
    vec3 to_light = light.position - world_position;
    float distance_squared = dot(to_light, to_light);
    if (distance_squared <= 0.00000001) return vec3(0.0);
    float range_squared = light.range * light.range;
    if (distance_squared >= range_squared) return vec3(0.0);

    vec3 light_direction = to_light * inversesqrt(distance_squared);
    float normal_dot_light = max(dot(normal, light_direction), 0.0);
    if (normal_dot_light <= 0.0) return vec3(0.0);

    float normalized_distance_squared = distance_squared / range_squared;
    float range_fade = 1.0
        - normalized_distance_squared * normalized_distance_squared;
    range_fade *= range_fade;
    vec3 radiance = light.color * light.intensity
        * range_fade / (distance_squared + 0.0001);

    float view_dot_light = dot(view_direction, light_direction);
    float inverse_halfway_length = inversesqrt(
        max(2.0 + 2.0 * view_dot_light, 0.00000001));
    float normal_dot_halfway = max(
        (normal_dot_view + normal_dot_light) * inverse_halfway_length,
        0.0);
    float halfway_dot_view = max(
        (1.0 + view_dot_light) * inverse_halfway_length,
        0.0);
    vec3 fresnel = fresnel_schlick(
        halfway_dot_view, f0);
    vec3 diffuse_brdf = (vec3(1.0) - fresnel)
        * (1.0 - metallic) * base_color / PI;
    float distribution = distribution_ggx(
        normal_dot_halfway, alpha_squared);
    float geometry = geometry_view
        * geometry_schlick_ggx(normal_dot_light, geometry_k);
    float denominator = 4.0
        * normal_dot_view * normal_dot_light + 0.0001;
    vec3 specular_brdf = distribution * geometry * fresnel / denominator;
    return (diffuse_brdf + specular_brdf) * radiance * normal_dot_light;
}

vec3 sample_reflection_probe(int probe_index, vec3 direction, float mip) {
    return textureLod(
        reflection_probe_cubemaps,
        vec4(direction, float(probe_index)),
        mip
    ).rgb;
}

vec3 environment_brdf_approximation(
    vec3 f0,
    float roughness,
    float normal_dot_view
) {
    vec4 c0 = vec4(-1.0, -0.0275, -0.572, 0.022);
    vec4 c1 = vec4(1.0, 0.0425, 1.04, -0.04);
    vec4 r = roughness * c0 + c1;
    float a004 = min(r.x * r.x, exp2(-9.28 * normal_dot_view))
        * r.x + r.y;
    vec2 ab = vec2(-1.04, 1.04) * a004 + r.zw;
    float f90 = clamp(50.0 * f0.g, 0.0, 1.0);
    return f0 * ab.x + f90 * ab.y;
}

vec3 reflection_probe_specular(
    vec3 normal,
    vec3 view_direction,
    vec3 f0,
    float roughness,
    float ambient_occlusion,
    vec3 indirect_irradiance
) {
    if (reflection_probe_count <= 0) return vec3(0.0);

    float alpha = roughness * roughness;
    vec3 reflected = reflect(-view_direction, normal);
    vec3 reflection_direction = mix(
        normal,
        reflected,
        (1.0 - alpha) * (sqrt(1.0 - alpha) + alpha)
    );
    float level_from_one_by_one = 1.0
        - 1.2 * log2(max(roughness, 0.001));
    float mip = clamp(
        reflection_probe_max_mip - 1.0 - level_from_one_by_one,
        0.0,
        reflection_probe_max_mip
    );
    vec3 weighted_reflection_sum = vec3(0.0);
    float weighted_average_brightness_sum = 0.0;
    float total_probe_weight = 0.0;
    float reflection_coverage = 0.0;
    float normal_dot_view = max(dot(normal, view_direction), 0.001);
    float specular_occlusion = clamp(
        pow(normal_dot_view + ambient_occlusion, alpha)
            - 1.0 + ambient_occlusion,
        0.0,
        1.0
    );

    for (int probe_index = 0; probe_index < MAX_REFLECTION_PROBES; ++probe_index) {
        if (probe_index >= reflection_probe_count) break;
        ReflectionProbe probe = reflection_probes[probe_index];
        vec3 local_position = world_position - probe.position;
        float normalized_distance = length(local_position)
            / max(probe.influence_radius, 0.0001);
        if (normalized_distance >= 1.0) continue;

        // distance weighting has no full-weight plateau. Raising proximity
        // to the fourth power makes the closest probe dominate while keeping
        // the result continuous as the dominant probe changes.
        float proximity = max(1.0 - normalized_distance, 0.0);
        float proximity_squared = proximity * proximity;
        float distance_weight = proximity_squared * proximity_squared;

        // coverage is separate from blending so a small normalized weight does
        // not darken reflections. It only fades across the outer 10% of a
        // probe's influence volume when no neighboring probe covers the point.
        float coverage = 1.0 - smoothstep(
            0.9,
            1.0,
            normalized_distance
        );

        // intersect the reflected ray with the probe's influence sphere. The
        // vector from the capture position to that hit point is the cubemap
        // lookup direction, which keeps reflected features anchored in space.
        float ray_projection = dot(reflection_direction, local_position);
        float sphere_term = dot(local_position, local_position)
            - probe.influence_radius * probe.influence_radius;
        float determinant = ray_projection * ray_projection - sphere_term;
        if (determinant < 0.0) continue;
        float hit_distance = sqrt(determinant) - ray_projection;
        vec3 projected_direction = local_position
            + hit_distance * reflection_direction;

        weighted_reflection_sum += sample_reflection_probe(
            probe_index,
            projected_direction,
            mip
        ) * distance_weight;
        weighted_average_brightness_sum += probe.average_brightness
            * distance_weight;
        total_probe_weight += distance_weight;
        reflection_coverage = max(reflection_coverage, coverage);
    }

    if (total_probe_weight <= 0.000000000001) return vec3(0.0);

    // dividing by the shared sum makes the result independent of probe loop
    // order while retaining the relative distance preference.
    vec3 accumulated = weighted_reflection_sum
        / total_probe_weight
        * reflection_coverage
        * specular_occlusion;
    float composited_average_brightness =
        weighted_average_brightness_sum
        / total_probe_weight
        * reflection_coverage;

    float indirect_luminance = dot(
        max(indirect_irradiance, vec3(0.0)),
        vec3(0.2126, 0.7152, 0.0722)
    );
    float mixing_alpha = smoothstep(
        0.0,
        1.0,
        clamp(roughness * 5.0 - 0.5, 0.0, 1.0)
    );
    float mixing_weight = min(
        indirect_luminance / max(composited_average_brightness, 0.0001),
        10000.0
    );
    accumulated *= mix(1.0, mixing_weight, mixing_alpha);

    return accumulated
        * environment_brdf_approximation(f0, roughness, normal_dot_view);
}
