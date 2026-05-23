#import "String";
#import "File";
#import "tbx/section_logger";

Shader_Metadata :: struct { // call this Shader_Metadata?

    name : string;

    // we use array views here because if we use dynamic arrays then 
    // we cannot fill them in at compile time, this makes them act like string literals in that way.
    attributes : [] GL_Shader_Vertex_Attribute_Variable;
    uniforms   : [] GL_Shader_Uniform_Variable;

    per_object_transforms : bool;

    num_elements_in_each_buffer : u32;


    /*
     By default our shaders are in "retained mode", this is when you submit geometry to the GPU 
     and then we have a handle to that geometry. When we want to draw it, we use the handle to do so.
     The geometry persists on the GPU across frames until explicitly removed.

     On the other hand there is value to being able to render things on a per-frame basis without 
     the overhead of managing handles and GPU-side allocations. This is "immediate mode" geometry 
     is uploaded and drawn in one shot, with no expectation that it persists beyond the current frame.
     This is useful for debug visualization, gizmos, overlays, or any transient geometry that changes 
     every frame and would otherwise require constant re-buffering through the retained path.

     When immediate_mode_support is true, the renderer will allocate a separate set of GL buffers 
     dedicated to immediate draws, so that immediate and retained rendering can be freely interleaved 
     without interfering with each other.
    */
    immediate_mode_support : bool = false;
    num_elements_in_each_immediate_buffer: u32 = 4096;

    vertex_shader_path   : string;
    fragment_shader_path : string;


    primitive_mode : GLenum = GL_TRIANGLES;

}

gl_primitive_mode_to_string :: (mode: GLenum) -> string {
    if mode == {
        case GL_TRIANGLES;      return "GL_TRIANGLES";
        case GL_LINES;          return "GL_LINES";
        case GL_LINE_STRIP;     return "GL_LINE_STRIP";
        case GL_LINE_LOOP;      return "GL_LINE_LOOP";
        case GL_POINTS;         return "GL_POINTS";
        case GL_TRIANGLE_STRIP; return "GL_TRIANGLE_STRIP";
        case GL_TRIANGLE_FAN;   return "GL_TRIANGLE_FAN";
        case GL_PATCHES;        return "GL_PATCHES";
        case;                   return "GL_TRIANGLES"; // fallback
    }
}


/*

This shader is really good to get your orientation right in a very sparse scene. 
Additionally it can be used for debugging things in terms of how big you expect something to be.

*/
CAMERA_INFINITE_GRID_SHADER :: Shader_Metadata.{
    name = "Camera_Infinite_Grid", 
    attributes = .[], // doesn't need any vertices, it stores them internally in the shader
    uniforms = .[.CAMERA_TO_CLIP, .WORLD_TO_CAMERA, .CAMERA_POSITION, .GRID_SIZE, .GRID_PLANE],
    per_object_transforms = false,
    immediate_mode_support = false,
    num_elements_in_each_buffer = 6, // lol, cause we only do one quad
    vertex_shader_path = "data/shaders/out/infinite_grid.vert",
    fragment_shader_path = "data/shaders/out/infinite_grid.frag"
};

/*

Used for rendering 3d objects with points instead of triangles or lines, useful for modelling applications.
Also you can specify color on the vertices so you can do things like selecting verts and see that visually.

*/
CAMERA_PER_OBJECT_TRANSFORM_POSITION_POINT_COLOR :: Shader_Metadata.{
    name = "Camera_Per_Object_Transform_Position_Point_Color", 
    attributes = .[.POSITION, .PASSTHROUGH_RGB_COLOR],
    uniforms = .[.CAMERA_TO_CLIP, .WORLD_TO_CAMERA, .POINT_SIZE],
    per_object_transforms = true,
    num_elements_in_each_buffer = 100000,
    vertex_shader_path = "data/shaders/out/camera_per_object_transform_position_point_color.vert",
    fragment_shader_path = "data/shaders/out/position_point_color.frag",
    primitive_mode = GL_POINTS
};

/*

note: if you render points with this it will not match the points rendered using the above, the reason is that 
the above shader turns them into circles, those circles are small and the picking probably just picks the closest one anyway*
so I decided that the square descrepancy doesn't really bother me that much until someone complains about it.

*/
CAMERA_PER_OBJECT_TRANSFORM_OBJECT_ID :: Shader_Metadata.{
    name = "Camera_Per_Object_Transform_Object_Id", 
    attributes = .[.POSITION, .PASSTHROUGH_OBJECT_ID],
    uniforms = .[.CAMERA_TO_CLIP, .WORLD_TO_CAMERA, .POINT_SIZE],
    per_object_transforms = true,
    num_elements_in_each_buffer = 100000,
    vertex_shader_path = "data/shaders/out/camera_per_object_transform_object_id.vert",
    fragment_shader_path = "data/shaders/out/object_id.frag",
};

/*

This shader is also very simple, good for rendering solid color hud elements and things that don't move.

*/
ABSOLUTE_POSITION_COLOR_SHADER :: Shader_Metadata.{
    name = "Absolute_Position_Color", 
    attributes = .[.POSITION, .PASSTHROUGH_RGB_COLOR],
    uniforms = .[.ASPECT_RATIO],
    per_object_transforms = false,
    immediate_mode_support = true,
    num_elements_in_each_buffer = 100000,
    vertex_shader_path = "data/shaders/out/absolute_position_color.vert",
    fragment_shader_path = "data/shaders/out/color.frag"
};

ABSOLUTE_POSITION_COLOR_ALPHA :: Shader_Metadata.{
    name = "Absolute_Position_Color_Alpha", 
    attributes = .[.POSITION, .PASSTHROUGH_RGBA_COLOR],
    uniforms = .[.ASPECT_RATIO],
    per_object_transforms = false,
    immediate_mode_support = true,
    num_elements_in_each_buffer = 100000,
    vertex_shader_path = "data/shaders/out/absolute_position_color_alpha.vert",
    fragment_shader_path = "data/shaders/out/color_alpha.frag"
};

/*

*/
CAMERA_ABSOLUTE_POSITION_COLOR :: Shader_Metadata.{
    name = "Camera_Absolute_Position_Color", 
    attributes = .[.POSITION, .PASSTHROUGH_RGB_COLOR],
    uniforms = .[.CAMERA_TO_CLIP, .WORLD_TO_CAMERA],
    per_object_transforms = false,
    num_elements_in_each_buffer = 100000,
    vertex_shader_path = "data/shaders/out/camera_absolute_position_color.vert",
    fragment_shader_path = "data/shaders/out/color.frag"
};

TRANSFORM_POSITION_COLOR_ALPHA :: Shader_Metadata.{
    name = "Transform_Position_Color_Alpha",
    attributes = .[.POSITION, .PASSTHROUGH_RGBA_COLOR],
    uniforms = .[
        .TRANSFORM,
    ],
    per_object_transforms = false,
    immediate_mode_support = true,
    num_elements_in_each_buffer = 100000, 
    vertex_shader_path = "data/shaders/out/transform_position_color_alpha.vert",
    fragment_shader_path = "data/shaders/out/color_alpha.frag"
};


/*

for text rendering at small and large fonts cleanly

*/
MULTI_CHANNEL_SIGNED_DISTANCE_FIELD_TEXT :: Shader_Metadata.{
    name = "Multi_Channel_Signed_Distance_Field_Text",
    attributes = .[.POSITION, .PASSTHROUGH_TEXTURE_COORDINATE],
    uniforms = .[
        .ASPECT_RATIO,
        .TEXTURE_SAMPLER,
        .RGBA_COLOR,
    ],
    per_object_transforms = false,
    immediate_mode_support = true,
    num_elements_in_each_buffer = 100000, // i think this could be reduced because text has less usually.
    vertex_shader_path = "data/shaders/out/absolute_position_textured.vert",
    fragment_shader_path = "data/shaders/out/multi_channel_signed_distance_field_text.frag"
};

TRANSFORM_MSDF_TEXT :: Shader_Metadata.{
    name = "Transform_MSDF_Text",
    attributes = .[.POSITION, .PASSTHROUGH_TEXTURE_COORDINATE],
    uniforms = .[
        .TRANSFORM,
        .TEXTURE_SAMPLER,
        .RGBA_COLOR,
    ],
    per_object_transforms = false,
    immediate_mode_support = true,
    num_elements_in_each_buffer = 100000, // i think this could be reduced because text has less usually.
    vertex_shader_path = "data/shaders/out/transform_position_textured.vert",
    fragment_shader_path = "data/shaders/out/multi_channel_signed_distance_field_text.frag"
};


/*

Takes in a framebuffer storing a bunch of objects being rendered by their ids (similar to 3d object picking)
then it adds outlines to it based on the objects. Note that this isn't called camera_per_object blah blah, because
it doesn't care where it came from.

Specifically I render my scene with the CAMERA_PER_OBJECT_TRANSFORM_OBJECT_ID, on a different framebuffer, then I bind that texture
into this shader and continue on.

*/
OBJECT_ID_SELECTION_OUTLINE :: Shader_Metadata.{
    name = "Object_Id_Selection_Outline", 
    attributes = .[],
    uniforms = .[.OBJECT_ID_TEXTURE, .SELECTED_OBJECT_ID, .RGBA_COLOR, .THICKNESS_PX],
    per_object_transforms = true,
    num_elements_in_each_buffer = 100000,
    vertex_shader_path = "data/shaders/out/fullscreen_quad.vert",
    fragment_shader_path = "data/shaders/out/object_id_selection_outline.frag"
};


/*

This shader was is a way to get borders on things fast, or so I thought. 
Pretty much what it does is that it takes a 3d object, renders that to a stencil buffer with all 1's.
Then you render again but this time with a "bigger" version of that object and only in places where it's 0.

This tries to make an outline, and it works on most 3d objects, but then it fails on objects that are like 2d quads and stuff.
So I realized it's not that good. I'm not sure if I'll be using this again, but I'll just keep it for now.

*/
CAMERA_PER_OBJECT_TRANSFORM_NORMAL_BORDER :: Shader_Metadata.{
    name = "Camera_Per_Object_Transform_Normal_Border", 
    attributes = .[.POSITION, .NORMAL],
    uniforms = .[.CAMERA_TO_CLIP, .WORLD_TO_CAMERA, .BORDER_THICKNESS, .RGB_COLOR],
    per_object_transforms = true,
    num_elements_in_each_buffer = 100000,
    vertex_shader_path = "data/shaders/out/camera_per_object_transform_normal_border.vert",
    fragment_shader_path = "data/shaders/out/uniform_color.frag"
};


