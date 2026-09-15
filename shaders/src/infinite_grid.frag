#version 330

in vec3 grid_world_position;

out vec4 frag_color;

uniform vec3 camera_position;

// not sure if it's even worth while to make the rest uniforms because
// who is tweaking the grid in realtime? but I'll wait till I know for sure.

uniform float grid_size = 100.0; // matches the one in the vertex shader
uniform float min_pixels_between_cells = 2.0;
uniform float grid_cell_size = 0.05;
uniform vec4 grid_color_thick = vec4(0.5, 0.5, 0.5, 1.0);
uniform vec4 grid_color_thin = vec4(0.0, 0.0, 0.0, 1.0);

// 0 = XZ (horizontal, Y=0), 1 = XY (vertical, Z=0), 2 = YZ (vertical, X=0)
// Must match the vertex shader
uniform int grid_plane = 0;

float log10(float x) {
    return log(x) / log(10.0);
}

// Clamps a value to [0, 1], equivalent to HLSL's saturate()
float saturate(float x) {
    return clamp(x, 0.0, 1.0);
}

vec2 saturate(vec2 x) {
    return clamp(x, vec2(0.0), vec2(1.0));
}

float max_component(vec2 v) {
    return max(v.x, v.y);
}

void main() {

    // Compute screen-space derivatives of the world position BEFORE
    // any branching. dFdx/dFdy must be called on values that aren't
    // selected through dynamic branches, otherwise some drivers
    // return zero for one or more components.

    vec3 ddx = dFdx(grid_world_position);
    vec3 ddy = dFdy(grid_world_position);

    // Select the two world-space coordinates that lie in the grid plane,
    // and the corresponding camera coordinates for the distance falloff.
    // Also pick the matching derivative components.

    vec2 grid_uv;
    vec2 camera_uv;
    vec2 ddx_uv;
    vec2 ddy_uv;

    if (grid_plane == 0) {
        // XZ plane
        grid_uv = grid_world_position.xz;
        camera_uv = camera_position.xz;
        ddx_uv = ddx.xz;
        ddy_uv = ddy.xz;
    } else if (grid_plane == 1) {
        // XY plane
        grid_uv = grid_world_position.xy;
        camera_uv = camera_position.xy;
        ddx_uv = ddx.xy;
        ddy_uv = ddy.xy;
    } else {
        // YZ plane
        grid_uv = grid_world_position.yz;
        camera_uv = camera_position.yz;
        ddx_uv = ddx.yz;
        ddy_uv = ddy.yz;
    }

    // Compute screen-space derivatives of the world position.
    // This tells us how much the world position changes per pixel
    // in screen space essentially the "size" of one pixel in
    // world units. We only care about the two axes that form the
    // grid plane.

    vec2 dv_u = vec2(ddx_uv.x, ddy_uv.x);
    vec2 dv_v = vec2(ddx_uv.y, ddy_uv.y);

    float len_u = length(dv_u);
    float len_v = length(dv_v);

    vec2 du_dv = vec2(len_u, len_v);

    // Determine the Level of Detail (LOD).
    // As the camera moves further away, each pixel covers more world
    // space, so we need coarser grid lines. LOD is computed based on
    // how many screen pixels fit between the smallest grid cells.
    // Each LOD level is 10x larger than the previous (powers of 10).

    float derivative_length = length(du_dv);

    float lod = max(0.0, log10(derivative_length * min_pixels_between_cells / grid_cell_size) + 1.0);

    // Three nested LOD levels, each 10x the size of the previous
    float cell_size_lod0 = grid_cell_size * pow(10.0, floor(lod));
    float cell_size_lod1 = cell_size_lod0 * 10.0;  // 10x coarser
    float cell_size_lod2 = cell_size_lod1 * 10.0;   // 100x coarser

    // Compute grid line anti-aliased coverage for each LOD level.
    // For each LOD, we use mod() to find the distance to the nearest
    // grid line, then divide by the screen-space derivatives (du_dv)
    // to convert to pixel units. The saturate → *2 - 1 → abs → 1-
    // sequence creates a smooth "pulse" that is 1 on a grid line
    // and falls to 0 between them a cheap form of anti-aliasing.
    // The *4 on du_dv controls the anti-aliasing filter width.

    du_dv *= 4.0;

    vec2 mod_div_dudv = mod(grid_uv, cell_size_lod0) / du_dv;
    float lod_0_alpha = max_component(vec2(1.0) - abs(saturate(mod_div_dudv) * 2.0 - vec2(1.0)));

    mod_div_dudv = mod(grid_uv, cell_size_lod1) / du_dv;
    float lod_1_alpha = max_component(vec2(1.0) - abs(saturate(mod_div_dudv) * 2.0 - vec2(1.0)));

    mod_div_dudv = mod(grid_uv, cell_size_lod2) / du_dv;
    float lod_2_alpha = max_component(vec2(1.0) - abs(saturate(mod_div_dudv) * 2.0 - vec2(1.0)));

    // Blend between LOD levels.
    // - The coarsest visible lines (lod2) are always drawn as thick.
    // - Mid-level lines (lod1) blend between thick and thin based
    //   on the fractional part of the LOD (smooth transition).
    // - The finest lines (lod0) are drawn thin and fade out as
    //   the LOD transitions to the next level.

    float lod_fade = fract(lod);
    vec4 color;

    if (lod_2_alpha > 0.0) {
        color = grid_color_thick;
        color.a *= lod_2_alpha;
    } else {
        if (lod_1_alpha > 0.0) {
            color = mix(grid_color_thick, grid_color_thin, lod_fade);
            color.a *= lod_1_alpha;
        } else {
            color = grid_color_thin;
            color.a *= (lod_0_alpha * (1.0 - lod_fade));
        }
    }

    // Distance-based opacity falloff.
    // The grid fades to transparent at the edges (grid_size radius)
    // to avoid a harsh cutoff at the boundary of the grid plane.

    float opacity_falloff = 1.0 - saturate(length(grid_uv - camera_uv) / grid_size);

    color.a *= opacity_falloff;

    frag_color = color;
}
