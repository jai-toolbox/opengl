// auto-generated renderer for shader: Animated_Mesh_Display
// do not edit manually.

Animated_Mesh_Display_Animated_Mesh_Display_Uniforms_Bindings :: struct {
    image: GLuint;
    exposure: float32;
    tone_map: bool;
}

Animated_Mesh_Display_Renderer :: struct {
    shader_program_gl_handle : GLuint;
    vertex_attribute_array_gl_handle : GLuint;
    typed_0_uniform_location : GLint = -1;
    typed_1_uniform_location : GLint = -1;
    typed_2_uniform_location : GLint = -1;
}

set_uniforms :: (renderer: *Animated_Mesh_Display_Renderer, ctx: Animated_Mesh_Display_Animated_Mesh_Display_Uniforms_Bindings) {
    gl_set_active_shader_program(renderer.shader_program_gl_handle);
    gl_set_active_texture_unit(GL_TEXTURE0 + 0);
    gl_bind_texture_to_binding_target_of_active_texture_unit(GL_TEXTURE_2D,ctx.image);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_0_uniform_location,0);
    gl_set_uniform_1f_on_active_shader_program(renderer.typed_1_uniform_location, ctx.exposure);
    gl_set_uniform_1i_on_active_shader_program(renderer.typed_2_uniform_location, xx ctx.tone_map);
    gl_set_active_texture_unit(GL_TEXTURE0);
    gl_clear_active_shader_program();
}

init :: (using renderer : *Animated_Mesh_Display_Renderer) -> bool {
    success : bool;
    shader_program_gl_handle, success = create_shader_program(Animated_Mesh_Display_Vertex_Source, Animated_Mesh_Display_Fragment_Source);
    if !success return false;
    // OpenGL core profile requires a bound VAO even when the vertex shader uses
    // gl_VertexID and supplies every vertex itself. This VAO has no buffers.
    vertex_attribute_array_gl_handle = gl_create_vertex_array();
    typed_0_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "image");
    typed_1_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "exposure");
    typed_2_uniform_location = gl_get_uniform_location_in_shader_program(shader_program_gl_handle, "tone_map");

    return true;
}

deinit :: (renderer : *Animated_Mesh_Display_Renderer) {
    gl_delete_vertex_array(renderer.vertex_attribute_array_gl_handle);
    gl_delete_shader_program(renderer.shader_program_gl_handle);
    renderer.* = .{};
}
render :: (renderer : *Animated_Mesh_Display_Renderer, vertex_count : GLsizei = 3) {
    assert(vertex_count >= 0);
    gl_set_active_shader_program(renderer.shader_program_gl_handle);
    gl_bind_vertex_array(renderer.vertex_attribute_array_gl_handle);
    gl_draw_vertices_from_bound_vertex_array(GL_TRIANGLES, 0, vertex_count);
    gl_bind_vertex_array(0);
    gl_clear_active_shader_program();
}

Animated_Mesh_Display_Vertex_Source :: #string END_Animated_Mesh_Display_Vertex_Source
#version 330 core
// Generated from Jai procedure fullscreen_vertex_shader.
out vec2 passthrough_uv;

void main() {
    vec2 p = vec2(float(((gl_VertexID << 1) & 2)), float((gl_VertexID & 2)));
    gl_Position = vec4(((p.x * 2.0) - 1.0), ((p.y * 2.0) - 1.0), 0.0, 1.0);
    passthrough_uv = p;
}

END_Animated_Mesh_Display_Vertex_Source

Animated_Mesh_Display_Fragment_Source :: #string END_Animated_Mesh_Display_Fragment_Source
#version 330 core
// Generated from Jai procedure animated_mesh_display.
in vec2 passthrough_uv;
layout(location=0) out vec4 gpu_rendering_pipeline_stage_attachment_color;
uniform sampler2D image;
uniform float exposure;
uniform bool tone_map;

float jai_linear_to_srgb_channel(float linear) {
    float value = max(linear, 0.0);
    if ((value <= 0.0031308)) {
        return (value * 12.92);
    }
    return ((1.055 * pow(value, (1.0 / 2.4))) - 0.055);
}

vec3 jai_linear_to_srgb(vec3 linear) {
    return vec3(jai_linear_to_srgb_channel(linear.x), jai_linear_to_srgb_channel(linear.y), jai_linear_to_srgb_channel(linear.z));
}

void main() {
    vec4 sample = texture(image, passthrough_uv);
    vec3 color = max((vec3(sample.x, sample.y, sample.z) * exp2(exposure)), vec3(0.0, 0.0, 0.0));
    if (tone_map) {
        color = (color / (vec3(1.0, 1.0, 1.0) + color));
    }
    color = jai_linear_to_srgb(color);
    gpu_rendering_pipeline_stage_attachment_color = vec4(color.x, color.y, color.z, 1.0);
}

END_Animated_Mesh_Display_Fragment_Source
