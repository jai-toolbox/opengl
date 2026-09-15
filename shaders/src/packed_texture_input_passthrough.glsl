// Resource contract:
// These attributes identify which packed texture rectangle this object's
// vertices should sample. passthrough_packed_texture_index selects the
// sampler2DArray layer. passthrough_packed_texture_bounding_box_index selects
// the packed sub-rectangle metadata stored in packed_texture_bounding_boxes.
// Both are marked constant across an object because they are material/resource
// IDs, not per-corner interpolated data.
in int passthrough_packed_texture_index; // @constant_across_object
in vec2 passthrough_texture_coordinate;
in int passthrough_packed_texture_bounding_box_index; // @constant_across_object

out vec2 texture_coordinate;
// flat means that the rasterizer will not interpolate this
flat out int packed_texture_index;
flat out int packed_texture_bounding_box_index;


// todo rename this to packed_texture_passhtrough later
// call the function like this: 
// texture_packer_passthrough(passthrough_texture_coordinate, passthrough_packed_texture_index, passthrough_packed_texture_bounding_box_index, texture_coordinate, packed_texture_index, packed_texture_bounding_box_index)
void texture_packer_passthrough(in vec2 passthrough_texture_coordinate, in int passthrough_packed_texture_index, in int passthrough_packed_texture_bounding_box_index, out vec2 texture_coordinate, out int packed_texture_index, out int packed_texture_bounding_box_index) {
    texture_coordinate = passthrough_texture_coordinate;
    packed_texture_index = passthrough_packed_texture_index;
    packed_texture_bounding_box_index = passthrough_packed_texture_bounding_box_index;
}
