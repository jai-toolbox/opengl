#version 330 core

in vec2 texture_coordinate;
in vec4 rgba_color;

// The MSDF atlas texture: each channel (R, G, B) encodes signed distance
// to a different set of glyph edges. Sampling gives three distances.
uniform sampler2D texture_sampler;

// How many screen pixels the distance field transition spans.
// Computed as: distance_range * (font_size_pixels / atlas_em_size_pixels)
// Controls sharpness: too low = blurry, too high = jagged.
uniform float screen_pixels_per_distance_range;

out vec4 fragment_color;

// MSDF core operation: the median of three channels recovers a single
// signed distance that preserves sharp corners. A single-channel SDF
// would round off corners; using three channels and taking the median
// keeps them intact.
float median_of_three(float channel_r, float channel_g, float channel_b) {
    return max(min(channel_r, channel_g), min(max(channel_r, channel_g), channel_b));
}

void main() {
    vec3 multi_channel_signed_distance = texture(texture_sampler, texture_coordinate).rgb;

    // Collapse three channels into one signed distance via median.
    // Result is 0.5 exactly on the glyph edge,
    // > 0.5 inside the glyph, < 0.5 outside.
    float signed_distance = median_of_three(multi_channel_signed_distance.r, multi_channel_signed_distance.g, multi_channel_signed_distance.b);

    // usually distance is measured from the center of the char, 0 at center and 1 at edge, instead 
    // we center on the edge: negative = outside glyph, positive = inside.
    float distance_from_edge = signed_distance - 0.5;

    // Convert from atlas-space distance to screen pixel distance.
    // This is what makes the anti-aliasing resolution-independent:
    // the same atlas works at any font size because we scale the
    // distance by how many screen pixels the range covers.
    float screen_pixel_distance = screen_pixels_per_distance_range * distance_from_edge;

    // Produce anti-aliased alpha with a 1-pixel-wide linear ramp
    // centered on the glyph edge:
    //   edge fragment (distance = 0)  -> 0.5 (half transparent)
    //   1 pixel inside               -> 1.0 (fully opaque)
    //   1 pixel outside              -> 0.0 (fully transparent)
    float glyph_opacity = clamp(screen_pixel_distance + 0.5, 0.0, 1.0);

    // Final color: text color with alpha modulated by glyph coverage
    fragment_color = vec4(rgba_color.rgb, rgba_color.a * glyph_opacity);
}