/*

This is the simplest shader to get stuff on the screen and be somewhat visible with camera controls.

This shader is also useful to check performance things, because you're barely doing anything at all here.

*/
CAMERA_PER_OBJECT_TRANSFORM_COLOR :: Shader_Metadata.{
    // todo one day rename Transform to Transforms here, will have to update the using code too. hence why I'm not doing it now.
    name = "Camera_Per_Object_Transform_Color", 
    attributes = .[.POSITION, .PASSTHROUGH_RGB_COLOR],
    uniforms = .[.CAMERA_TO_CLIP, .WORLD_TO_CAMERA],
    per_object_transforms = true,
    immediate_mode_support = true,
    num_elements_in_each_buffer = 100000,
    vertex_shader_path = "data/shaders/out/camera_per_object_transform_color.vert",
    fragment_shader_path = "data/shaders/out/color.frag"
};

CAMERA_PER_OBJECT_TRANSFORMS_COLOR_ALPHA :: Shader_Metadata.{
    name = "Camera_Per_Object_Transform_Color_Alpha", 
    attributes = .[.POSITION, .PASSTHROUGH_RGBA_COLOR],
    uniforms = .[.CAMERA_TO_CLIP, .WORLD_TO_CAMERA],
    per_object_transforms = true,
    num_elements_in_each_buffer = 100000,
    vertex_shader_path = "data/shaders/out/camera_per_object_transform_color_alpha.vert",
    fragment_shader_path = "data/shaders/out/color_alpha.frag"
};


/*
 in opengl3.3 we can batch our objects together but then we run into the problem
 of how do we bind the right texture if we draw all our objects at once, this shader
 solves it by making a bunch of texture atlases of all the textures we are using 
 then we use indices to determine which atlas to go into and then which bounding box is used
 for a particular texture.

 We abbreivate all the above as a shader being "texture packed". 

 I'm pretty sure that in later versions of opengl 4.6 you can just use bindless textures, but I'm
 still keeping this in-case there's a context where 3.3 is important.
*/

CAMERA_PER_OBJECT_TRANSFORM_PACKED_TEXTURE :: Shader_Metadata.{
    // todo change to not use transforms instead just the singular.
    name = "Camera_Per_Object_Transforms_Packed_Texture", 
    attributes = .[
        .POSITION,
        .PASSTHROUGH_PACKED_TEXTURE_INDEX, 
        .PASSTHROUGH_TEXTURE_COORDINATE,
        .PASSTHROUGH_PACKED_TEXTURE_BOUNDING_BOX_INDEX,
    ],
    uniforms = .[
        .CAMERA_TO_CLIP, 
        .WORLD_TO_CAMERA,
        .PACKED_TEXTURES,
        .PACKED_TEXTURE_BOUNDING_BOXES
    ],
    per_object_transforms = true,
    num_elements_in_each_buffer = 100000,
    vertex_shader_path = "data/shaders/out/camera_per_object_transform_packed_texture.vert",
    fragment_shader_path = "data/shaders/out/packed_texture.frag"
};

// could do 4 channel and 8 channel in the future I guess if needed.
CAMERA_PER_OBJECT_TRANSFORM_PACKED_TEXTURE_2_CHANNEL :: Shader_Metadata.{
    name = "Camera_Per_Object_Transform_Packed_Texture_2_Channel", 
    attributes = .[
        .POSITION,

        .PASSTHROUGH_TEXTURE_COORDINATE_0,
        .PASSTHROUGH_PACKED_TEXTURE_INDEX_0, 
        .PASSTHROUGH_PACKED_TEXTURE_BOUNDING_BOX_INDEX_0,

        .PASSTHROUGH_TEXTURE_COORDINATE_1,
        .PASSTHROUGH_PACKED_TEXTURE_INDEX_1, 
        .PASSTHROUGH_PACKED_TEXTURE_BOUNDING_BOX_INDEX_1,

    ],
    uniforms = .[
        .CAMERA_TO_CLIP, 
        .WORLD_TO_CAMERA,
        .PACKED_TEXTURES,
        .PACKED_TEXTURE_BOUNDING_BOXES
    ],
    per_object_transforms = true,
    num_elements_in_each_buffer = 100000,
    vertex_shader_path = "data/shaders/out/camera_per_object_transform_packed_texture_2_channel.vert",
    fragment_shader_path = "data/shaders/out/packed_texture_2_channel.frag"
};


CAMERA_PER_OBJECT_TRANSFORM_PBR_PACKED_TEXTURE :: Shader_Metadata.{
    name = "Camera_Per_Object_Transform_Pbr_Packed_Texture",
    attributes = .[
        .POSITION,
        .PASSTHROUGH_NORMAL,
        .PASSTHROUGH_TANGENT,
        .PASSTHROUGH_TEXTURE_COORDINATE,

        .PASSTHROUGH_PACKED_TEXTURE_INDEX_FOR_BASE_COLOR,
        .PASSTHROUGH_PACKED_TEXTURE_BOUNDING_BOX_INDEX_FOR_BASE_COLOR,

        .PASSTHROUGH_PACKED_TEXTURE_INDEX_FOR_NORMAL,
        .PASSTHROUGH_PACKED_TEXTURE_BOUNDING_BOX_INDEX_FOR_NORMAL,

        .PASSTHROUGH_PACKED_TEXTURE_INDEX_FOR_METALLIC_ROUGHNESS,
        .PASSTHROUGH_PACKED_TEXTURE_BOUNDING_BOX_INDEX_FOR_METALLIC_ROUGHNESS,

        .PASSTHROUGH_PACKED_TEXTURE_INDEX_FOR_AMBIENT_OCCLUSION,
        .PASSTHROUGH_PACKED_TEXTURE_BOUNDING_BOX_INDEX_FOR_AMBIENT_OCCLUSION,
    ],
    uniforms = .[
        .CAMERA_TO_CLIP,
        .WORLD_TO_CAMERA,
        .CAMERA_POSITION,
        .PACKED_TEXTURES,
        .PACKED_TEXTURE_BOUNDING_BOXES,
        .NUM_ACTIVE_LIGHTS,
        .DEFAULT_BASE_COLOR,
        .DEFAULT_METALLIC,
        .DEFAULT_ROUGHNESS,
        .DEFAULT_AMBIENT_OCCLUSION,
    ],
    per_object_transforms = true,
    num_elements_in_each_buffer = 500000,
    vertex_shader_path   = "data/shaders/out/camera_per_object_transform_pbr_packed_texture.vert",
    fragment_shader_path = "data/shaders/out/pbr_packed_texture.frag",
};


CAMERA_PER_OBJECT_TRANSFORM_DEFERRED_LIGHTING_GEOMETRY_PASS :: Shader_Metadata.{
    name = "Camera_Per_Object_Transform_Deferred_Lighting_Geometry_Pass", 
    attributes = .[
        .POSITION,
        .PASSTHROUGH_RGB_COLOR,
        .PASSTHROUGH_NORMAL
    ],
    uniforms = .[
        .CAMERA_TO_CLIP, 
        .WORLD_TO_CAMERA
    ],
    per_object_transforms = true,
    num_elements_in_each_buffer = 100000,
    vertex_shader_path   = "data/shaders/out/lighting/camera_per_object_transform_color_normal.vert",
    fragment_shader_path = "data/shaders/out/lighting/render_position_color_normal_textures.frag"
};

CAMERA_PER_OBJECT_TRANSFORM_DEFERRED_LIGHTING_COMPUTE_LIGHT_PASS :: Shader_Metadata.{
    name = "Camera_Per_Object_Transform_Deferred_Lighting_Compute_Light_Pass", 
    attributes = .[
        .POSITION,
        .PASSTHROUGH_TEXTURE_COORDINATE,
    ],
    uniforms = .[
        .ASPECT_RATIO,
        .POSITION_TEXTURE,
        .COLOR_TEXTURE,
        .NORMAL_TEXTURE
    ],
    per_object_transforms = false,
    num_elements_in_each_buffer = 100000,
    vertex_shader_path   = "data/shaders/out/absolute_position_textured.vert",
    fragment_shader_path = "data/shaders/out/lighting/compute_lighting_from_position_color_normal_textures.frag"
};

get_renderer_struct_name :: (shader : Shader_Metadata) -> string {
    return tprint("%1_Renderer", shader.name);
}

get_renderable_struct_name :: (shader : Shader_Metadata) -> string {
    return tprint("%1_Renderable", shader.name);
}

// this is mega wasteful during compilation, there should just be a script to do this in this directory... 

#run create_code_to_render_stuff_with_shader(ABSOLUTE_POSITION_COLOR_SHADER);
#run create_code_to_render_stuff_with_shader(ABSOLUTE_POSITION_COLOR_ALPHA);
#run create_code_to_render_stuff_with_shader(TRANSFORM_POSITION_COLOR_ALPHA);
#run create_code_to_render_stuff_with_shader(CAMERA_ABSOLUTE_POSITION_COLOR);

#run create_code_to_render_stuff_with_shader(MULTI_CHANNEL_SIGNED_DISTANCE_FIELD_TEXT);
#run create_code_to_render_stuff_with_shader(TRANSFORM_MSDF_TEXT);

#run create_code_to_render_stuff_with_shader(CAMERA_PER_OBJECT_TRANSFORM_NORMAL_BORDER);
#run create_code_to_render_stuff_with_shader(OBJECT_ID_SELECTION_OUTLINE);

#run create_code_to_render_stuff_with_shader(CAMERA_PER_OBJECT_TRANSFORM_POSITION_POINT_COLOR);
#run create_code_to_render_stuff_with_shader(CAMERA_PER_OBJECT_TRANSFORM_OBJECT_ID);

#run create_code_to_render_stuff_with_shader(CAMERA_INFINITE_GRID_SHADER);

#run create_code_to_render_stuff_with_shader(CAMERA_PER_OBJECT_TRANSFORM_COLOR);
#run create_code_to_render_stuff_with_shader(CAMERA_PER_OBJECT_TRANSFORMS_COLOR_ALPHA);

#run create_code_to_render_stuff_with_shader(CAMERA_PER_OBJECT_TRANSFORM_PACKED_TEXTURE);
#run create_code_to_render_stuff_with_shader(CAMERA_PER_OBJECT_TRANSFORM_PACKED_TEXTURE_2_CHANNEL);

