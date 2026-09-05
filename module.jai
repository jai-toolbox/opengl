/*

So I'm starting to see a higher level pattern appear here, which is good. Some visual representations of objects will require multiple shaders, for example a shader which does draws a border/outline on an object, then there might be a wireframe version (say you're in an editor) and then there might be the entirely lit object.

So I'm not entirely sure yet if it's best to create a "super shader" that does all these things at once. But the ability to combine into a multi-shader renderable seems like a logical solution without having to manually create these super shaders. A multishader renderable holds all the unique data inside, so for example if we have a shader that needs positions, texture coordinates and another that needs positions, normals, the multi-shader renderable becomes positions, texture coordinates, normals (the union of all the attributes, and there are no problems because we used metaprogramming to enforce unique attribute names).

Then for the multi-shader renderable there is also a buffer object / queue render like in all other systems, though it starts to get more complicated when each shader requires different parameters like depth test off or something to render properly, but in general this seems like the right direction. The name of these renderables probably starts getting too long so at this point it's probably best to name it shorter...


*/

#import "GL";
#import "Basic";
#import "Math";

#import,file "first_fit_virtual_allocator.jai";

#import "Hash_Table";
#import "tbx/assets";

#load "renderer_generation_per_shader.jai";
#load "reflection_probe_resources.jai";

// opengl's coordinate system is only NDC space, everything else is something that you make up
// and ndc space we have the following, the misconception can be understood here:
// https://www.gingerbill.org/article/2024/11/10/opengl-is-not-right-handed/
// in the future it'd be interesting to have a way to re-map things, which would occur at the shader level so that there isn't an associated runtime cost of flipping things.
GL_FORWARD_VEC :: Vector3.{0, 0, 1};
GL_RIGHT_VEC :: Vector3.{1, 0, 0};
GL_UP_VEC :: Vector3.{0, 1, 0};

enable_wireframe_mode :: () { glPolygonMode(GL_FRONT_AND_BACK, GL_LINE); }
disable_wireframe_mode :: () { glPolygonMode(GL_FRONT_AND_BACK, GL_FILL); }

// SHADER_PREFIX : string : "#version 330 core";
SHADER_PREFIX : string : "";

/*

Something important to realize about this is what a local_to_world_index is and how that is different from a object index.

A local to world index, is the index which maps into the local to world matrices which tells the renderer where this object should be in space.

The object index a number which represents where we can put this object in the gpu's buffer where there is enough space to fit all the data in.

Because we do SoA style buffers for each attribute, each buffer is just a scaled version of the other depending on the size of the individual elements stored in the buffer. (buffer is just an array of a particular attribute)

Now we can understand the difference between this and the local to world index.

If you were to buffer an object that has 8 vertices, then in each SoA buffer, we would do "virtual allocation" to find a place we can store it, and at the start
that will be index 0, and we'll take up 8 of the elements in the array. We can assign this object the local_to_world index of 0 as well. 

When we create the second object, then now its object_index is going to be 8, because that was the next space in the buffer where we can put the object. 
But we can still assign this object the local to world index of 1, because the local to world index is the same along every vertex of the object. 

This means that the local_to_world index can just be the number of objects you've created up until this point (not thinking about removals or anything).

*/

// these files needs to be generated first... need a way to do that smartly, what if they always just exist...
// also loading everything is becoming more and more bad, can we not just do a module or something?
#load "renderers/absolute_position_color_renderer.jai";
#load "renderers/absolute_position_color_alpha_renderer.jai";
#load "renderers/transform_position_color_alpha_renderer.jai";
#load "renderers/camera_per_object_transform_color_renderer.jai";
#load "renderers/camera_per_object_transform_color_skeletal_animation_renderer.jai";
#load "renderers/camera_per_object_transform_color_alpha_renderer.jai";
#load "renderers/camera_infinite_grid_renderer.jai";
#load "renderers/object_id_selection_outline_renderer.jai";
#load "renderers/camera_per_object_transform_position_point_color_renderer.jai";
#load "renderers/multi_channel_signed_distance_field_text_renderer.jai";
#load "renderers/transform_msdf_text_renderer.jai";
#load "renderers/camera_per_object_transform_normal_border_renderer.jai";
#load "renderers/camera_per_object_transform_object_id_renderer.jai";
#load "renderers/camera_per_object_transform_deferred_lighting_geometry_pass_renderer.jai";
#load "renderers/camera_per_object_transform_deferred_lighting_compute_light_pass_renderer.jai";
#load "renderers/camera_per_object_transforms_packed_texture_renderer.jai"; // bad plural on transforms
#load "renderers/camera_per_object_transform_packed_texture_2_channel_renderer.jai";
#load "renderers/camera_per_object_transform_pbr_packed_texture_renderer.jai";
#load "renderers/camera_absolute_position_color_renderer.jai";
#load "renderers/gpu_style_vertex_color_renderer.jai";
#load "renderers/gpu_style_blinn_phong_renderer.jai";
#load "renderers/gpu_style_pbr_renderer.jai";
#load "renderers/gpu_style_pbr_lightmapped_renderer.jai";
#load "renderers/gpu_style_pbr_directional_shadows_renderer.jai";
#load "renderers/gpu_style_pbr_directional_shadow_depth_renderer.jai";
#load "renderers/gpu_style_pbr_skeletal_animation_renderer.jai";
#load "renderers/gpu_style_pbr_directional_shadows_skeletal_animation_renderer.jai";
#load "renderers/gpu_style_pbr_directional_shadow_depth_skeletal_animation_renderer.jai";

