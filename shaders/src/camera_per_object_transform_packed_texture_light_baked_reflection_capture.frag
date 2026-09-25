#version 330 core

#include "light_baked_surface.glsl"

out vec4 frag_color;

// This renderer is used only while producing reflection-probe cubemaps. A
// metallic surface normally gets its visible energy by reflecting a completed
// environment, but that environment does not exist while it is being captured.
// The capture shader therefore purposefully brightens metallic surfaces by
// folding part of their broad specular response into a view-independent color.
// The regular camera shader remains physically based and does not apply this.
const float REFLECTION_CAPTURE_SPECULAR_TO_DIFFUSE = 0.45;

void main() {
    LightBakedSurface surface = sample_light_baked_surface();
    if (surface.alpha_mode == ALPHA_MODE_MASK
        && surface.alpha < surface.alpha_cutoff) discard;

    vec3 diffuse_color = surface.base_color * (1.0 - surface.metallic);
    vec3 specular_color = mix(vec3(0.04), surface.base_color, surface.metallic);

    // A reflection capture cannot recursively reflect the cubemap it is
    // currently producing. Represent the broad, fully rough portion of the
    // material's specular response as view-independent energy instead.
    vec3 capture_color = diffuse_color
        + specular_color * REFLECTION_CAPTURE_SPECULAR_TO_DIFFUSE;
    vec3 hdr_lighting = sample_baked_irradiance()
        * capture_color
        * surface.ambient_occlusion
        + surface.emissive;

    // Cubemap faces store linear HDR values. Tone mapping happens when the
    // normal surface shader samples the completed reflection probe.
    frag_color = vec4(max(hdr_lighting, vec3(0.0)), surface.alpha);
}