#run create_code_to_render_stuff_with_shader(CAMERA_PER_OBJECT_TRANSFORM_PBR_PACKED_TEXTURE);

#run create_code_to_render_stuff_with_shader(CAMERA_PER_OBJECT_TRANSFORM_DEFERRED_LIGHTING_GEOMETRY_PASS);
#run create_code_to_render_stuff_with_shader(CAMERA_PER_OBJECT_TRANSFORM_DEFERRED_LIGHTING_COMPUTE_LIGHT_PASS);

create_code_to_render_stuff_with_shader :: (shader: Shader_Metadata) {
    push_allocator(temp);

    builder: String_Builder;
    init_string_builder(*builder);

    print_to_builder(*builder, "// auto-generated renderer for shader: %\n", shader.name);
    print_to_builder(*builder, "// do not edit manually.\n\n");

    has_attributes := shader.attributes.count > 0;

    if has_attributes {
        append(*builder, generate_renderable_struct_for_given_shader(shader));
        append(*builder, generate_code_for_constructing_renderable_from_generic_geometry_type(shader));
        append(*builder, generate_code_for_deinit_renderable(shader));
        append(*builder, generate_code_for_unbuffer_renderable(shader));
        append(*builder, generate_code_for_queue_render_from_renderable(shader));
        if shader.per_object_transforms append(*builder, generate_code_for_set_local_to_world_matrix(shader));
    }

    append(*builder, generate_renderer_struct_for_given_shader(shader));
    append(*builder, generate_code_for_uniform_setter_functions(shader));
    append(*builder, generate_code_for_init(shader));
    append(*builder, generate_code_for_deinit_renderer(shader));

    if has_attributes {
        append(*builder, generate_init_buffers_no_data(shader));
        append(*builder, generate_init_immediate_buffers(shader));       
        append(*builder, generate_code_for_buffer_object_from_renderable(shader));
        append(*builder, generate_buffer_object(shader));
        append(*builder, generate_rebuffer_object(shader));
        append(*builder, generate_render(shader));
        append(*builder, generate_immediate_render(shader));            
    }

    output := builder_to_string(*builder);

    renderers_dir := tprint("%/renderers", #filepath);
    make_directory_if_it_does_not_exist(renderers_dir);

    filename := tprint("%/%_renderer.jai", renderers_dir, to_lower_copy(shader.name));

    success := write_entire_file(filename, output);
    if !success {
        log_error("Failed to write generated file: %", filename);
    } 
}

jai_struct_attributes_for_gl_vertex_attribute_handles :: (attributes: [] GL_Shader_Vertex_Attribute_Variable) -> string {
    push_allocator(temp); // everything in this function is temp storage, yay!

    builder: String_Builder;
    init_string_builder(*builder); 

    for attributes {
        attr_conf := get_configuration(it); 
        print_to_builder(*builder, "    %_buffer_gl_handle: GLuint;\n", attr_conf.plural_name);
    }

    return builder_to_string(*builder);
}

generate_code_for_per_object_transform_attributes :: (s : Shader_Metadata) -> string {
    if !s.per_object_transforms return "";

    return #string END 

    using #as ltw_pool : Local_To_World_Matrix_Pool;

    local_to_world_index_buffer_gl_handle : GLuint;

    END;
}

generate_code_for_cached_uniform_location_attributes :: (shader: Shader_Metadata) -> string {
    push_allocator(temp);
    builder: String_Builder;
    init_string_builder(*builder);

    for shader.uniforms {
        unif_conf := get_configuration(it);
        print_to_builder(*builder, "    %_uniform_location : GLint = -1;\n", 
            to_lower_copy(tprint("%", it)));
    }

    return builder_to_string(*builder);
}

generate_code_for_immediate_mode_attributes :: (s : Shader_Metadata) -> string {
    if !s.immediate_mode_support return "";

    push_allocator(temp);
    builder: String_Builder;
    init_string_builder(*builder);

    print_to_builder(*builder, "\n    // immediate-mode buffers\n");
    print_to_builder(*builder, "    immediate_vertex_attribute_array_gl_handle: GLuint;\n");
    print_to_builder(*builder, "    immediate_index_buffer_gl_handle: GLuint;\n");

    for s.attributes {
        attr_conf := get_configuration(it);
        print_to_builder(*builder, "    immediate_%_buffer_gl_handle: GLuint;\n", attr_conf.plural_name);
    }

    return builder_to_string(*builder);
}

generate_renderer_struct_for_given_shader :: (s : Shader_Metadata) -> string {
    return tprint(#string END

%1 :: struct {
    using #as psr : Per_Shader_Renderer;

%2
%3
%4
%5
}

    END, get_renderer_struct_name(s), 
         generate_code_for_per_object_transform_attributes(s), 
         generate_code_for_cached_uniform_location_attributes(s),    
         jai_struct_attributes_for_gl_vertex_attribute_handles(s.attributes),
         generate_code_for_immediate_mode_attributes(s));
}

generate_renderable_struct_attributes :: (shader : Shader_Metadata) -> string {
    push_allocator(temp); 

    builder: String_Builder;
    init_string_builder(*builder); 

    if shader.per_object_transforms print_to_builder(*builder, "    local_to_world_index : u32;\n\n");

    for shader.attributes {
        attr_conf := get_configuration(it); 
        print_to_builder(*builder, "    %: [..] %;\n", attr_conf.argument_name_in_buffer_object, attr_conf.type_in_jai);
    }

    return builder_to_string(*builder);
}

generate_renderable_struct_for_given_shader :: (s : Shader_Metadata) -> string {

    return tprint(#string END

%1 :: struct {
    indices : [..] u32;
    object_index : u32;

%2
}

    END, get_renderable_struct_name(s), generate_renderable_struct_attributes(s));
}

generate_code_for_constructing_renderable_from_generic_geometry_type :: (shader: Shader_Metadata) -> string {
    push_allocator(temp);

    geometry_struct_name := tprint("%1_Geometry", shader.name);

    geometry_fields: String_Builder;
    init_string_builder(*geometry_fields);
    print_to_builder(*geometry_fields, "    indices : [..] u32;\n");
    for shader.attributes {
        attr_conf := get_configuration(it);
        print_to_builder(*geometry_fields, "    %: [..] %;\n", attr_conf.argument_name_in_buffer_object, attr_conf.type_in_jai);
    }

    copy_assignments: String_Builder;
    init_string_builder(*copy_assignments);
    print_to_builder(*copy_assignments, "    array_copy(*renderable.indices, geometry.indices);\n");
    for shader.attributes {
        attr_conf := get_configuration(it);
        print_to_builder(*copy_assignments, "    array_copy(*renderable.%, geometry.%);\n", attr_conf.argument_name_in_buffer_object, attr_conf.argument_name_in_buffer_object);
    }

    shallow_assignments: String_Builder;
    init_string_builder(*shallow_assignments);
    print_to_builder(*shallow_assignments, "    renderable.indices = geometry.indices;\n");
    for shader.attributes {
        attr_conf := get_configuration(it);
        print_to_builder(*shallow_assignments, "    renderable.% = geometry.%;\n", attr_conf.argument_name_in_buffer_object, attr_conf.argument_name_in_buffer_object);
    }

    return tprint(#string END

%1 :: struct {
%2}

assign_geometry_copy :: (renderable: *%3, geometry: $T/interface %1) {
%4}

assign_geometry :: (renderable: *%3, geometry: $T/interface %1) {
%5}

    END,
    geometry_struct_name,
    builder_to_string(*geometry_fields),
    get_renderable_struct_name(shader),
    builder_to_string(*copy_assignments),
    builder_to_string(*shallow_assignments)
    );
}

generate_code_for_set_local_to_world_matrix :: (shader: Shader_Metadata) -> string {
    push_allocator(temp);

    renderable_struct_name := get_renderable_struct_name(shader);
    renderer_struct_name := get_renderer_struct_name(shader);

    return tprint(#string END

set_local_to_world_matrix :: (renderer: *%1, renderable: %2, matrix: Matrix4) {
    set_matrix(*renderer.ltw_pool, renderable.local_to_world_index, matrix);
}

    END,
    renderer_struct_name,
    renderable_struct_name
    );
}

generate_code_for_deinit_renderable :: (shader: Shader_Metadata) -> string {
    push_allocator(temp);

    array_frees: String_Builder;
    init_string_builder(*array_frees);

    print_to_builder(*array_frees, "    array_free(renderable.indices);\n");
    for shader.attributes {
        attr_conf := get_configuration(it);
        print_to_builder(*array_frees, "    array_free(renderable.%);\n", attr_conf.argument_name_in_buffer_object);
    }

    per_object_transform_cleanup := "";
    if shader.per_object_transforms {
        per_object_transform_cleanup = "    free_index(*renderer.ltw_pool, renderable.local_to_world_index);\n    renderable.local_to_world_index = 0;\n    renderable.object_index = 0;\n";
    }

    return tprint(#string END

deinit :: (renderable: *%1) {
%4}

/*

So deinit exists but also unbuffer object exists, the difference is that deinit takes in a renderable and frees its CPU-side arrays and resets its transform slot, whereas unbuffer_object only frees the GPU-side virtual allocation, leaving the CPU data intact for potential re-buffering later.

*/
deinit :: (renderable: *%1, renderer: *%2) {
    unbuffer_object(*renderer.psr, renderable.object_index);
%3%4}

    END,
    get_renderable_struct_name(shader),
    get_renderer_struct_name(shader),
    per_object_transform_cleanup,
    builder_to_string(*array_frees)
    );
}

generate_code_for_unbuffer_renderable :: (shader: Shader_Metadata) -> string {
    push_allocator(temp);

    local_to_world_reset := "";
    if shader.per_object_transforms {
        local_to_world_reset = tprint(
            "    free_index(*renderer.ltw_pool, renderable.local_to_world_index);\n    renderable.local_to_world_index = 0;\n"
        );
    }

    return tprint(#string END

unbuffer_object :: (renderer: *%1, renderable: *%2) {
    unbuffer_object(*renderer.psr, renderable.object_index);
%3    renderable.object_index = 0;
}

    END,
    get_renderer_struct_name(shader),
    get_renderable_struct_name(shader),
    local_to_world_reset
    );
}

generate_code_for_queue_render_from_renderable :: (shader: Shader_Metadata) -> string {
    return tprint(#string END

queue_render :: (using renderer: *%1, renderable: %2) {
    queue_render(*renderer.psr, renderable.object_index);
}

    END,
    get_renderer_struct_name(shader),
    get_renderable_struct_name(shader));
}

generate_code_for_initting_matrices :: (s : Shader_Metadata) -> string {
    if !s.per_object_transforms return "";
    return #string END
    init(*renderer.ltw_pool);
    END;
}

generate_code_for_caching_uniform_locations :: (shader: Shader_Metadata) -> string {
    push_allocator(temp);
    builder: String_Builder;
    init_string_builder(*builder);

    for shader.uniforms {
        unif_conf := get_configuration(it);
        lower_name := to_lower_copy(tprint("%", it));
        print_to_builder(*builder, 
            "    %_uniform_location = glGetUniformLocation(shader_program_gl_handle, \"%\");\n",
            lower_name, unif_conf.var_name_in_shader);
    }

    return builder_to_string(*builder);
}

generate_code_for_init :: (shader : Shader_Metadata) -> string {

    immediate_init_call := ifx shader.immediate_mode_support then "    init_immediate_buffers(renderer);\n" else "";
    init_buffers_call := ifx shader.attributes.count > 0 then "    init_buffers_no_data(renderer);\n" else "";

    return tprint(#string END

init :: (using renderer : *%1) { 
    vertex_shader_loaded, vertex_shader_source := load_asset("%2");
    assert(vertex_shader_loaded, "Failed to load vertex shader asset: %2");
    fragment_shader_loaded, fragment_shader_source := load_asset("%3");
    assert(fragment_shader_loaded, "Failed to load fragment shader asset: %3");

    init(renderer, vertex_shader_source, fragment_shader_source, max_num_elements_in_each_buffer);
%6%7
%4
%5
}

    END, get_renderer_struct_name(shader), 
         shader.vertex_shader_path, 
         shader.fragment_shader_path, 
         generate_code_for_initting_matrices(shader),
         generate_code_for_caching_uniform_locations(shader),
         init_buffers_call,
         immediate_init_call); 
}

generate_code_for_deinit_renderer :: (shader: Shader_Metadata) -> string {
    push_allocator(temp);

    builder: String_Builder;
    init_string_builder(*builder);

    // deinit the local-to-world matrix pool if applicable
    if shader.per_object_transforms {
        print_to_builder(*builder, "    deinit(*ltw_pool);\n\n");
    }

    // deinit the base per-shader renderer (shader program, VAO, index buffer, tables, allocator, etc.)
    print_to_builder(*builder, "    deinit(*psr);\n\n");

    // delete per-attribute GL buffers
    for shader.attributes {
        attr_conf := get_configuration(it);
        print_to_builder(*builder, "    glDeleteBuffers(1, *%_buffer_gl_handle);\n", attr_conf.plural_name);
    }

    // delete the local_to_world_index buffer if applicable
    if shader.per_object_transforms {
        print_to_builder(*builder, "    glDeleteBuffers(1, *local_to_world_index_buffer_gl_handle);\n");
    }

    // delete immediate-mode GL resources if applicable
    if shader.immediate_mode_support {
        print_to_builder(*builder, "\n    // immediate-mode cleanup\n");
        print_to_builder(*builder, "    glDeleteBuffers(1, *immediate_index_buffer_gl_handle);\n");
        for shader.attributes {
            attr_conf := get_configuration(it);
            print_to_builder(*builder, "    glDeleteBuffers(1, *immediate_%_buffer_gl_handle);\n", attr_conf.plural_name);
        }
        print_to_builder(*builder, "    glDeleteVertexArrays(1, *immediate_vertex_attribute_array_gl_handle);\n");
    }

    return tprint(#string END

deinit :: (using renderer : *%1) {
%2}

    END,
    get_renderer_struct_name(shader),
    builder_to_string(*builder));
}

generate_attribute_setup_code :: (attributes: [] GL_Shader_Vertex_Attribute_Variable) -> string {
    push_allocator(temp);
    builder: String_Builder;

    for attr: attributes {
        glvac := get_configuration(attr);

        print_to_builder(*builder,
            "    generate_buffer_for_vertex_attribute(*%_buffer_gl_handle, %, max_num_elements_in_each_buffer);\n",
            glvac.plural_name, glvac.type_in_jai
        );

        print_to_builder(*builder,
            "    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, %_buffer_gl_handle, .%);\n\n",
            glvac.plural_name, attr
        );
    }

    return builder_to_string(*builder);
}

generate_code_for_setting_up_local_to_world_matrices :: (shader : Shader_Metadata) -> string {
    if !shader.per_object_transforms return "";
    return #string END

    generate_buffer_for_vertex_attribute(*local_to_world_index_buffer_gl_handle, u32, max_num_elements_in_each_buffer);
    init_vertex_attribute(shader_program_gl_handle, vertex_attribute_array_gl_handle, local_to_world_index_buffer_gl_handle, .LOCAL_TO_WORLD_INDEX);

    END;
}


generate_init_buffers_no_data :: (shader : Shader_Metadata) -> string {
    return tprint(#string END


init_buffers_no_data :: (using apcr : *%1) { // todo change renderer name

    glGenVertexArrays(1, *vertex_attribute_array_gl_handle);
    glBindVertexArray(vertex_attribute_array_gl_handle);

%2

    glGenBuffers(1, *index_buffer_gl_handle);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index_buffer_gl_handle);
    // NOTE: it's probably wrong to use  max_num_elements_in_each_buffer because as noted before the number of indices
    // could be larger than this value if we try and render all objects, but we won't care about that until it's a problem.
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, size_of(u32) *  max_num_elements_in_each_buffer, null, GL_DYNAMIC_DRAW);
    // note: we don't have to init the vertex attribute for indices because they used in the shader program for rendering, they're just used during glDrawElements.

%3

	glBindBuffer (GL_ARRAY_BUFFER, 0);
}

    END, 
    get_renderer_struct_name(shader), 
    generate_code_for_setting_up_local_to_world_matrices(shader), 
    generate_attribute_setup_code(shader.attributes));
}

