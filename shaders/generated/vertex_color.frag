#version 330 core
// Generated from Jai procedure mesh_vertex_color_fragment_shader.
in vec3 passthrough_color;
layout(location=0) out vec4 gpu_rendering_pipeline_stage_attachment_color;

void main() {
    gpu_rendering_pipeline_stage_attachment_color = vec4(passthrough_color.x, passthrough_color.y, passthrough_color.z, 1.0);
}
