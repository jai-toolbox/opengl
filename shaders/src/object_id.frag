#version 330 core

flat in uint object_id;
out uvec3 frag_color;

void main() {
    frag_color = uvec3(object_id, 0, 0);
}