generate_init_immediate_buffers :: (shader : Shader_Metadata) -> string {
    if !shader.immediate_mode_support return "";

    push_allocator(temp);

    attribute_setup: String_Builder;
    init_string_builder(*attribute_setup);

    for shader.attributes {
        attr_conf := get_configuration(it);

        print_to_builder(*attribute_setup,
            "    generate_buffer_for_vertex_attribute(*immediate_%_buffer_gl_handle, %, %);\n",
            attr_conf.plural_name, attr_conf.type_in_jai, shader.num_elements_in_each_immediate_buffer
        );

        print_to_builder(*attribute_setup,
            "    init_vertex_attribute(shader_program_gl_handle, immediate_vertex_attribute_array_gl_handle, immediate_%_buffer_gl_handle, .%);\n\n",
            attr_conf.plural_name, shader.attributes[it_index]
        );
    }

    return tprint(#string END


init_immediate_buffers :: (using renderer : *%1) {

    glGenVertexArrays(1, *immediate_vertex_attribute_array_gl_handle);
    glBindVertexArray(immediate_vertex_attribute_array_gl_handle);

    glGenBuffers(1, *immediate_index_buffer_gl_handle);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, immediate_index_buffer_gl_handle);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, size_of(u32) * %2, null, GL_STREAM_DRAW);

%3

    glBindBuffer(GL_ARRAY_BUFFER, 0);
}

    END, 
    get_renderer_struct_name(shader),
    shader.num_elements_in_each_immediate_buffer,
    builder_to_string(*attribute_setup));
}


generate_buffer_vertex_attribute_data_at_index_code :: (attribute: GL_Shader_Vertex_Attribute_Variable) -> string {
    // maybe just pass the conf then?
    attr_conf := get_configuration(attribute);
    return tprint(#string END

    glBindBuffer(GL_ARRAY_BUFFER, %1_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, index * size_of(%2), %3.count * size_of(%2), %3.data);

    END, attr_conf.plural_name, attr_conf.type_in_jai, attr_conf.argument_name_in_buffer_object);
}


code_to_buffer_local_to_world_indices :: #string END
    ltw_index_we_used, ltw_success := alloc_index(*ltw_pool);
    if !ltw_success {
        virtual_free(*first_fit_virtual_allocator, index);
        return 0, 0, false;
    }

    local_to_world_indices: [..] u32;
    for 0..positions.count-1 array_add(*local_to_world_indices, ltw_index_we_used);

    glBindBuffer(GL_ARRAY_BUFFER, local_to_world_index_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, index * size_of(u32), local_to_world_indices.count * size_of(u32), local_to_world_indices.data);

    array_free(local_to_world_indices);
END;

generate_buffer_vertex_attributes_code :: (shader : Shader_Metadata) -> string {
    push_allocator(temp);
    builder: String_Builder;

    for shader.attributes {
        print_to_builder(*builder, "    %\n", generate_buffer_vertex_attribute_data_at_index_code(it));
    }

    if shader.per_object_transforms print_to_builder(*builder, code_to_buffer_local_to_world_indices);

    return builder_to_string(*builder);
}

generate_parameter_list_for_buffer_object :: (shader : Shader_Metadata) -> string {

    push_allocator(temp);
    builder: String_Builder;


    for shader.attributes {
        attr_conf := get_configuration(it);
        print_to_builder(*builder, "        % : [..] %", attr_conf.argument_name_in_buffer_object, attr_conf.type_in_jai); 
        if it_index < shader.attributes.count-1 print_to_builder(*builder, ",\n");
    }

    return tprint(#string END
        using renderer: *%1,
        indices : [..] u32,
%2
    END, get_renderer_struct_name(shader), builder_to_string(*builder));
}

// was about to integrate this.

generate_code_for_return_type_of_buffer_object :: (shader : Shader_Metadata) -> string {
    if shader.per_object_transforms return "object_index: u32, local_to_world_index: u32, success: bool";
    return "object_index: u32, success: bool";
}

generate_code_for_return_in_failure_case  :: (shader : Shader_Metadata) -> string {
    if shader.per_object_transforms return "return 0, 0, false;";
    return "return 0, false;";
}

generate_code_for_final_return :: (shader : Shader_Metadata) -> string {
    if shader.per_object_transforms return "return index, ltw_index_we_used, true;";
    return "return index, true;";
}


