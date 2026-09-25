#version 330 core

uniform samplerCube source_cubemap;
uniform int cube_face;
uniform float roughness;
uniform float mip_size;
uniform float source_resolution;

out vec4 fragment_color;

const float PI = 3.14159265358979323846;
const uint SAMPLE_COUNT = 64u;

// Convert one destination cubemap texel into the world direction represented
// by that texel. This orientation matches the six capture cameras.
vec3 cubemap_direction(vec2 uv, int face) {
    if (face == 0) return vec3( 1.0, -uv.y, -uv.x);
    if (face == 1) return vec3(-1.0, -uv.y,  uv.x);
    if (face == 2) return vec3( uv.x,  1.0,  uv.y);
    if (face == 3) return vec3( uv.x, -1.0, -uv.y);
    if (face == 4) return vec3( uv.x, -uv.y,  1.0);
    return                    vec3(-uv.x, -uv.y, -1.0);
}

float radical_inverse_vdc(uint bits) {
    bits = (bits << 16u) | (bits >> 16u);
    bits = ((bits & 0x55555555u) << 1u)
        | ((bits & 0xAAAAAAAAu) >> 1u);
    bits = ((bits & 0x33333333u) << 2u)
        | ((bits & 0xCCCCCCCCu) >> 2u);
    bits = ((bits & 0x0F0F0F0Fu) << 4u)
        | ((bits & 0xF0F0F0F0u) >> 4u);
    bits = ((bits & 0x00FF00FFu) << 8u)
        | ((bits & 0xFF00FF00u) >> 8u);
    return float(bits) * 2.3283064365386963e-10;
}

vec2 hammersley(uint index) {
    return vec2(
        float(index) / float(SAMPLE_COUNT),
        radical_inverse_vdc(index)
    );
}

float distribution_ggx(float normal_dot_halfway, float alpha_squared) {
    float denominator = normal_dot_halfway * normal_dot_halfway
        * (alpha_squared - 1.0) + 1.0;
    return alpha_squared / max(PI * denominator * denominator, 0.0000001);
}

vec3 importance_sample_ggx(vec2 sample_point, vec3 normal, float material_roughness) {
    float alpha = material_roughness * material_roughness;
    float alpha_squared = alpha * alpha;
    float phi = 2.0 * PI * sample_point.x;
    float cosine_theta = sqrt(
        (1.0 - sample_point.y)
        / (1.0 + (alpha_squared - 1.0) * sample_point.y)
    );
    float sine_theta = sqrt(max(0.0, 1.0 - cosine_theta * cosine_theta));
    vec3 halfway_tangent = vec3(
        cosine_theta == 1.0 ? 0.0 : sine_theta * cos(phi),
        cosine_theta == 1.0 ? 0.0 : sine_theta * sin(phi),
        cosine_theta
    );

    vec3 helper = abs(normal.z) < 0.999
        ? vec3(0.0, 0.0, 1.0)
        : vec3(1.0, 0.0, 0.0);
    vec3 tangent = normalize(cross(helper, normal));
    vec3 bitangent = cross(normal, tangent);
    return normalize(
        tangent * halfway_tangent.x
        + bitangent * halfway_tangent.y
        + normal * halfway_tangent.z
    );
}

void main() {
    vec2 uv = gl_FragCoord.xy / mip_size;
    vec3 normal = normalize(cubemap_direction(uv * 2.0 - 1.0, cube_face));

    // Mip zero is the unblurred captured environment.
    if (roughness <= 0.0001) {
        fragment_color = vec4(
            max(textureLod(source_cubemap, normal, 0.0).rgb, vec3(0.0)),
            1.0
        );
        return;
    }

    vec3 view_direction = normal;
    vec3 filtered = vec3(0.0);
    float total_weight = 0.0;
    float texel_solid_angle = 4.0 * PI
        / (6.0 * source_resolution * source_resolution);
    float alpha = roughness * roughness;
    float alpha_squared = alpha * alpha;

    for (uint sample_index = 0u; sample_index < SAMPLE_COUNT; ++sample_index) {
        vec3 halfway = importance_sample_ggx(
            hammersley(sample_index),
            normal,
            roughness
        );
        vec3 light_direction = normalize(
            2.0 * dot(view_direction, halfway) * halfway - view_direction
        );
        float normal_dot_light = max(dot(normal, light_direction), 0.0);
        if (normal_dot_light <= 0.0) continue;

        float normal_dot_halfway = max(dot(normal, halfway), 0.0);
        float halfway_dot_view = max(dot(halfway, view_direction), 0.0001);
        float density = distribution_ggx(normal_dot_halfway, alpha_squared);
        float probability = max(
            density * normal_dot_halfway / (4.0 * halfway_dot_view),
            0.000001
        );
        float sample_solid_angle = 1.0
            / (float(SAMPLE_COUNT) * probability);
        float source_mip = max(
            0.0,
            0.5 * log2(sample_solid_angle / texel_solid_angle)
        );

        filtered += textureLod(
            source_cubemap,
            light_direction,
            source_mip
        ).rgb * normal_dot_light;
        total_weight += normal_dot_light;
    }

    if (total_weight > 0.0) filtered /= total_weight;
    else filtered = textureLod(source_cubemap, normal, 0.0).rgb;
    fragment_color = vec4(max(filtered, vec3(0.0)), 1.0);
}
