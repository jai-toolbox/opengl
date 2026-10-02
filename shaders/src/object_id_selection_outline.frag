#version 330 core

out vec4 frag_color;

uniform sampler2D selected_depth_texture;
uniform sampler2D scene_depth_texture;
uniform vec4 rgba_color;
uniform float occluded_alpha = 0.32;
/*
three representable steps of a 24-bit depth buffer cover quantization noise
without treating meaningfully separated surfaces as coplanar.
*/
uniform float depth_epsilon = 3.0 / 8388608.0;
// pixel thickness is retained for compatibility with the existing ui setting.
uniform uint thickness_px = 2u;
uniform vec2 viewport_origin;

void main() {
    ivec2 pixel = ivec2(gl_FragCoord.xy - viewport_origin);
    ivec2 texture_size = textureSize(selected_depth_texture, 0);
    float center_depth = texelFetch(selected_depth_texture, pixel, 0).r;

    // draw outside the selected silhouette, not over its surface.
    if (center_depth < 1.0) {
        discard;
    }

    int thickness = int(thickness_px);
    bool found_selected_neighbor = false;
    int closest_distance_squared = thickness * thickness + 1;
    float selected_depth = 1.0;
    ivec2 selected_pixel = pixel;

    for (int x_offset = -thickness; x_offset <= thickness; x_offset++) {
        for (int y_offset = -thickness; y_offset <= thickness; y_offset++) {
            if (x_offset == 0 && y_offset == 0) continue;

            int distance_squared = x_offset * x_offset + y_offset * y_offset;
            if (distance_squared > thickness * thickness ||
                distance_squared >= closest_distance_squared) {
                continue;
            }

            ivec2 neighbor_pixel = pixel + ivec2(x_offset, y_offset);
            if (any(lessThan(neighbor_pixel, ivec2(0))) ||
                any(greaterThanEqual(neighbor_pixel, texture_size))) {
                continue;
            }

            float neighbor_depth = texelFetch(selected_depth_texture, neighbor_pixel, 0).r;
            if (neighbor_depth < 1.0) {
                found_selected_neighbor = true;
                closest_distance_squared = distance_squared;
                selected_depth = neighbor_depth;
                selected_pixel = neighbor_pixel;
            }
        }
    }

    if (!found_selected_neighbor) {
        discard;
    }

    float scene_depth = texelFetch(scene_depth_texture, selected_pixel, 0).r;
    bool occluded = selected_depth > scene_depth + depth_epsilon;
    float alpha = rgba_color.a * (occluded ? occluded_alpha : 1.0);
    frag_color = vec4(rgba_color.rgb, alpha);
}