generate_buffer_object :: (shader : Shader_Metadata) -> string {

    return tprint(#string END
// todo ability to specify the transform matrix upon buffering?
buffer_object :: (
%1
        ) -> %2 {

    // note: we use the positions as count, becaues that is the actual data that needs to be in the buffer
    // the indices use duplicates sometimes to refer to the same vertex multiple times.
    length := positions.count; // TODO: need to metaprogram this out, but it's pretty safe for now.
    index, success := virtual_alloc(*first_fit_virtual_allocator, xx length);
    if !success {
        log("ran out of virtual memory");
        %3
    }

    global_indices_for_object : [..] u32;
    for indices 
        array_add(*global_indices_for_object, xx index + it);

    table_add(*buffered_object_index_to_global_indices, xx index, global_indices_for_object);

    glBindVertexArray(vertex_attribute_array_gl_handle);

%4

    glBindVertexArray(0);

    %5
}
    END, 
    generate_parameter_list_for_buffer_object(shader), 
    generate_code_for_return_type_of_buffer_object(shader), 
    generate_code_for_return_in_failure_case(shader),
    generate_buffer_vertex_attributes_code(shader),
    generate_code_for_final_return(shader)
    );

}

generate_code_for_buffer_object_from_renderable :: (shader : Shader_Metadata) -> string {

    push_allocator(temp); 

    // we're building a the body here.
    buffer_object_call_code: String_Builder;

    if !shader.per_object_transforms { 
        print_to_builder(*buffer_object_call_code, #string END

    object_index, success := buffer_object(renderer, 
            renderable.indices, 

        END);
    } else {
        print_to_builder(*buffer_object_call_code, #string END

    object_index, local_to_world_index, success := buffer_object(renderer, 
            renderable.indices, 

        END);
    }

    for shader.attributes {
        attr_conf := get_configuration(it);
        print_to_builder(*buffer_object_call_code, "            renderable.%", attr_conf.argument_name_in_buffer_object); 
        if it_index < shader.attributes.count-1 {
            print_to_builder(*buffer_object_call_code, ",\n");
        } else {
            print_to_builder(*buffer_object_call_code, "\n    );");
        }
    }

    success_assignment_code : String_Builder;
    print_to_builder(*success_assignment_code, "        renderable.object_index = object_index;\n");
    if shader.per_object_transforms print_to_builder(*success_assignment_code, "        renderable.local_to_world_index = local_to_world_index;\n");

    return tprint(#string END

buffer_object :: (using renderer : *%1, renderable : *$T/interface %2) -> success: bool {

%3

    if success {
%4
    };
    return success;
}

    END, 
    get_renderer_struct_name(shader), 
    get_renderable_struct_name(shader),
    builder_to_string(*buffer_object_call_code),
    builder_to_string(*success_assignment_code)
    );
}

generate_rebuffer_object :: (shader : Shader_Metadata) -> string {
    push_allocator(temp);

    renderer_name := get_renderer_struct_name(shader);
    renderable_name := get_renderable_struct_name(shader);

    upload_code: String_Builder;
    init_string_builder(*upload_code);

    for shader.attributes {
        attr_conf := get_configuration(it);
        print_to_builder(*upload_code, #string ATTR
    glBindBuffer(GL_ARRAY_BUFFER, %1_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, renderable.object_index * size_of(%2), renderable.%3.count * size_of(%2), renderable.%3.data);

ATTR,
            attr_conf.plural_name,
            attr_conf.type_in_jai,
            attr_conf.argument_name_in_buffer_object);
    }

    return tprint(#string END

/*

So this function is kinda sketchy right now, you can only rebuffer an object if it takes up the exact same size, 
if you're rebuffering things and using up more space then you did before you'll start having undefined behavior in rendering and things 
will go off the rails.

*/
rebuffer_object :: (using renderer : *%1, renderable : $T/interface %2) {

    glBindVertexArray(vertex_attribute_array_gl_handle);

%3
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);
}

    END,
    renderer_name,
    renderable_name,
    builder_to_string(*upload_code));
}


generate_code_for_uploading_local_to_world_matrices :: (s: Shader_Metadata) -> string {
    if !s.per_object_transforms return "";
    return #string END

    upload_to_gpu(*ltw_pool);

    END;
}

generate_render :: (shader : Shader_Metadata) -> string {

    return tprint(#string END
render :: (using renderer : *%1, primitive_mode: GLenum = %3) {

    // todo think about if we should be using temporary storage.

    glUseProgram(shader_program_gl_handle);

%2

    glBindVertexArray(vertex_attribute_array_gl_handle);
    // todo: reserve so we don't get a ton of reallocations in this for loop
    geom_indices_to_render : [..] u32;  // can we just use temp storage?
    defer array_free(geom_indices_to_render);
    // array_reserve(*geom_indices_to_render, ???); // needs some running count whenever we buffer an obj.
    for object_indices_to_render_this_frame {
        success, geom_indices := table_find(*buffered_object_index_to_global_indices, it);
        if !success log("couldn't find the global indices of object with id: %", it);
        for geom_indices 
            array_add(*geom_indices_to_render, it);
    }


    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index_buffer_gl_handle);
    // here we're just overwriting the buffer on each draw call, if there's less data written than last iteration it's fine
    // as we will only access the smaller portion
    glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, 0, geom_indices_to_render.count * size_of(u32), geom_indices_to_render.data);

    glDrawElements(primitive_mode, xx geom_indices_to_render.count, GL_UNSIGNED_INT, cast (*void) 0);

    // the rendering the same objects test as last frame test is a worthwhile optimization that should occur.

    array_reset(*object_indices_to_render_this_frame);

    glBindVertexArray(0);
    glUseProgram(0);
}

    END, 
    get_renderer_struct_name(shader), 
    generate_code_for_uploading_local_to_world_matrices(shader),
    gl_primitive_mode_to_string(shader.primitive_mode),
    );

}

generate_immediate_render :: (shader : Shader_Metadata) -> string {
    if !shader.immediate_mode_support return "";

    push_allocator(temp);

    param_list: String_Builder;
    init_string_builder(*param_list);
    for shader.attributes {
        attr_conf := get_configuration(it);
        print_to_builder(*param_list, "        % : [] %", attr_conf.argument_name_in_buffer_object, attr_conf.type_in_jai);
        if it_index < shader.attributes.count-1 print_to_builder(*param_list, ",\n");
    }

    upload_code: String_Builder;
    init_string_builder(*upload_code);
    for shader.attributes {
        attr_conf := get_configuration(it);
        print_to_builder(*upload_code,
            "    glBindBuffer(GL_ARRAY_BUFFER, immediate_%1_buffer_gl_handle);\n    glBufferSubData(GL_ARRAY_BUFFER, 0, %2.count * size_of(%3), %2.data);\n\n",
            attr_conf.plural_name, attr_conf.argument_name_in_buffer_object, attr_conf.type_in_jai);
    }

    slice_version := tprint(#string END

immediate_render :: (
        using renderer: *%1,
        indices : [] u32,
%2
        ) {

    assert(indices.count > 0, "No indices to render.");

    glUseProgram(shader_program_gl_handle);
    glBindVertexArray(immediate_vertex_attribute_array_gl_handle);

%3
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, immediate_index_buffer_gl_handle);
    glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, 0, indices.count * size_of(u32), indices.data);

    glDrawElements(GL_TRIANGLES, xx indices.count, GL_UNSIGNED_INT, cast(*void) 0);

    glBindVertexArray(0);
    glUseProgram(0);
}

    END,
    get_renderer_struct_name(shader),
    builder_to_string(*param_list),
    builder_to_string(*upload_code));

    // Geometry convenience overload
    geometry_struct_name := tprint("%1_Geometry", shader.name);

    geometry_args: String_Builder;
    init_string_builder(*geometry_args);
    print_to_builder(*geometry_args, "            geometry.indices,\n");
    for shader.attributes {
        attr_conf := get_configuration(it);
        print_to_builder(*geometry_args, "            geometry.%", attr_conf.argument_name_in_buffer_object);
        if it_index < shader.attributes.count - 1 print_to_builder(*geometry_args, ",\n");
        else print_to_builder(*geometry_args, "\n");
    }

    geometry_version := tprint(#string END

immediate_render :: (using renderer : *%1, geometry : $T/interface %2) {
    immediate_render(renderer,
%3    );
}

    END,
    get_renderer_struct_name(shader),
    geometry_struct_name,
    builder_to_string(*geometry_args));

    // Combine both
    result: String_Builder;
    init_string_builder(*result);
    append(*result, slice_version);
    append(*result, geometry_version);
    return builder_to_string(*result);
}

generate_buffer_for_vertex_attribute :: (attribute_buffer_gl_handle : *GLuint, $attribute_type : Type, num_elements: u32) {
    glGenBuffers(1, attribute_buffer_gl_handle);
    glBindBuffer(GL_ARRAY_BUFFER, attribute_buffer_gl_handle.*);
    glBufferData(GL_ARRAY_BUFFER, size_of(attribute_type) * num_elements, null, GL_DYNAMIC_DRAW);
}

GL_Vertex_Attribute_Configuration :: struct { // gl_vac

    type_in_jai: Type;

    // I'm pretty sure this is just the enum name right? can I remove this?
    var_name_in_shader : string;

    // the plural name can be automated as well, index -> indices everything else trivial add exceptions when needed.
    // this is actually what we call something in the code or something.
    plural_name : string;

    argument_name_in_buffer_object : string;

    // when a value is constant across an object, then you only have to pass in a single value into buffer object rather than an array of them
    constant_across_object : bool;  

    // value_is_constant_per_object : bool; // as of right now only local to world index has this property, when there are other ones that have this we could think about doing this.

    components_per_vertex: GLint;
    data_type_of_component: GLenum;
    normalize : GLboolean;
    stride : GLsizei ;
    pointer_offset_to_start_of_data : *void;

    passthrough := false;
}

gl_uniform_suffix_for_type :: (type: Type) -> string { // unused didn't see the potential yet after doing the matrix fun below
    if type == {
        case Matrix4;  return "Matrix4fv";

        // uncomment as needed so we can find the bug when it happens rather than assuming this is always correct.
        // case Matrix3;  return "Matrix3fv";
        // case Matrix2;  return "Matrix2fv";
        // case Vector4;  return "4fv";
        // case Vector3;  return "3fv";
        // case Vector2;  return "2fv";
        // case float32;  return "1f";
        // case s32;      return "1i";
        // case u32;      return "1ui";
    }

    return "UNSUPPORTED_TYPE";
}

