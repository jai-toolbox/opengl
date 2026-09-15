#version 330 core

const int SKELETAL_ANIMATION_MAX_BONES = 100;

layout(std140, row_major) uniform LtwMatrices {
    mat4 local_to_world_matrices[1024];
};

layout(std140, row_major) uniform BoneAnimationTransforms {
    mat4 bone_animation_transforms[SKELETAL_ANIMATION_MAX_BONES];
};

uniform mat4 world_to_camera;
uniform mat4 camera_to_clip;
uniform mat4 world_to_light_clip;

in vec3 position;
in vec3 normal;
in vec3 tangent;
in vec2 uv;
in uint material_index;
in uint local_to_world_index;
in uvec4 bone_transform_indices;
in vec4 bone_weights;

out vec3 v_world_position;
out vec3 v_normal;
out vec3 v_tangent;
out vec2 v_uv;
out vec4 v_light_clip_position;
flat out uint v_material_index;

mat4 compute_animation_transform(uvec4 indices, vec4 weights) {
    mat4 animation_transform = mat4(0.0);
    float total_weight = 0.0;

    for (int i = 0; i < 4; i++) {
        uint bone_index = indices[i];
        float weight = weights[i];
        if (bone_index < uint(SKELETAL_ANIMATION_MAX_BONES) && weight > 0.0) {
            animation_transform += bone_animation_transforms[bone_index] * weight;
            total_weight += weight;
        }
    }

    if (total_weight == 0.0) return mat4(1.0);
    return animation_transform;
}

void main() {
    mat4 animation_transform = compute_animation_transform(bone_transform_indices, bone_weights);
    vec3 skinned_position = vec3(animation_transform * vec4(position, 1.0));
    vec3 skinned_normal = normalize(vec3(animation_transform * vec4(normal, 0.0)));
    vec3 skinned_tangent = normalize(vec3(animation_transform * vec4(tangent, 0.0)));

    mat4 local_to_world = local_to_world_matrices[local_to_world_index];
    vec4 world_position = local_to_world * vec4(skinned_position, 1.0);
    v_world_position = world_position.xyz;
    v_normal = normalize(mat3(local_to_world) * skinned_normal);
    v_tangent = normalize(mat3(local_to_world) * skinned_tangent);
    v_uv = uv;
    v_light_clip_position = world_to_light_clip * world_position;
    v_material_index = material_index;
    gl_Position = camera_to_clip * world_to_camera * world_position;
}
