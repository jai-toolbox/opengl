#version 330 core

#include "packed_texture_2_channel_input.glsl"
#include "packed_texture_sampling.glsl"

out vec4 frag_color;

void main() {
    vec4 channel_0_color = sample_packed_texture(
        packed_textures, 
        texture_coordinate_0, 
        packed_texture_index_0, 
        packed_texture_bounding_box_index_0
    );

    vec4 channel_1_color = sample_packed_texture(
        packed_textures, 
        texture_coordinate_1, 
        packed_texture_index_1, 
        packed_texture_bounding_box_index_1
    );

    frag_color = vec4(channel_0_color.rgb * channel_1_color.rgb, channel_0_color.a);
}
