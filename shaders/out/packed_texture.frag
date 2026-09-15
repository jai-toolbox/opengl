#version 330 core

// Begin include: packed_texture_input.glsl
in vec2 texture_coordinate;
flat in int packed_texture_index;
flat in int packed_texture_bounding_box_index;
// End include: packed_texture_input.glsl
// Begin include: packed_texture_sampling.glsl
// Resource contract:
// packed_textures is an OpenGL 3.3 bindless-texture workaround. It is a texture
// array whose layers are power-of-two container textures. Each container layer
// may itself hold many smaller source textures packed into rectangular regions.
// The runtime texture packer owns creating and uploading this array.
//
// Geometry does not bind a different texture per object. Instead, vertex
// attributes carry integer indices that select a packed container layer and a
// bounding-box entry. This lets many objects draw together without one draw call
// per texture bind.
uniform sampler2DArray packed_textures;

// the next lines are really bad and cause stuff to break 
// because running out of uniform space, instead 
// use a texture thing: https://stackoverflow.com/questions/51781227/estimate-number-of-registers-required-in-glsl-shader

// packed_texture_bounding_boxes stores vec4 entries in the form:
//   x = top-left u, y = top-left v, z = width, w = height
// Each entry describes the sub-rectangle for one packed source texture inside a
// container layer of packed_textures. Vertex attributes choose which entry to
// use for each object/material channel.
uniform sampler1D packed_texture_bounding_boxes;
//
// note that before we used to do this, but it caused an array about using up too many constant registers
// which come from using too many uniforms, so we no longer do the below, but instead the above.
// 
#define MAX_NUM_TEXTURES 1024
// uniform vec4 packed_texture_bounding_boxes[MAX_NUM_TEXTURES];


vec4 get_bounding_box(int index) {
    // this is the definition of how bounding boxes are stored in textures, as vector4s
    return texture( packed_texture_bounding_boxes, float(index) / float(MAX_NUM_TEXTURES));
}

/*

Wraps a texture coordinate (tc) to stay within the given bounding box. 

We assume that the tc is in the packed texture space (not local uvs)

 */
vec2 wrap_texture_coordinate(vec2 tc, vec4 bbox) {
    float tlx = bbox.x;      // top-left x
    float tly = bbox.y;      // top-left y
    float width = bbox.z;    
    float height = bbox.w;   

    // calculate deltas from the top-left corner
    float dx = tc.x - tlx;
    float dy = tc.y - tly;

    // wrap the coordinates using modulo and shift back into the bounding box
    float wrapped_x = mod(dx, width) + tlx;
    float wrapped_y = mod(dy, height) + tly;

    return vec2(wrapped_x, wrapped_y);
}

/**
 * @brief Samples from a 2D texture array.
 * 
 * @param texture_array The sampler2DArray containing the packed textures.
 * @param tex_coord The 2D texture coordinates for sampling.
 * @param texture_index The index of the texture in the array.
 * @param bounding_boxes The array of bounding boxes for the textures.
 * @param bounding_box_index The index of the bounding box for the current texture.
 * @return vec4 The sampled color from the texture.
 */
vec4 sample_packed_texture(
    sampler2DArray texture_array,
    vec2 tex_coord,
    int texture_index,
    int bounding_box_index
) {
    vec4 bbox = get_bounding_box(bounding_box_index);
    return texture(texture_array, vec3(wrap_texture_coordinate(tex_coord, bbox), texture_index));
}
// End include: packed_texture_sampling.glsl

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