set_uniform :: (shader_program_gl_handle: GLuint, uniform: GL_Shader_Uniform_Variable, m: Matrix4) {

    gl_vuc := get_configuration(uniform);

    row_major := GL_TRUE;
    num_matrices_we_are_updating: u32 = 1;

    uniform_location := glGetUniformLocation(shader_program_gl_handle, temp_c_string(gl_vuc.var_name_in_shader));

    glUniformMatrix4fv(uniform_location, num_matrices_we_are_updating, row_major, *m.coef[0][0]);
}

set_uniform :: (shader_program_gl_handle: GLuint, uniform: GL_Shader_Uniform_Variable, v: Vector2) {
    gl_vuc := get_configuration(uniform);
    uniform_location := glGetUniformLocation(shader_program_gl_handle, temp_c_string(gl_vuc.var_name_in_shader));
    glUniform2f(uniform_location, v.x, v.y);
}

set_uniform :: (shader_program_gl_handle: GLuint, uniform: GL_Shader_Uniform_Variable, value: s32) {
    gl_vuc := get_configuration(uniform);
    uniform_location := glGetUniformLocation(shader_program_gl_handle, temp_c_string(gl_vuc.var_name_in_shader));
    glUniform1i(uniform_location, value);
}

set_uniform :: (shader_program_gl_handle: GLuint, uniform: GL_Shader_Uniform_Variable, value: u32) {
    gl_vuc := get_configuration(uniform);
    uniform_location := glGetUniformLocation(shader_program_gl_handle, temp_c_string(gl_vuc.var_name_in_shader));
    glUniform1ui(uniform_location, value);
}

set_uniform :: (shader_program_gl_handle: GLuint, uniform: GL_Shader_Uniform_Variable, value: float32) {
    gl_vuc := get_configuration(uniform);
    uniform_location := glGetUniformLocation(shader_program_gl_handle, temp_c_string(gl_vuc.var_name_in_shader));
    glUniform1f(uniform_location, value);
}

set_uniform :: (shader_program_gl_handle: GLuint, uniform: GL_Shader_Uniform_Variable, v: Vector3) {
    gl_vuc := get_configuration(uniform);
    uniform_location := glGetUniformLocation(shader_program_gl_handle, temp_c_string(gl_vuc.var_name_in_shader));
    glUniform3f(uniform_location, v.x, v.y, v.z);
}

set_uniform :: (shader_program_gl_handle: GLuint, uniform: GL_Shader_Uniform_Variable, v: Vector4) {
    gl_vuc := get_configuration(uniform);
    uniform_location := glGetUniformLocation(shader_program_gl_handle, temp_c_string(gl_vuc.var_name_in_shader));
    glUniform4f(uniform_location, v.x, v.y, v.z, v.w);
}

set_uniform :: (shader_program_gl_handle: GLuint, uniform: GL_Shader_Uniform_Variable, m: Matrix3) {
    gl_vuc := get_configuration(uniform);
    row_major := GL_TRUE;
    num_matrices_we_are_updating: u32 = 1;
    uniform_location := glGetUniformLocation(shader_program_gl_handle, temp_c_string(gl_vuc.var_name_in_shader));
    glUniformMatrix3fv(uniform_location, num_matrices_we_are_updating, row_major, *m.coef[0][0]);
}

set_uniform :: (shader_program_gl_handle: GLuint, uniform: GL_Shader_Uniform_Variable, value: bool) {
    gl_vuc := get_configuration(uniform);
    uniform_location := glGetUniformLocation(shader_program_gl_handle, temp_c_string(gl_vuc.var_name_in_shader));
    glUniform1i(uniform_location, cast(s32) ifx value then 1 else 0);
}

set_uniform :: (shader_program_gl_handle: GLuint, uniform: GL_Shader_Uniform_Variable, x: s32, y: s32) {
    gl_vuc := get_configuration(uniform);
    uniform_location := glGetUniformLocation(shader_program_gl_handle, temp_c_string(gl_vuc.var_name_in_shader));
    glUniform2i(uniform_location, x, y);
}

set_uniform :: (shader_program_gl_handle: GLuint, uniform: GL_Shader_Uniform_Variable, x: s32, y: s32, z: s32) {
    gl_vuc := get_configuration(uniform);
    uniform_location := glGetUniformLocation(shader_program_gl_handle, temp_c_string(gl_vuc.var_name_in_shader));
    glUniform3i(uniform_location, x, y, z);
}

set_uniform :: (shader_program_gl_handle: GLuint, uniform: GL_Shader_Uniform_Variable, x: s32, y: s32, z: s32, w: s32) {
    gl_vuc := get_configuration(uniform);
    uniform_location := glGetUniformLocation(shader_program_gl_handle, temp_c_string(gl_vuc.var_name_in_shader));
    glUniform4i(uniform_location, x, y, z, w);
}

GL_Vertex_Uniform_Configuration :: struct { // (i don't give a) gl_vuc 

    type_in_jai: Type;

    var_name_in_shader : string;

    // plural_name : string; don't think I need this for uniforms??
}


// this defines the allowed attribute variables that our shaders can have.
// note that we don't specify the in's of the fragment shader here.
GL_Shader_Vertex_Attribute_Variable :: enum u32 { // gl_sav
    POSITION;
    NORMAL;
    LOCAL_TO_WORLD_INDEX;

    // common passthroughs for fragment shader
    PASSTHROUGH_RGB_COLOR;
    PASSTHROUGH_RGBA_COLOR;
    PASSTHROUGH_NORMAL;
    PASSTHROUGH_TANGENT;

    // for 3d picking
    PASSTHROUGH_OBJECT_ID;

    // used for texture packing
    PASSTHROUGH_PACKED_TEXTURE_INDEX;
    PASSTHROUGH_PACKED_TEXTURE_INDEX_0;
    PASSTHROUGH_PACKED_TEXTURE_INDEX_1;

    PASSTHROUGH_PACKED_TEXTURE_BOUNDING_BOX_INDEX;
    PASSTHROUGH_PACKED_TEXTURE_BOUNDING_BOX_INDEX_0;
    PASSTHROUGH_PACKED_TEXTURE_BOUNDING_BOX_INDEX_1;


    // multi-channel texture coordinates (for things like light mapping etc)
    PASSTHROUGH_TEXTURE_COORDINATE;
    PASSTHROUGH_TEXTURE_COORDINATE_0;
    PASSTHROUGH_TEXTURE_COORDINATE_1;


    // texture packing with pbr, note that metallic and roughness are combined because we can do that to remove one texture from gpu memory
    PASSTHROUGH_PACKED_TEXTURE_INDEX_FOR_BASE_COLOR;
    PASSTHROUGH_PACKED_TEXTURE_INDEX_FOR_NORMAL;
    PASSTHROUGH_PACKED_TEXTURE_INDEX_FOR_METALLIC_ROUGHNESS;
    PASSTHROUGH_PACKED_TEXTURE_INDEX_FOR_AMBIENT_OCCLUSION;

    PASSTHROUGH_PACKED_TEXTURE_BOUNDING_BOX_INDEX_FOR_BASE_COLOR;
    PASSTHROUGH_PACKED_TEXTURE_BOUNDING_BOX_INDEX_FOR_NORMAL;
    PASSTHROUGH_PACKED_TEXTURE_BOUNDING_BOX_INDEX_FOR_METALLIC_ROUGHNESS;
    PASSTHROUGH_PACKED_TEXTURE_BOUNDING_BOX_INDEX_FOR_AMBIENT_OCCLUSION;

    
}

GL_Shader_Uniform_Variable :: enum u32 { // gl_suv
    // things with a camera
    WORLD_TO_CAMERA;
    CAMERA_TO_CLIP;

    TRANSFORM;

    // color the entire scene or an object a solid color
    // note that this already exists as a passthrough vertex attribute
    // and once passed through it becomes "rgb_color" in the fragment shader 
    // this would be a name collision with this uniform, except for the fact that you usually don't need
    // a uniform color if you're doing a passthrough color.
    RGB_COLOR;
    RGBA_COLOR;

    // use for the infinite grid shader
    GRID_SIZE;
    GRID_PLANE;

    // when you're rendering things with points
    POINT_SIZE;

    // used in borders
    BORDER_THICKNESS;

    // used in 2d situations sometimes
    ASPECT_RATIO;


    // used for texture packing
    PACKED_TEXTURES;
    PACKED_TEXTURE_BOUNDING_BOXES;

    // used when doing object wise things (ie object borders)
    OBJECT_ID_TEXTURE;

    SELECTED_OBJECT_ID;
    THICKNESS_PX;

    // used in deferred rendering
    POSITION_TEXTURE;
    COLOR_TEXTURE;
    NORMAL_TEXTURE;

    // generic thing for doing a texture
    TEXTURE_SAMPLER;

    CAMERA_POSITION; // common in lighting situations
    LIGHTS;

    // used in forward lighting situations to not iterate over all lights when possible
    NUM_ACTIVE_LIGHTS;

    // default values for things rendered with pbr that are missing a texture
    DEFAULT_BASE_COLOR;
    DEFAULT_METALLIC;
    DEFAULT_ROUGHNESS;
    DEFAULT_AMBIENT_OCCLUSION;
}

