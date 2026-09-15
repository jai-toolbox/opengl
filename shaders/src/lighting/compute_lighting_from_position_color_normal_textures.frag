#version 330 core

out vec4 frag_color;
  
in vec2 texture_coordinate;

uniform sampler2D position_texture;
uniform sampler2D normal_texture;
uniform sampler2D color_texture;

struct Light {
    vec3 position;
    vec3 color;
};

const int MAX_LIGHTS = 32;
uniform Light lights[MAX_LIGHTS];
uniform vec3 camera_position;

#include "blinn_phong.glsl"

void main() {             
    vec3 world_space_position = texture(position_texture, texture_coordinate).rgb;
    vec3 normal = texture(normal_texture, texture_coordinate).rgb;
    vec3 color = texture(color_texture, texture_coordinate).rgb;
    // don't have support for specmaps yet.
    // float Specular = texture(gAlbedoSpec, TexCoords).a;
    float specular_strength = 0.5;
    float shininess = 64.0;
    
    vec3 lighting = color * 0.1; // hard-coded ambient component
    vec3 camera_to_frag_pos_dir = normalize(camera_position - world_space_position);

    for(int i = 0; i < MAX_LIGHTS; ++i) {
        vec3 light_dir = normalize(lights[i].position - world_space_position);

        // diffuse
        // note that a negative dot product means the angle between the normal and light
        // is greater than 90 degrees so light cannot hit that, so we make sure to 
        // make the diff 0 in those cases using max
        float diff = max(dot(normal, light_dir), 0.0);
        vec3 diffuse = diff * color * lights[i].color;

        vec3 specular = compute_specular_blinn_phong(light_dir, camera_position, normal, specular_strength, shininess, lights[i].color);

        lighting += diffuse + specular;
    }

    frag_color = vec4(lighting, 1.0);

}  
