#version 330 core

// Reuse the exact alpha-mask sampling rule from the PBR surface shader. The
// linker removes the material inputs and functions that this pass does not use.
#include "light_baked_surface.glsl"

void main() {
    if (!light_baked_surface_passes_alpha_mask()) discard;
}
