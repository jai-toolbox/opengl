vec3 pbr_light_contribution_shape(vec3 n, vec3 v, vec3 l, vec3 radiance, vec3 base_color, float metallic, float roughness, vec3 f0) {
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
