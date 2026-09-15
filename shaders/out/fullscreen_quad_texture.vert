#version 330 core

// This shader has no vertex inputs. The fullscreen quad geometry is
// stored entirely as constants. We use gl_VertexID to index into
// the vertex/index arrays, so you just need to issue a draw call
// with 6 vertices and an empty VAO bound.

out vec2 texture_coordinate;

const vec2 quad_positions[4] = vec2[4](
    vec2(-1.0, -1.0),    // bottom left
    vec2( 1.0, -1.0),    // bottom right
    vec2( 1.0,  1.0),    // top right
    vec2(-1.0,  1.0)     // top left
);

const int quad_indices[6] = int[6](0, 2, 1, 2, 0, 3);

void main() {
    int index = quad_indices[gl_VertexID];
    vec2 pos = quad_positions[index];

    gl_Position = vec4(pos, 0.0, 1.0);

    // map from clip space [-1, 1] to texture space [0, 1]
    texture_coordinate = pos * 0.5 + 0.5;
}
