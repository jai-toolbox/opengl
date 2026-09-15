#version 330 core

#include "packed_texture_input.glsl";
#include "packed_texture_sampling.glsl"

out vec4 frag_color;

void main() {
    frag_color = sample_packed_texture(
        packed_textures, 
        texture_coordinate, 
        packed_texture_index, 
        // packed_texture_bounding_boxes, 
        packed_texture_bounding_box_index
    );
}
