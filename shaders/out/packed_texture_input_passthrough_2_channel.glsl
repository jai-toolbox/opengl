// I guess in the future we could do an array, but I'm just being explicit and boring until I see this working.
// for 4 or 8 channel I'll definitely move to that approach

// Resource contract:
// Each channel has its own packed texture layer index, uv coordinate, and
// bounding-box metadata index. The packed texture indices select layers in the
// packed_textures sampler2DArray; the bounding-box indices select source
// texture rectangles in packed_texture_bounding_boxes. These resource indices
// are constant across an object/material channel so a renderer can draw many
// textured objects without rebinding one texture per object.

in int passthrough_packed_texture_index_0; // @constant_across_object
in vec2 passthrough_texture_coordinate_0;
in int passthrough_packed_texture_bounding_box_index_0; // @constant_across_object

in int passthrough_packed_texture_index_1; // @constant_across_object
in vec2 passthrough_texture_coordinate_1;
in int passthrough_packed_texture_bounding_box_index_1; // @constant_across_object

out vec2 texture_coordinate_0;
// flat means that the rasterizer will not interpolate this
flat out int packed_texture_index_0;
flat out int packed_texture_bounding_box_index_0;

out vec2 texture_coordinate_1;
// flat means that the rasterizer will not interpolate this
flat out int packed_texture_index_1;
flat out int packed_texture_bounding_box_index_1;

void packed_texture_passthrough(

        in vec2 passthrough_texture_coordinate_0, 
        in int passthrough_packed_texture_index_0, 
        in int passthrough_packed_texture_bounding_box_index_0, 

        out vec2 texture_coordinate_0, 
        out int packed_texture_index_0, 
        out int packed_texture_bounding_box_index_0,

        in vec2 passthrough_texture_coordinate_1, 
        in int passthrough_packed_texture_index_1, 
        in int passthrough_packed_texture_bounding_box_index_1, 

        out vec2 texture_coordinate_1, 
        out int packed_texture_index_1, 
        out int packed_texture_bounding_box_index_1


    ) {

    texture_coordinate_0 = passthrough_texture_coordinate_0;
    packed_texture_index_0 = passthrough_packed_texture_index_0;
    packed_texture_bounding_box_index_0 = passthrough_packed_texture_bounding_box_index_0;

    texture_coordinate_1 = passthrough_texture_coordinate_1;
    packed_texture_index_1 = passthrough_packed_texture_index_1;
    packed_texture_bounding_box_index_1 = passthrough_packed_texture_bounding_box_index_1;

}
