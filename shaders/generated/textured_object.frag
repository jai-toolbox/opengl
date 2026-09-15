#version 330 core

// Resource contract:
// packed_textures is an OpenGL 3.3 bindless-texture workaround. It is a texture
// array whose layers are power-of-two container textures. Each layer may hold
// many smaller source textures packed into rectangular regions. The runtime
// texture packer owns creating and uploading this array.
uniform sampler2DArray packed_textures;

// packed_texture_bounding_boxes stores vec4 entries:
//   x = top-left u, y = top-left v, z = width, w = height
// Vertex attributes select which bounding-box entry to use for each object.
uniform sampler1D packed_texture_bounding_boxes;

in vec2 texture_coordinate;
flat in int packed_texture_index;
flat in int packed_texture_bounding_box_index;

in vec3 world_normal;

out vec4 frag_color;

vec4 get_bounding_box(int index) {
    return texture(packed_texture_bounding_boxes, float(index) / 1024.0);
}

vec2 wrap_texture_coordinate(vec2 tc, vec4 bbox) {
    float tlx = bbox.x;
    float tly = bbox.y;
    float width = bbox.z;
    float height = bbox.w;
    return vec2(mod(tc.x - tlx, width) + tlx, mod(tc.y - tly, height) + tly);
}

vec4 sample_packed_texture(sampler2DArray texture_array, vec2 tex_coord, int texture_index, int bounding_box_index) {
    vec4 bbox = get_bounding_box(bounding_box_index);
    return texture(texture_array, vec3(wrap_texture_coordinate(tex_coord, bbox), texture_index));
}

void main() {
    vec4 base_color = sample_packed_texture(
        packed_textures,
        texture_coordinate,
        packed_texture_index,
        packed_texture_bounding_box_index
    );

    vec3 n = normalize(world_normal);
    vec3 l = normalize(vec3(0.45, 0.70, -0.55));
    float diffuse = max(0.0, dot(n, l));
    float intensity = clamp(0.22 + diffuse * 0.78, 0.0, 1.0);
    frag_color = vec4(base_color.rgb * intensity, base_color.a);
}
