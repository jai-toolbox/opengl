// Versioned reflection-capture data and its OpenGL runtime form.
// Cubemap texels are stored mip-major, face-major for each capture.  Runtime
// capture proxies are uploaded through a texture buffer so the renderer does
// not impose a fixed uniform-array cap.

REFLECTION_CAPTURE_MAP_MAGIC :: 0x4143524c; // LRCA
REFLECTION_CAPTURE_MAP_VERSION :: 3;
REFLECTION_CAPTURE_PROXY_FLOAT4S :: 8;

Reflection_Capture_Guid :: struct {
    a: u32;
    b: u32;
    c: u32;
    d: u32;
}

reflection_capture_guid_equal :: (a: Reflection_Capture_Guid, b: Reflection_Capture_Guid) -> bool {
    return a.a == b.a && a.b == b.b && a.c == b.c && a.d == b.d;
}

// Every imported capture needs a persistent identifier. glTF has no GUID field
// for reflection probes, so importers derive the same stable value from the
// source node index instead of generating a random identifier.
reflection_capture_guid_from_import_node :: (node_token: u64) -> Reflection_Capture_Guid {
    return .{
        0x52434647, // RC_FGuid namespace
        0x474c5446, // GLTF
        cast(u32) node_token,
        cast(u32) (node_token >> 32) ^ 0x9e3779b9
    };
}

Reflection_Capture_Shape :: enum u32 {
    SPHERE;
    BOX;
    PLANE;
}

Reflection_Capture_Source_Type :: enum u32 {
    CAPTURED_SCENE;
    SPECIFIED_CUBEMAP;
}

Reflection_Capture_Map_Header :: struct {
    magic: u32;
    version: u32;
    actor_count: u32;
    build_data_count: u32;
    actor_record_bytes: u32;
    build_data_record_bytes: u32;
    full_hdr_bytes: u64;
    encoded_hdr_bytes: u64;
}

Reflection_Capture_Map_Record :: struct {
    map_build_data_id: Reflection_Capture_Guid;
    proxy_guid: u64;
    shape: u32;
    source_type: u32;
    position: Vector3;
    influence_radius: float32;
    capture_offset: Vector3;
    brightness: float32 = 1.0;
    box_transform: Matrix4 = Matrix4_Identity;
    box_scales: Vector3;
    box_transition_distance: float32;
    source_cubemap_angle: float32;
}

// Filtered cubemap payload associated with a stable map-build identifier. The
// actor table intentionally contains none of these fields; loaders resolve the
// payload through map_build_data_id.
Reflection_Capture_Map_Build_Data :: struct {
    map_build_data_id: Reflection_Capture_Guid;
    cubemap_size: u32;
    average_brightness: float32;
    full_hdr_offset: u64;
    full_hdr_bytes: u64;
    encoded_hdr_offset: u64;
    encoded_hdr_bytes: u64;
}

Reflection_Probe_Resources :: struct {
    cubemap_array_gl_handle: GLuint;
    proxy_buffer_gl_handle: GLuint;
    proxy_texture_gl_handle: GLuint;
    captures: [..] Reflection_Capture_Map_Record;
    cubemap_size: s32;
    num_mips: s32;
}

deinit :: (resources: *Reflection_Probe_Resources) {
    if resources.cubemap_array_gl_handle != 0 glDeleteTextures(1, *resources.cubemap_array_gl_handle);
    if resources.proxy_texture_gl_handle != 0 glDeleteTextures(1, *resources.proxy_texture_gl_handle);
    if resources.proxy_buffer_gl_handle != 0 glDeleteBuffers(1, *resources.proxy_buffer_gl_handle);
    array_free(resources.captures);
    resources.* = .{};
}

reflection_capture_proxy_add_vec4 :: (data: *[..] float32, v: Vector4) {
    array_add(data, v.x);
    array_add(data, v.y);
    array_add(data, v.z);
    array_add(data, v.w);
}

reflection_capture_mip_count :: (size: s32) -> s32 {
    result: s32 = 0;
    while size > 0 {
        result += 1;
        size >>= 1;
    }
    return result;
}

reflection_capture_full_hdr_bytes :: (size: s32) -> u64 {
    result: u64 = 0;
    while size > 0 {
        result += cast(u64) size * cast(u64) size * 6 * 8;
        size >>= 1;
    }
    return result;
}

