#version 330 core
// Generated from Jai procedure animated_mesh_display.
in vec2 passthrough_uv;
layout(location=0) out vec4 gpu_rendering_pipeline_stage_attachment_color;
uniform sampler2D image;
uniform float exposure;
uniform bool tone_map;

float jai_linear_to_srgb_channel(float linear) {
    float value = max(linear, 0.0);
    if ((value <= 0.0031308)) {
        return (value * 12.92);
    }
    return ((1.055 * pow(value, (1.0 / 2.4))) - 0.055);
}

vec3 jai_linear_to_srgb(vec3 linear) {
    return vec3(jai_linear_to_srgb_channel(linear.x), jai_linear_to_srgb_channel(linear.y), jai_linear_to_srgb_channel(linear.z));
}

void main() {
    vec4 sample = texture(image, passthrough_uv);
    vec3 color = max((vec3(sample.x, sample.y, sample.z) * exp2(exposure)), vec3(0.0, 0.0, 0.0));
    if (tone_map) {
        color = (color / (vec3(1.0, 1.0, 1.0) + color));
    }
    color = jai_linear_to_srgb(color);
    gpu_rendering_pipeline_stage_attachment_color = vec4(color.x, color.y, color.z, 1.0);
}
