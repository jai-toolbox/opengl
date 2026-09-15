#version 330 core

out vec4 frag_color;

uniform usampler2D object_id_texture;
uniform uint selected_object_id;
uniform vec4 rgba_color;
// doing anything by px is wrong, because it will look different on screen that have different pixel sizes, for now It'll do.
uniform uint thickness_px = 2u;

void main() {
    ivec2 pixel = ivec2(gl_FragCoord.xy);

    uint center = texelFetch(object_id_texture, pixel, 0).r;

    // don't draw outline on top of the object itself
    if (center == selected_object_id) {
        discard;
    }

    bool neighbor_is_selected = false;

    // given a point, sample all nearby positions except for itself, if any one of those positions
    // yields the selected object, then we can color this pixel, when outline thickness is 2
    // then points that are distance 2 away can find that they are neighbors, that's why this works.

    int t = int(thickness_px);
    for (int x_offset = -t; x_offset <= t; x_offset++) {
        for (int y_offset = -t; y_offset <= t; y_offset++) {

            if (x_offset == 0 && y_offset == 0) continue;
            // x^2 + y^2 > ot^2 means that this pixel is not close enough and we can stop
            if (x_offset * x_offset + y_offset * y_offset >  t * t) continue;

            uint neighbor = texelFetch(object_id_texture, pixel + ivec2(x_offset, y_offset), 0).r;
            if (neighbor == selected_object_id) {
                neighbor_is_selected = true;
                break;
            }
        }
        if (neighbor_is_selected) break;
    }

    if (neighbor_is_selected) {
        frag_color = rgba_color;
    } else {
        discard;
    }
}
