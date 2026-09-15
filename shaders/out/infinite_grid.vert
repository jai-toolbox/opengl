#version 330

// This shader has no vertex inputs, the grid quad geometry is
// stored entirely as constants. We use gl_VertexID to index into
// the vertex/index arrays, so you just need to issue a draw call
// with 6 vertices and an empty VAO bound.

out vec3 grid_world_position;

uniform mat4 camera_to_clip = mat4(1.0);
uniform mat4 world_to_camera = mat4(1.0);

uniform float grid_size = 100.0;  // note that this is also in the fragment shader
uniform vec3 camera_position;

// 0 = XZ (horizontal, Y=0), 1 = XY (vertical, Z=0), 2 = YZ (vertical, X=0)
uniform int grid_plane = 0;

const vec2 square_positions[4] = vec2[4](
    vec2(-1.0, -1.0),      // bottom left
    vec2( 1.0, -1.0),      // bottom right
    vec2( 1.0,  1.0),      // top right
    vec2(-1.0,  1.0)       // top left
);

const int square_indices[6] = int[6](0, 2, 1, 2, 0, 3);

void main() {
    // look up the vertex position from the hardcoded quad.
    // the unit square [-1, 1] is scaled by grid_size to cover
    // the desired world-space area.

    int index = square_indices[gl_VertexID];
    vec2 pos2d = square_positions[index] * grid_size;

    // Expand the 2D quad into 3D based on the chosen plane.
    // The two active axes get the quad coordinates; the flat axis
    // stays at 0.

    // move the grid to the camera's position along the active axes
    // so the grid always surrounds the viewer. The flat axis stays
    // at 0. This is what makes the grid appear "infinite" — it
    // follows the camera so you never see its edges.

    vec3 grid_position;

    if (grid_plane == 0) {
        // XZ plane (Y = 0) — the original behavior
        grid_position = vec3(pos2d.x + camera_position.x,
                             0.0,
                             pos2d.y + camera_position.z);
    } else if (grid_plane == 1) {
        // XY plane (Z = 0)
        grid_position = vec3(pos2d.x + camera_position.x,
                             pos2d.y + camera_position.y,
                             0.0);
    } else {
        // YZ plane (X = 0)
        grid_position = vec3(0.0,
                             pos2d.x + camera_position.y,
                             pos2d.y + camera_position.z);
    }

    // we pass the world position to the fragment shader so it can
    // compute grid lines based on world-space coordinates.
    grid_world_position = grid_position;

    gl_Position = camera_to_clip * world_to_camera * vec4(grid_position, 1.0);
}
