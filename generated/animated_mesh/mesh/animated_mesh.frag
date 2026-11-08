#version 330 core
// Generated from Jai procedure animated_mesh_fragment.
struct Surface_Shader {
    vec3 radiance;
    vec3 transmittance;
};
in vec3 passthrough_position_in_world;
in vec3 passthrough_normal;
in vec2 passthrough_uv;
in float passthrough_spacing;
layout(location=0) out vec4 gpu_rendering_pipeline_stage_attachment_color;
uniform sampler2D image;
uniform vec2 first_offset;
uniform vec2 second_offset;
uniform float frame_mix;
uniform vec3 eye;
uniform vec3 direction;
uniform bool orthographic;
uniform bool volume;
uniform bool blend_axis_stacks;
uniform float emission;

float jai_volume_slice_distance(float spacing, float normal_dot_view, bool blend_axis_stacks) {
    float cosine = abs(normal_dot_view);
    float weight = 1.0;
    if (blend_axis_stacks) {
        weight = (cosine * cosine);
    }
    return ((spacing * weight) / max(cosine, 0.05));
}

Surface_Shader jai_surface_from_cache(vec4 value) {
    float transmission = (1.0 - value.w);
    return Surface_Shader(vec3(value.x, value.y, value.z), vec3(transmission, transmission, transmission));
}

float jai_surface_opacity(Surface_Shader surface) {
    float opacity = (1.0 - (((surface.transmittance.x + surface.transmittance.y) + surface.transmittance.z) / 3.0));
    return opacity;
}

vec4 jai_surface_to_volume_premultiplied_rgba(Surface_Shader surface, float distance) {
    if ((distance <= 0.0)) {
        return vec4(0.0, 0.0, 0.0, 0.0);
    }
    float opacity = clamp(jai_surface_opacity(surface), 0.0, 1.0);
    float integrated = (1.0 - pow((1.0 - opacity), distance));
    float scale = distance;
    if ((opacity > 0.000001)) {
        scale = (integrated / opacity);
    }
    return vec4((surface.radiance.x * scale), (surface.radiance.y * scale), (surface.radiance.z * scale), integrated);
}

void main() {
    vec4 first = texture(image, (passthrough_uv + first_offset));
    vec4 second = texture(image, (passthrough_uv + second_offset));
    vec4 color = mix(first, second, frame_mix);
    if (volume) {
        vec3 view = direction;
        if (!(orthographic)) {
            view = normalize((eye - passthrough_position_in_world));
        }
        float facing = dot(normalize(passthrough_normal), view);
        float distance = jai_volume_slice_distance(passthrough_spacing, facing, blend_axis_stacks);
        Surface_Shader surface = jai_surface_from_cache(color);
        color = jai_surface_to_volume_premultiplied_rgba(surface, distance);
    }
    gpu_rendering_pipeline_stage_attachment_color = vec4((color.x * emission), (color.y * emission), (color.z * emission), color.w);
}