load_reflection_probe_resources :: (path: string) -> Reflection_Probe_Resources, bool {
    result: Reflection_Probe_Resources;
    data, ok := read_entire_file(path);
    defer if data.data != null free(data.data);
    if !ok || data.count < size_of(Reflection_Capture_Map_Header) return result, false;

    header := cast(*Reflection_Capture_Map_Header) data.data;
    if header.magic != REFLECTION_CAPTURE_MAP_MAGIC || header.version != REFLECTION_CAPTURE_MAP_VERSION return result, false;
    if header.actor_record_bytes != size_of(Reflection_Capture_Map_Record) return result, false;
    if header.build_data_record_bytes != size_of(Reflection_Capture_Map_Build_Data) return result, false;

    actor_bytes := cast(int) header.actor_count * size_of(Reflection_Capture_Map_Record);
    build_data_bytes := cast(int) header.build_data_count * size_of(Reflection_Capture_Map_Build_Data);
    build_data_start := size_of(Reflection_Capture_Map_Header) + actor_bytes;
    full_hdr_start := build_data_start + build_data_bytes;
    encoded_hdr_start := full_hdr_start + cast(int) header.full_hdr_bytes;
    expected := encoded_hdr_start + cast(int) header.encoded_hdr_bytes;
    if actor_bytes < 0 || build_data_bytes < 0 || build_data_start < 0 || full_hdr_start < build_data_start || expected < encoded_hdr_start || data.count < expected return result, false;

    if header.actor_count == 0 return result, true;
    actors := cast(*Reflection_Capture_Map_Record) (data.data + size_of(Reflection_Capture_Map_Header));
    build_data := cast(*Reflection_Capture_Map_Build_Data) (data.data + build_data_start);
    capture_build_indices: [..] int;
    defer array_free(capture_build_indices);
    max_array_layers: GLint = 0;
    glGetIntegerv(GL_MAX_ARRAY_TEXTURE_LAYERS, *max_array_layers);
    max_capture_count := min(341, cast(int) max_array_layers / 6);
    for actor_index: 0..cast(int) header.actor_count-1 {
        if result.captures.count >= max_capture_count break;
        found := -1;
        for build_index: 0..cast(int) header.build_data_count-1 {
            if reflection_capture_guid_equal(actors[actor_index].map_build_data_id, build_data[build_index].map_build_data_id) {
                found = build_index;
                break;
            }
        }
        // This is the same rule as UpdateReflectionSceneData: actors without
        // valid map build data are not exposed to reflection shaders.
        if found >= 0 && build_data[found].cubemap_size > 0 && build_data[found].full_hdr_bytes > 0 {
            array_add(*result.captures, actors[actor_index]);
            array_add(*capture_build_indices, found);
            source_size := cast(s32) build_data[found].cubemap_size;
            if result.cubemap_size == 0 || source_size < result.cubemap_size result.cubemap_size = source_size;
        }
    }
    if result.captures.count == 0 return result, true;

    // UpdateReflectionSceneData selects registered captures up to the platform
    // cap, then orders the selected proxies by radius and path hash.
    for i: 1..result.captures.count-1 {
        actor := result.captures[i];
        build_index := capture_build_indices[i];
        j := i;
        while j > 0 {
            previous := result.captures[j - 1];
            if previous.influence_radius < actor.influence_radius break;
            if previous.influence_radius == actor.influence_radius && previous.proxy_guid <= actor.proxy_guid break;
            result.captures[j] = previous;
            capture_build_indices[j] = capture_build_indices[j - 1];
            j -= 1;
        }
        result.captures[j] = actor;
        capture_build_indices[j] = build_index;
    }

    result.num_mips = reflection_capture_mip_count(result.cubemap_size);
    if result.num_mips == 0 return result, false;

    glGenTextures(1, *result.cubemap_array_gl_handle);
    glBindTexture(GL_TEXTURE_CUBE_MAP_ARRAY, result.cubemap_array_gl_handle);
    for mip: 0..result.num_mips-1 {
        mip_size := max(1, result.cubemap_size >> mip);
        glTexImage3D(GL_TEXTURE_CUBE_MAP_ARRAY, cast(GLint) mip, cast(GLint) GL_RGBA16F,
            cast(GLsizei) mip_size, cast(GLsizei) mip_size, cast(GLsizei) (result.captures.count * 6),
            0, GL_RGBA, GL_HALF_FLOAT, null);
    }
    glTexParameteri(GL_TEXTURE_CUBE_MAP_ARRAY, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    glTexParameteri(GL_TEXTURE_CUBE_MAP_ARRAY, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_CUBE_MAP_ARRAY, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP_ARRAY, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP_ARRAY, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP_ARRAY, GL_TEXTURE_BASE_LEVEL, 0);
    glTexParameteri(GL_TEXTURE_CUBE_MAP_ARRAY, GL_TEXTURE_MAX_LEVEL, result.num_mips - 1);

    for capture_index: 0..result.captures.count-1 {
        capture_data := *build_data[capture_build_indices[capture_index]];
        source_size := cast(s32) capture_data.cubemap_size;
        required_source_bytes := reflection_capture_full_hdr_bytes(source_size);
        if capture_data.full_hdr_bytes < required_source_bytes || capture_data.full_hdr_offset + capture_data.full_hdr_bytes > header.full_hdr_bytes {
            deinit(*result);
            return result, false;
        }
        local_offset: u64 = 0;
        while source_size > result.cubemap_size {
            local_offset += cast(u64) source_size * cast(u64) source_size * 6 * 8;
            source_size >>= 1;
        }
        if source_size != result.cubemap_size {
            deinit(*result);
            return result, false;
        }
        for mip: 0..result.num_mips-1 {
            mip_size := max(1, result.cubemap_size >> mip);
            face_bytes := cast(u64) mip_size * cast(u64) mip_size * 8;
            for face: 0..5 {
                source_offset := cast(u64) full_hdr_start + capture_data.full_hdr_offset + local_offset;
                if source_offset + face_bytes > cast(u64) full_hdr_start + capture_data.full_hdr_offset + capture_data.full_hdr_bytes {
                    deinit(*result);
                    return result, false;
                }
                glTexSubImage3D(GL_TEXTURE_CUBE_MAP_ARRAY, cast(GLint) mip, 0, 0,
                    cast(GLint) (capture_index * 6 + face), cast(GLsizei) mip_size, cast(GLsizei) mip_size, 1,
                    GL_RGBA, GL_HALF_FLOAT, cast(*void) (data.data + cast(int) source_offset));
                local_offset += face_bytes;
            }
        }
    }
    glBindTexture(GL_TEXTURE_CUBE_MAP_ARRAY, 0);

    proxy_data: [..] float32;
    defer array_free(proxy_data);
    array_reserve(*proxy_data, result.captures.count * REFLECTION_CAPTURE_PROXY_FLOAT4S * 4);
    for capture_index: 0..result.captures.count-1 {
        record := *result.captures[capture_index];
        capture_data := *build_data[capture_build_indices[capture_index]];
        reflection_capture_proxy_add_vec4(*proxy_data, .{record.position.x, record.position.y, record.position.z, record.influence_radius});
        reflection_capture_proxy_add_vec4(*proxy_data, .{record.brightness, cast(float32) capture_index, cast(float32) record.shape, 1.0});
        reflection_capture_proxy_add_vec4(*proxy_data, .{record.capture_offset.x, record.capture_offset.y, record.capture_offset.z, capture_data.average_brightness});
        reflection_capture_proxy_add_vec4(*proxy_data, .{record.box_scales.x, record.box_scales.y, record.box_scales.z, record.box_transition_distance});
        for row: 0..3 reflection_capture_proxy_add_vec4(*proxy_data, .{
            record.box_transform.coef[row][0], record.box_transform.coef[row][1],
            record.box_transform.coef[row][2], record.box_transform.coef[row][3]
        });
    }

    glGenBuffers(1, *result.proxy_buffer_gl_handle);
    glBindBuffer(GL_TEXTURE_BUFFER, result.proxy_buffer_gl_handle);
    glBufferData(GL_TEXTURE_BUFFER, proxy_data.count * size_of(float32), proxy_data.data, GL_STATIC_DRAW);
    glGenTextures(1, *result.proxy_texture_gl_handle);
    glBindTexture(GL_TEXTURE_BUFFER, result.proxy_texture_gl_handle);
    glTexBuffer(GL_TEXTURE_BUFFER, GL_RGBA32F, result.proxy_buffer_gl_handle);
    glBindTexture(GL_TEXTURE_BUFFER, 0);
    glBindBuffer(GL_TEXTURE_BUFFER, 0);
    return result, true;
}
