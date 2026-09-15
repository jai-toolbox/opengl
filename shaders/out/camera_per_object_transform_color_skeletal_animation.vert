#version 330 core

// Begin include: local_to_world_1024_ubo.glsl
in uint local_to_world_index;

layout(std140, row_major) uniform LtwMatrices {
    mat4 local_to_world_matrices[1024];
};
// End include: local_to_world_1024_ubo.glsl
// Begin include: skeletal_animation_100_bones_4_bones_per_vertex.glsl
// so we call these passthrough because we sometimes want to visualize the bone weights in the fragment shader
// you can create out's for these and do that if you want to. or if you don't then you can take off the passthrough_
// in ivec4 passthrough_bone_transorm_indices;
// in vec4 passthrough_bone_weights;

in ivec4 bone_transform_indices;
in vec4 bone_weights;

// if a model contains more, then those bones will not be used.
// in the future we may want to generate other versions of this file with different constants.
const int MAX_BONES_TO_USE = 100;

// Resource contract:
// The CPU/runtime side must upload one interpolated animation pose into this
// array before drawing. Each matrix is the final skinning transform for one
// bone at the current animation time: local animated pose, including the full
// parent hierarchy, composed with whatever inverse bind/rest data the model
// loader uses for skinning.
//
// In other words, this shader does not sample animation clips or walk the
// skeleton. It assumes that work has already happened, and that
// bone_animation_transforms[bone_index] is ready to move vertices influenced by
// that bone. Each vertex carries up to four bone indices and weights; the
// shader blends those ready-to-use matrices to produce the animated position.
uniform mat4 bone_animation_transforms[MAX_BONES_TO_USE];

/**
 * @brief Computes the animation transform by blending the bone animation transforms
 *        based on the bone weights.
 *
 * @param bone_transorm_indices The IDs of the bones influencing the vertex.
 * @param bone_weights The weights of the bones influencing the vertex.
 * @return The computed animation transform matrix.
 */
mat4 compute_animation_transform(ivec4 bone_transorm_indices, vec4 bone_weights) {

    mat4 animation_transform = mat4(0.0);
    float total_weight = 0.0;

    for (int i = 0; i < 4; i++) {
        if (bone_transorm_indices[i] >= 0 && bone_transorm_indices[i] < MAX_BONES_TO_USE && bone_weights[i] > 0.0) {
            animation_transform += bone_animation_transforms[bone_transorm_indices[i]] * bone_weights[i];
            total_weight += bone_weights[i];
        }
    }

    // if all weights are zero, then the above produces a full zero animation transform
    // that's a problem for vertices that are not affected by any bones as they will get mapped to the origin.
    // so instead we should return the multiplicative identity
    if (total_weight == 0.0) {
        return mat4(1.0);
    }

    return animation_transform;
}

// Something confusing at first is that it seems like we're applying 4 full
// transformations, which should move the vertex way too far. But recall that
// the bone weights are non-negative and sum to 1.0, so this is actually a
// weighted average, not an accumulation.
//
// Consider the simple case: given 2 points in space, linear interpolation
// t * v + (1 - t) * w gives you a point somewhere on the line segment
// between v and w, because the weights t and (1 - t) sum to 1.
//
// This generalizes to n points. Non-negative weights that sum to 1 are
// barycentric coordinates, and the result is constrained to the convex hull
// of the points, a simplex. For 2 points that's a line segment, for 3 a
// triangle, and for our 4 bone influences, a tetrahedron.
//
// So the skinned position isn't "transformed 4 times", it's a blend that
// lies somewhere inside the tetrahedron defined by where each bone would
// independently place the vertex.
//
// One caveat: the simplex interpretation is clean for positions, but we're
// blending full transformation matrices here, which include rotation and
// scale. Linear blending of rotation matrices doesn't interpolate rotations
// correctly. For example, consider averaging a +90 and -90 degree rotation
// in 2D:
//
//   0.5 * [ 0 -1 ] + 0.5 * [  0  1 ] = [ 0  0 ]
//         [ 1  0 ]         [ -1  0 ]   [ 0  0 ]
//
// You'd expect the identity (0 degree rotation), but instead you get the
// zero matrix. The columns of a rotation matrix are unit vectors, and when
// two rotations point those columns in opposing directions, they cancel out
// rather than meeting in the middle. The result is a matrix that shrinks
// or collapses the geometry. This is the source of the classic "candy
// wrapper" artifact where a mesh loses volume at joints that twist heavily,
// like a wrist rotating 180 degrees. Techniques like Dual Quaternion
// Skinning exist to handle this properly, but in practice plain Linear
// Blend Skinning works well enough for most cases and is what the vast
// majority of real-time applications use.
// End include: skeletal_animation_100_bones_4_bones_per_vertex.glsl

uniform mat4 camera_to_clip;
uniform mat4 world_to_camera;

in vec3 position;
in vec3 passthrough_rgb_color;

out vec3 rgb_color;

void main() {

    rgb_color = passthrough_rgb_color;

    // the animation transform contains the entire hierarchical structure for that vertex
    mat4 animation_transform = compute_animation_transform(bone_transform_indices, bone_weights);
    vec4 animated_position = animation_transform * vec4(position, 1.0);

    gl_Position = camera_to_clip * world_to_camera * local_to_world_matrices[local_to_world_index] * animated_position;
}
