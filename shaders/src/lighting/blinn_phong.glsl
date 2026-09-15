vec3 compute_specular_blinn_phong(vec3 light_dir, vec3 view_dir, vec3 normal, float specular_strength, float shininess, vec3 light_color) {
    float ndotl = max(dot(normal, light_dir), 0.0);

    vec3 halfway_dir = normalize(light_dir + view_dir);
    float spec_angle = max(dot(normal, halfway_dir), 0.0);
    float specular_term = pow(spec_angle, shininess);

    // Scale specular by ndotl to fade it as the light moves away from the surface
    return specular_strength * specular_term * ndotl * light_color;
}
