#version 330 core
// Generated from Jai procedure fullscreen_vertex_shader.
out vec2 passthrough_uv;

void main() {
    vec2 p = vec2(float(((gl_VertexID << 1) & 2)), float((gl_VertexID & 2)));
    gl_Position = vec4(((p.x * 2.0) - 1.0), ((p.y * 2.0) - 1.0), 0.0, 1.0);
    passthrough_uv = p;
}