// good god, we need to automate this away soon, but it's working for now because we only add one shader at a time, but this has really exploded hasn't it.
get_configuration :: (attr: GL_Shader_Vertex_Attribute_Variable) -> GL_Vertex_Attribute_Configuration {
    if #complete attr == {
        case .POSITION;
            return .{
                type_in_jai                     = Vector3,
                var_name_in_shader              = "position",
                plural_name                     = "positions",
                argument_name_in_buffer_object  = "positions",
                constant_across_object          = false,
                components_per_vertex           = 3,
                data_type_of_component          = GL_FLOAT,
                normalize                       = GL_FALSE,
                stride                          = 0,
                pointer_offset_to_start_of_data = null,
            };
        case .NORMAL;
            return .{
                type_in_jai                     = Vector3,
                var_name_in_shader              = "normal",
                plural_name                     = "normals",
                argument_name_in_buffer_object  = "normals",
                constant_across_object          = false,
                components_per_vertex           = 3,
                data_type_of_component          = GL_FLOAT,
                normalize                       = GL_FALSE,
                stride                          = 0,
                pointer_offset_to_start_of_data = null,
            };
        case .PASSTHROUGH_RGB_COLOR;
            return .{
                type_in_jai                     = Vector3,
                var_name_in_shader              = "passthrough_rgb_color",
                plural_name                     = "passthrough_rgb_colors",
                argument_name_in_buffer_object  = "rgb_colors",
                constant_across_object          = false,
                components_per_vertex           = 3,
                data_type_of_component          = GL_FLOAT,
                normalize                       = GL_FALSE,
                stride                          = 0,
                pointer_offset_to_start_of_data = null,
                passthrough              = true,
            };
        case .PASSTHROUGH_RGBA_COLOR;
            return .{
                type_in_jai                     = Vector4,
                var_name_in_shader              = "passthrough_rgba_color",
                plural_name                     = "passthrough_rgba_colors",
                argument_name_in_buffer_object  = "rgba_colors",
                constant_across_object          = false,
                components_per_vertex           = 4,
                data_type_of_component          = GL_FLOAT,
                normalize                       = GL_FALSE,
                stride                          = 0,
                pointer_offset_to_start_of_data = null,
                passthrough              = true,
            };
        case .PASSTHROUGH_NORMAL;
            return .{
                type_in_jai                     = Vector3,
                var_name_in_shader              = "passthrough_normal",
                plural_name                     = "passthrough_normals",
                argument_name_in_buffer_object  = "normals",
                constant_across_object          = false,
                components_per_vertex           = 3,
                data_type_of_component          = GL_FLOAT,
                normalize                       = GL_FALSE,
                stride                          = 0,
                pointer_offset_to_start_of_data = null,
                passthrough              = true,
            };
        case .PASSTHROUGH_TANGENT;
            return .{
                type_in_jai                     = Vector3,
                var_name_in_shader              = "passthrough_tangent",
                plural_name                     = "passthrough_tangents",
                argument_name_in_buffer_object  = "tangents",
                constant_across_object          = false,
                components_per_vertex           = 3,
                data_type_of_component          = GL_FLOAT,
                normalize                       = GL_FALSE,
                stride                          = 0,
                pointer_offset_to_start_of_data = null,
                passthrough                     = true,
            };
        case .PASSTHROUGH_OBJECT_ID;
            return .{
                type_in_jai                     = u32,
                var_name_in_shader              = "passthrough_object_id",
                plural_name                     = "passthrough_object_ids",
                argument_name_in_buffer_object  = "object_ids",
                constant_across_object          = true,
                components_per_vertex           = 1,
                data_type_of_component          = GL_UNSIGNED_INT,
                normalize                       = GL_FALSE,
                stride                          = 0,
                pointer_offset_to_start_of_data = null,
                passthrough              = true,
            };
        case .LOCAL_TO_WORLD_INDEX;
            return .{
                type_in_jai                     = u32,
                var_name_in_shader              = "local_to_world_index",
                plural_name                     = "local_to_world_indices",
                argument_name_in_buffer_object  = "local_to_world_index",
                constant_across_object          = true,
                components_per_vertex           = 1,
                data_type_of_component          = GL_UNSIGNED_INT,
                normalize                       = GL_FALSE,
                stride                          = 0,
                pointer_offset_to_start_of_data = null,
            };
        case .PASSTHROUGH_PACKED_TEXTURE_INDEX;
            return .{
                type_in_jai                     = s32,
                var_name_in_shader              = "passthrough_packed_texture_index",
                plural_name                     = "passthrough_packed_texture_indices",
                argument_name_in_buffer_object  = "packed_texture_index",
                constant_across_object          = true,
                components_per_vertex           = 1,
                data_type_of_component          = GL_INT,
                normalize                       = GL_FALSE,
                stride                          = 0,
                pointer_offset_to_start_of_data = null,
            };
        case .PASSTHROUGH_PACKED_TEXTURE_INDEX_0;
            return .{
                type_in_jai                     = s32,
                var_name_in_shader              = "passthrough_packed_texture_index_0",
                plural_name                     = "passthrough_packed_texture_indices_0",
                argument_name_in_buffer_object  = "packed_texture_index_0",
                constant_across_object          = true,
                components_per_vertex           = 1,
                data_type_of_component          = GL_INT,
                normalize                       = GL_FALSE,
                stride                          = 0,
                pointer_offset_to_start_of_data = null,
            };
        case .PASSTHROUGH_PACKED_TEXTURE_INDEX_1;
            return .{
                type_in_jai                     = s32,
                var_name_in_shader              = "passthrough_packed_texture_index_1",
                plural_name                     = "passthrough_packed_texture_indices_1",
                argument_name_in_buffer_object  = "packed_texture_index_1",
                constant_across_object          = true,
                components_per_vertex           = 1,
                data_type_of_component          = GL_INT,
                normalize                       = GL_FALSE,
                stride                          = 0,
                pointer_offset_to_start_of_data = null,
            };
        case .PASSTHROUGH_TEXTURE_COORDINATE;
            return .{
                type_in_jai                     = Vector2,
                var_name_in_shader              = "passthrough_texture_coordinate",
                plural_name                     = "passthrough_texture_coordinates",
                argument_name_in_buffer_object  = "texture_coordinates",
                constant_across_object          = false,
                components_per_vertex           = 2,
                data_type_of_component          = GL_FLOAT,
                normalize                       = GL_FALSE,
                stride                          = 0,
                pointer_offset_to_start_of_data = null,
            };
        case .PASSTHROUGH_TEXTURE_COORDINATE_0;
            return .{
                type_in_jai                     = Vector2,
                var_name_in_shader              = "passthrough_texture_coordinate_0",
                plural_name                     = "passthrough_texture_coordinates_0",
                argument_name_in_buffer_object  = "texture_coordinates_0",
                constant_across_object          = false,
                components_per_vertex           = 2,
                data_type_of_component          = GL_FLOAT,
                normalize                       = GL_FALSE,
                stride                          = 0,
                pointer_offset_to_start_of_data = null,
            };
        case .PASSTHROUGH_TEXTURE_COORDINATE_1;
            return .{
                type_in_jai                     = Vector2,
                var_name_in_shader              = "passthrough_texture_coordinate_1",
                plural_name                     = "passthrough_texture_coordinates_1",
                argument_name_in_buffer_object  = "texture_coordinates_1",
                constant_across_object          = false,
                components_per_vertex           = 2,
                data_type_of_component          = GL_FLOAT,
                normalize                       = GL_FALSE,
                stride                          = 0,
                pointer_offset_to_start_of_data = null,
            };
        case .PASSTHROUGH_PACKED_TEXTURE_BOUNDING_BOX_INDEX;
            return .{
                type_in_jai                     = s32,
                var_name_in_shader              = "passthrough_packed_texture_bounding_box_index",
                plural_name                     = "passthrough_packed_texture_bounding_box_indices",
                argument_name_in_buffer_object  = "packed_texture_bounding_box_index",
                constant_across_object          = true,
                components_per_vertex           = 1,
                data_type_of_component          = GL_INT,
                normalize                       = GL_FALSE,
                stride                          = 0,
                pointer_offset_to_start_of_data = null,
            };
        case .PASSTHROUGH_PACKED_TEXTURE_BOUNDING_BOX_INDEX_0;
            return .{
                type_in_jai                     = s32,
                var_name_in_shader              = "passthrough_packed_texture_bounding_box_index_0",
                plural_name                     = "passthrough_packed_texture_bounding_box_indices_0",
                argument_name_in_buffer_object  = "packed_texture_bounding_box_index_0",
                constant_across_object          = true,
                components_per_vertex           = 1,
                data_type_of_component          = GL_INT,
                normalize                       = GL_FALSE,
                stride                          = 0,
                pointer_offset_to_start_of_data = null,
            };
        case .PASSTHROUGH_PACKED_TEXTURE_BOUNDING_BOX_INDEX_1;
            return .{
                type_in_jai                     = s32,
                var_name_in_shader              = "passthrough_packed_texture_bounding_box_index_1",
                plural_name                     = "passthrough_packed_texture_bounding_box_indices_1",
                argument_name_in_buffer_object  = "packed_texture_bounding_box_index_1",
                constant_across_object          = true,
                components_per_vertex           = 1,
                data_type_of_component          = GL_INT,
                normalize                       = GL_FALSE,
                stride                          = 0,
                pointer_offset_to_start_of_data = null,
            };

    case .PASSTHROUGH_PACKED_TEXTURE_INDEX_FOR_BASE_COLOR;
        return .{
            type_in_jai                     = s32,
            var_name_in_shader              = "passthrough_packed_texture_index_for_base_color",
            plural_name                     = "passthrough_packed_texture_indices_for_base_color",
            argument_name_in_buffer_object  = "packed_texture_index_for_base_color",
            constant_across_object          = true,
            components_per_vertex           = 1,
            data_type_of_component          = GL_INT,
            normalize                       = GL_FALSE,
            stride                          = 0,
            pointer_offset_to_start_of_data = null,
            passthrough                     = true,
        };

    case .PASSTHROUGH_PACKED_TEXTURE_INDEX_FOR_NORMAL;
        return .{
            type_in_jai                     = s32,
            var_name_in_shader              = "passthrough_packed_texture_index_for_normal",
            plural_name                     = "passthrough_packed_texture_indices_for_normal",
            argument_name_in_buffer_object  = "packed_texture_index_for_normal",
            constant_across_object          = true,
            components_per_vertex           = 1,
            data_type_of_component          = GL_INT,
            normalize                       = GL_FALSE,
            stride                          = 0,
            pointer_offset_to_start_of_data = null,
            passthrough                     = true,
        };

    case .PASSTHROUGH_PACKED_TEXTURE_INDEX_FOR_METALLIC_ROUGHNESS;
        return .{
            type_in_jai                     = s32,
            var_name_in_shader              = "passthrough_packed_texture_index_for_metallic_roughness",
            plural_name                     = "passthrough_packed_texture_indices_for_metallic_roughness",
            argument_name_in_buffer_object  = "packed_texture_index_for_metallic_roughness",
            constant_across_object          = true,
            components_per_vertex           = 1,
            data_type_of_component          = GL_INT,
            normalize                       = GL_FALSE,
            stride                          = 0,
            pointer_offset_to_start_of_data = null,
            passthrough                     = true,
        };

    case .PASSTHROUGH_PACKED_TEXTURE_INDEX_FOR_AMBIENT_OCCLUSION;
        return .{
            type_in_jai                     = s32,
            var_name_in_shader              = "passthrough_packed_texture_index_for_ambient_occlusion",
            plural_name                     = "passthrough_packed_texture_indices_for_ambient_occlusion",
            argument_name_in_buffer_object  = "packed_texture_index_for_ambient_occlusion",
            constant_across_object          = true,
            components_per_vertex           = 1,
            data_type_of_component          = GL_INT,
            normalize                       = GL_FALSE,
            stride                          = 0,
            pointer_offset_to_start_of_data = null,
            passthrough                     = true,
        };

    case .PASSTHROUGH_PACKED_TEXTURE_BOUNDING_BOX_INDEX_FOR_BASE_COLOR;
        return .{
            type_in_jai                     = s32,
            var_name_in_shader              = "passthrough_packed_texture_bounding_box_index_for_base_color",
            plural_name                     = "passthrough_packed_texture_bounding_box_indices_for_base_color",
            argument_name_in_buffer_object  = "packed_texture_bounding_box_index_for_base_color",
            constant_across_object          = true,
            components_per_vertex           = 1,
            data_type_of_component          = GL_INT,
            normalize                       = GL_FALSE,
            stride                          = 0,
            pointer_offset_to_start_of_data = null,
            passthrough                     = true,
        };

    case .PASSTHROUGH_PACKED_TEXTURE_BOUNDING_BOX_INDEX_FOR_NORMAL;
        return .{
            type_in_jai                     = s32,
            var_name_in_shader              = "passthrough_packed_texture_bounding_box_index_for_normal",
            plural_name                     = "passthrough_packed_texture_bounding_box_indices_for_normal",
            argument_name_in_buffer_object  = "packed_texture_bounding_box_index_for_normal",
            constant_across_object          = true,
            components_per_vertex           = 1,
            data_type_of_component          = GL_INT,
            normalize                       = GL_FALSE,
            stride                          = 0,
            pointer_offset_to_start_of_data = null,
            passthrough                     = true,
        };

    case .PASSTHROUGH_PACKED_TEXTURE_BOUNDING_BOX_INDEX_FOR_METALLIC_ROUGHNESS;
        return .{
            type_in_jai                     = s32,
            var_name_in_shader              = "passthrough_packed_texture_bounding_box_index_for_metallic_roughness",
            plural_name                     = "passthrough_packed_texture_bounding_box_indices_for_metallic_roughness",
            argument_name_in_buffer_object  = "packed_texture_bounding_box_index_for_metallic_roughness",
            constant_across_object          = true,
            components_per_vertex           = 1,
            data_type_of_component          = GL_INT,
            normalize                       = GL_FALSE,
            stride                          = 0,
            pointer_offset_to_start_of_data = null,
            passthrough                     = true,
        };

    case .PASSTHROUGH_PACKED_TEXTURE_BOUNDING_BOX_INDEX_FOR_AMBIENT_OCCLUSION;
        return .{
            type_in_jai                     = s32,
            var_name_in_shader              = "passthrough_packed_texture_bounding_box_index_for_ambient_occlusion",
            plural_name                     = "passthrough_packed_texture_bounding_box_indices_for_ambient_occlusion",
            argument_name_in_buffer_object  = "packed_texture_bounding_box_index_for_ambient_occlusion",
            constant_across_object          = true,
            components_per_vertex           = 1,
            data_type_of_component          = GL_INT,
            normalize                       = GL_FALSE,
            stride                          = 0,
            pointer_offset_to_start_of_data = null,
            passthrough                     = true,
        };
    }
}

