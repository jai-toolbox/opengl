#version 330 core

const int SKELETAL_ANIMATION_MAX_BONES = 100;

layout(std140, row_major) uniform LtwMatrices {
    mat4 local_to_world_matrices[1024];
};

layout(std140, row_major) uniform BoneAnimationTransforms {
    mat4 bone_animation_transforms[SKELETAL_ANIMATION_MAX_BONES];
};

uniform mat4 world_to_light_clip;

in vec3 position;
in uint local_to_world_index;
in uvec4 bone_transform_indices;
in vec4 bone_weights;

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
    mat4 local_to_world = local_to_world_matrices[local_to_world_index];
    vec4 world_position = local_to_world * vec4(skinned_position, 1.0);
    gl_Position = world_to_light_clip * world_position;
}