// #load "deferred_lighting.jai";
#load "camera_infinite_grid.jai";
#load "local_to_world_matrix_pool.jai";
#load "skybox.jai";
#load "hdr_post_process.jai";

#if OS == .LINUX {
    X11 :: #import "X11";

    _libGL :: #library,system "libGL";
    glXGetCurrentDrawable :: () -> X11.GLXDrawable #foreign _libGL;
}


check_compile_errors :: (shader : GLuint) -> success: bool, info_log : string {
    success : s32;
    glGetShaderiv (shader, GL_COMPILE_STATUS, *success);
    if !success {
        info_len : s32;
        glGetShaderiv (shader, GL_INFO_LOG_LENGTH, *info_len);
        info_data := cast (*u8) alloc (info_len,, temp);
        glGetShaderInfoLog (shader, xx info_len, xx *info_len, info_data);
        result : string;
        result.data = info_data;
        result.count = info_len;

        return false, result;
    }

    return true, "";
}

check_link_errors :: (program : GLuint) -> success: bool, info_log : string {
    success : s32;
    glGetProgramiv (program, GL_LINK_STATUS, *success);
    if !success {
        info_len : s32;
        glGetProgramiv (program, GL_INFO_LOG_LENGTH, *info_len);
        info_data := cast (*u8) alloc (info_len,, temp);
        glGetProgramInfoLog (program, xx info_len, xx *info_len, info_data);
        result : string;
        result.data = info_data;
        result.count = info_len;

        return false, result;
    }

    return true, "";
}

create_shader_program :: (vertex_source : string, fragment_source : string) -> program_handle: GLuint, success: bool {
    // in order to operate opengl you pretty much have to understand the entire rendering pipeline for rasterization on the gpu at a high level
	// OpenGL requires us to create at least a vertex shader and a
	// fragment shader, to create a shader program that it can execute.

	vertex_shader_handle := glCreateShader (GL_VERTEX_SHADER);
	defer glDeleteShader (vertex_shader_handle);

    shaders := *u8.[   SHADER_PREFIX.data ,    vertex_source.data ];
    lengths := s32.[xx SHADER_PREFIX.count, xx vertex_source.count];
	glShaderSource (vertex_shader_handle, 2, shaders.data, lengths.data);
	glCompileShader (vertex_shader_handle);
	ok, info_log := check_compile_errors (vertex_shader_handle);
	if !ok {
		log_error("Could not compile vertex shader %", info_log);
		return 0, false;
	}

	fragment_shader_handle := glCreateShader (GL_FRAGMENT_SHADER);
	defer glDeleteShader (fragment_shader_handle);
	shaders[1] =    fragment_source.data;
	lengths[1] = xx fragment_source.count;
	glShaderSource (fragment_shader_handle, 2, shaders.data, lengths.data);
	glCompileShader (fragment_shader_handle);

	ok, info_log = check_compile_errors (fragment_shader_handle);
	if !ok {
		log_error ("Could not compile fragment shader: %", info_log);
		return 0, false;
	}

	result := glCreateProgram ();
	glAttachShader(result, vertex_shader_handle);
	glAttachShader(result, fragment_shader_handle);

	glLinkProgram(result);
	ok, info_log = check_link_errors (result);

	if !ok {
		log_error ("Could not link shader program: %", info_log);
		glDeleteProgram (result);
		return 0, false;
	}

	return result, true;
}

set_vsync :: (value : bool) {
	#if OS == .WINDOWS {
        wglSwapIntervalEXT(xx ifx value then 1 else 0);
    } else #if OS == .LINUX {
        interval := cast(s32) ifx value then 1 else 0;

        display := X11.x_global_display;
        drawable := glXGetCurrentDrawable();
        if display != null && drawable != 0 && glXSwapIntervalEXT != null {
            glXSwapIntervalEXT(display, drawable, interval);
            return;
        }

        if glXSwapIntervalMESA != null {
            glXSwapIntervalMESA(interval);
            return;
        }

        if glXSwapIntervalSGI != null {
            glXSwapIntervalSGI(interval);
            return;
        }
    }
}