get_configuration :: (uniform: GL_Shader_Uniform_Variable) -> GL_Vertex_Uniform_Configuration {
    if #complete uniform == {
        case .WORLD_TO_CAMERA;
            return .{ type_in_jai = Matrix4, var_name_in_shader = "world_to_camera" };
        case .CAMERA_TO_CLIP;
            return .{ type_in_jai = Matrix4, var_name_in_shader = "camera_to_clip" };
        case .TRANSFORM;
            return .{ type_in_jai = Matrix4, var_name_in_shader = "transform" };
        case .RGB_COLOR;
            return .{ type_in_jai = Vector3, var_name_in_shader = "rgb_color" };
        case .RGBA_COLOR;
            return .{ type_in_jai = Vector4, var_name_in_shader = "rgba_color" };
        case .GRID_SIZE;
            return .{ type_in_jai = float32, var_name_in_shader = "grid_size" };
        case .GRID_PLANE;
            return .{ type_in_jai = s32, var_name_in_shader = "grid_plane" };
        case .POINT_SIZE;
            return .{ type_in_jai = float32, var_name_in_shader = "point_size" };
        case .BORDER_THICKNESS;
            return .{ type_in_jai = float32, var_name_in_shader = "border_thickness" };
        case .PACKED_TEXTURES;
            return .{ type_in_jai = s32, var_name_in_shader = "packed_textures" };
        case .PACKED_TEXTURE_BOUNDING_BOXES;
            return .{ type_in_jai = s32, var_name_in_shader = "packed_texture_bounding_boxes" };
        case .ASPECT_RATIO;
            return .{ type_in_jai = Vector2, var_name_in_shader = "aspect_ratio" };
        case .OBJECT_ID_TEXTURE;
            return .{ type_in_jai = s32, var_name_in_shader = "object_id_texture" };

        case .SELECTED_OBJECT_ID;
            return .{ type_in_jai = u32, var_name_in_shader = "selected_object_id" };

        case .THICKNESS_PX;
            return .{ type_in_jai = u32, var_name_in_shader = "thickness_px" };


        case .POSITION_TEXTURE;
            return .{ type_in_jai = s32, var_name_in_shader = "position_texture" };
        case .COLOR_TEXTURE;
            return .{ type_in_jai = s32, var_name_in_shader = "color_texture" };
        case .NORMAL_TEXTURE;
            return .{ type_in_jai = s32, var_name_in_shader = "normal_texture" };

        case .TEXTURE_SAMPLER;
            return .{ type_in_jai = s32, var_name_in_shader = "texture_sampler" };

        case .CAMERA_POSITION;
            return .{ type_in_jai = Vector3, var_name_in_shader = "camera_position" };
        case .LIGHTS;
            // todo the type is a list of lights or something.
            return .{ type_in_jai = int, var_name_in_shader = "camera_position" };

        case .NUM_ACTIVE_LIGHTS;
            return .{ type_in_jai = s32, var_name_in_shader = "num_active_lights" };
        case .DEFAULT_BASE_COLOR;
            return .{ type_in_jai = Vector3, var_name_in_shader = "default_base_color" };
        case .DEFAULT_METALLIC;
            return .{ type_in_jai = float32, var_name_in_shader = "default_metallic" };
        case .DEFAULT_ROUGHNESS;
            return .{ type_in_jai = float32, var_name_in_shader = "default_roughness" };
        case .DEFAULT_AMBIENT_OCCLUSION;
            return .{ type_in_jai = float32, var_name_in_shader = "default_ambient_occlusion" };


    }
}

generate_code_for_uniform_setter_function :: (shader : Shader_Metadata, uniform : GL_Shader_Uniform_Variable) -> string {
    unif_conf := get_configuration(uniform);
    lower_name := to_lower_copy(tprint("%", uniform));
    
    // Determine the right glUniform call based on type
    gl_call: string;
    args: string;
    if unif_conf.type_in_jai == {
        case Matrix4;
            gl_call = "glUniformMatrix4fv";
            args = "renderer.%1_uniform_location, 1, GL_TRUE, *v.coef[0][0]";
        case Matrix3;
            gl_call = "glUniformMatrix3fv";
            args = "renderer.%1_uniform_location, 1, GL_TRUE, *v.coef[0][0]";
        case Vector4;
            gl_call = "glUniform4f";
            args = "renderer.%1_uniform_location, v.x, v.y, v.z, v.w";
        case Vector3;
            gl_call = "glUniform3f";
            args = "renderer.%1_uniform_location, v.x, v.y, v.z";
        case Vector2;
            gl_call = "glUniform2f";
            args = "renderer.%1_uniform_location, v.x, v.y";
        case float32;
            gl_call = "glUniform1f";
            args = "renderer.%1_uniform_location, v";
        case s32;
            gl_call = "glUniform1i";
            args = "renderer.%1_uniform_location, v";
        case u32;
            gl_call = "glUniform1ui";
            args = "renderer.%1_uniform_location, v";
        case;
            gl_call = "glUniform1i";
            args = "renderer.%1_uniform_location, v";
    }
    
    // replace %1 in args with the actual lower_name
    resolved_args := tprint(args, lower_name);
    
    return tprint(#string END

set_%1_uniform :: (renderer : *%2, v: %3) {
    %4(%5);
}
    END, 
    lower_name,
    get_renderer_struct_name(shader), 
    unif_conf.type_in_jai, 
    gl_call,
    resolved_args
    );
}

generate_code_for_uniform_setter_functions :: (shader : Shader_Metadata) -> string {
    push_allocator(temp);
    builder : String_Builder;

    for shader.uniforms {
        print_to_builder(*builder, generate_code_for_uniform_setter_function(shader, it));
    }
    return builder_to_string(*builder); 
}


init_vertex_attribute :: (
        shader_program_gl_handle : GLuint, 
        vertex_attribute_array_gl_handle: GLuint, 
        attribute_buffer_gl_handle: GLuint, 
        attribute: GL_Shader_Vertex_Attribute_Variable
    ) {

    using glvac := get_configuration(attribute);

    glBindVertexArray(vertex_attribute_array_gl_handle);
    glBindBuffer(GL_ARRAY_BUFFER, attribute_buffer_gl_handle);

    log("%", var_name_in_shader);
    vertex_attribute_gl_handle : s32 = glGetAttribLocation(shader_program_gl_handle, temp_c_string(var_name_in_shader));

    glEnableVertexAttribArray(xx vertex_attribute_gl_handle);

    // todo: there are probably more integer types right?
    data_type_is_integer : bool = data_type_of_component == GL_INT || data_type_of_component == GL_UNSIGNED_INT;

    if (data_type_is_integer) { 
        // doesn't take in the normalize value.
        glVertexAttribIPointer(xx vertex_attribute_gl_handle, components_per_vertex, data_type_of_component, stride, pointer_offset_to_start_of_data);
    } else {
        glVertexAttribPointer(xx vertex_attribute_gl_handle, components_per_vertex, data_type_of_component, normalize, stride, pointer_offset_to_start_of_data);
    }

    glBindVertexArray(0);
}

#load "per_shader_renderer.jai";
