/*
Because you cannot just use a job system on opengl stuff because it can only 
happen in the main thread then we need a system that can still allow us to run
asynchronous logic when it comes to working with opengl. 

This system is a solution to that. The solution is simple, break down big calls
into a sequence of small calls which can make progress at realtime scale.
*/

/*
When you borrow source memory it must remain valid until gl_budgeted_operations_complete
returns true. COPY is intended for stack data or other short-lived staging memory.
*/
GL_Budgeted_Data_Lifetime :: enum {
    BORROW_UNTIL_COMPLETE;
    COPY;
}

GL_Budgeted_Operation_Kind :: enum {
    ALLOCATE_BUFFER_STORAGE;
    UPDATE_BUFFER_SUBDATA;
    DEFINE_TEXTURE_1D;
    DEFINE_TEXTURE_2D;
    DEFINE_TEXTURE_3D;
    UPDATE_TEXTURE_3D_SUBIMAGE;
}

GL_Budgeted_Operation :: struct {
    kind: GL_Budgeted_Operation_Kind;

    binding_target: GLenum;
    captured_object: GLuint;
    captured_texture_unit: GLenum = GL_TEXTURE0;
    captured_texture_binding_target: GLenum;
    captured_vertex_array: GLuint;

    byte_offset: GLintptr;
    storage_byte_count: GLsizeiptr;
    usage: GLenum;

    mipmap_level: GLint;
    internal_format: GLint;
    border: GLint;
    x_offset: GLint;
    y_offset: GLint;
    z_offset: GLint;
    width: GLsizei;
    height: GLsizei;
    depth: GLsizei;
    pixel_format: GLenum;
    pixel_data_type: GLenum;
    unpack_alignment: GLint = 4;
    unpack_row_length: GLint;
    unpack_skip_pixels: GLint;
    unpack_skip_rows: GLint;

    data: *u8;
    data_byte_count: s64;
    owns_data: bool;

    bytes_per_row: s64;
    completed_byte_count: s64;
    completed_rows: s64;
    allocation_complete: bool;

    total_work: s64;
    completed_work: s64;
}

GL_Budgeter :: struct {
    operations: [..] GL_Budgeted_Operation;
    next_operation_index: int;

    total_work: s64;
    completed_work: s64;

    // a chunk is one atomic glBufferSubData call
    // it is modest so one call does not consume the entire frame budget on ordinary desktop drivers.
    // we could also dynamically choose this based on real timings made, for now this works.
    maximum_buffer_chunk_bytes: s64 = 1024 * 1024;
    maximum_texture_chunk_bytes: s64 = 1024 * 1024;
}

gl_budgeted_copy_or_borrow_data :: (
    data: *void,
    byte_count: s64,
    lifetime: GL_Budgeted_Data_Lifetime,
) -> result: *u8, owns_result: bool {
    if data == null || byte_count <= 0 return null, false;

    if lifetime == .BORROW_UNTIL_COMPLETE {
        return cast(*u8) data, false;
    }

    copied_data := cast(*u8) alloc(byte_count);
    memcpy(copied_data, data, byte_count);
    return copied_data, true;
}

gl_budgeted_append_operation :: (
    budgeter: *GL_Budgeter,
    operation: GL_Budgeted_Operation,
) {
    normalized_operation := operation;
    normalized_operation.total_work = max(cast(s64) 1, operation.total_work);
    array_add(*budgeter.operations, normalized_operation);
    budgeter.total_work += normalized_operation.total_work;
}

gl_budgeted_tracked_pixel_store_or_default :: (
    parameter_name: GLenum,
    default_value: GLint,
) -> GLint {
    value, was_set := gl_get_tracked_integer_pixel_storage_parameter(parameter_name);
    return ifx was_set then value else default_value;
}

gl_budgeted_capture_unpack_state :: (operation: *GL_Budgeted_Operation) {
    operation.unpack_alignment = gl_budgeted_tracked_pixel_store_or_default(GL_UNPACK_ALIGNMENT, 4);
    operation.unpack_row_length = gl_budgeted_tracked_pixel_store_or_default(GL_UNPACK_ROW_LENGTH, 0);
    operation.unpack_skip_pixels = gl_budgeted_tracked_pixel_store_or_default(GL_UNPACK_SKIP_PIXELS, 0);
    operation.unpack_skip_rows = gl_budgeted_tracked_pixel_store_or_default(GL_UNPACK_SKIP_ROWS, 0);
}

gl_budgeted_allocate_storage_for_buffer_bound_to_binding_target :: (
    budgeter: *GL_Budgeter,
    binding_target: GLenum,
    byte_count: GLsizeiptr,
    initial_data: *void,
    usage: GLenum,
    data_lifetime: GL_Budgeted_Data_Lifetime = .COPY,
) -> bool {
    buffer := gl_get_tracked_buffer_bound_to_binding_target(binding_target);
    if buffer == 0 {
        log_error("Cannot budget buffer allocation: no buffer is bound to target %", binding_target);
        return false;
    }

    copied_data, owns_data := gl_budgeted_copy_or_borrow_data(
        initial_data, cast(s64) byte_count, data_lifetime);
    data_bytes := ifx initial_data != null then cast(s64) byte_count else 0;
    gl_budgeted_append_operation(budgeter, .{
        kind = .ALLOCATE_BUFFER_STORAGE,
        binding_target = binding_target,
        captured_object = buffer,
        captured_vertex_array = gl_state_metadata.vertex_array,
        storage_byte_count = byte_count,
        usage = usage,
        data = copied_data,
        data_byte_count = data_bytes,
        owns_data = owns_data,
        total_work = cast(s64) byte_count + data_bytes,
    });
    return true;
}

gl_allocate_storage_for_buffer_bound_to_binding_target :: (
    budgeter: *GL_Budgeter,
    binding_target: GLenum,
    byte_count: GLsizeiptr,
    initial_data: *void,
    usage: GLenum,
    data_lifetime: GL_Budgeted_Data_Lifetime = .COPY,
) -> bool {
    if budgeter {
        return gl_budgeted_allocate_storage_for_buffer_bound_to_binding_target(
            budgeter,
            binding_target,
            byte_count,
            initial_data,
            usage,
            data_lifetime,
        );
    }

    gl_allocate_storage_for_buffer_bound_to_binding_target(
        binding_target,
        byte_count,
        initial_data,
        usage,
    );
    return true;
}

gl_budgeted_update_subdata_in_buffer_bound_to_binding_target :: (
    budgeter: *GL_Budgeter,
    binding_target: GLenum,
    byte_offset: GLintptr,
    byte_count: GLsizeiptr,
    data: *void,
    data_lifetime: GL_Budgeted_Data_Lifetime = .COPY,
) -> bool {
    if byte_count <= 0 return true;
    if data == null {
        log_error("Cannot budget % bytes of buffer data from a null pointer", byte_count);
        return false;
    }

    buffer := gl_get_tracked_buffer_bound_to_binding_target(binding_target);
    if buffer == 0 {
        log_error("Cannot budget buffer update: no buffer is bound to target %", binding_target);
        return false;
    }

    budgeted_data, owns_data := gl_budgeted_copy_or_borrow_data(
        data, cast(s64) byte_count, data_lifetime);
    gl_budgeted_append_operation(budgeter, .{
        kind = .UPDATE_BUFFER_SUBDATA,
        binding_target = binding_target,
        captured_object = buffer,
        captured_vertex_array = gl_state_metadata.vertex_array,
        byte_offset = byte_offset,
        data = budgeted_data,
        data_byte_count = cast(s64) byte_count,
        owns_data = owns_data,
        total_work = cast(s64) byte_count,
    });
    return true;
}

gl_update_subdata_in_buffer_bound_to_binding_target :: (
    budgeter: *GL_Budgeter,
    binding_target: GLenum,
    byte_offset: GLintptr,
    byte_count: GLsizeiptr,
    data: *void,
    data_lifetime: GL_Budgeted_Data_Lifetime = .BORROW_UNTIL_COMPLETE,
) -> bool {
    if budgeter {
        return gl_budgeted_update_subdata_in_buffer_bound_to_binding_target(
            budgeter,
            binding_target,
            byte_offset,
            byte_count,
            data,
            data_lifetime,
        );
    }

    gl_update_subdata_in_buffer_bound_to_binding_target(
        binding_target, byte_offset, byte_count, data);
    return true;
}

gl_budgeted_define_1d_image_for_texture_bound_to_binding_target_of_active_texture_unit :: (
    budgeter: *GL_Budgeter,
    binding_target: GLenum,
    mipmap_level: GLint,
    internal_format: GLint,
    width: GLsizei,
    border: GLint,
    pixel_format: GLenum,
    pixel_data_type: GLenum,
    pixels: *void,
    pixel_byte_count: s64 = 0,
    data_lifetime: GL_Budgeted_Data_Lifetime = .COPY,
) -> bool {
    texture := gl_get_tracked_texture_bound_to_binding_target_of_active_texture_unit(binding_target);
    if texture == 0 {
        log_error("Cannot budget 1D texture definition: no texture is bound to target %", binding_target);
        return false;
    }

    budgeted_data, owns_data := gl_budgeted_copy_or_borrow_data(
        pixels, pixel_byte_count, data_lifetime);
    operation := GL_Budgeted_Operation.{
        kind = .DEFINE_TEXTURE_1D,
        binding_target = binding_target,
        captured_object = texture,
        captured_texture_unit = gl_state_metadata.active_texture_unit,
        mipmap_level = mipmap_level,
        internal_format = internal_format,
        width = width,
        border = border,
        pixel_format = pixel_format,
        pixel_data_type = pixel_data_type,
        data = budgeted_data,
        data_byte_count = pixel_byte_count,
        owns_data = owns_data,
        total_work = max(cast(s64) 1, pixel_byte_count),
    };
    gl_budgeted_capture_unpack_state(*operation);
    gl_budgeted_append_operation(budgeter, operation);
    return true;
}

gl_define_1d_image_for_texture_bound_to_binding_target_of_active_texture_unit :: (
    budgeter: *GL_Budgeter,
    binding_target: GLenum,
    mipmap_level: GLint,
    internal_format: GLint,
    width: GLsizei,
    border: GLint,
    pixel_format: GLenum,
    pixel_data_type: GLenum,
    pixels: *void,
    pixel_byte_count: s64 = 0,
    data_lifetime: GL_Budgeted_Data_Lifetime = .COPY,
) -> bool {
    if budgeter {
        return gl_budgeted_define_1d_image_for_texture_bound_to_binding_target_of_active_texture_unit(
            budgeter,
            binding_target,
            mipmap_level,
            internal_format,
            width,
            border,
            pixel_format,
            pixel_data_type,
            pixels,
            pixel_byte_count,
            data_lifetime,
        );
    }

    gl_define_1d_image_for_texture_bound_to_binding_target_of_active_texture_unit(
        binding_target,
        mipmap_level,
        internal_format,
        width,
        border,
        pixel_format,
        pixel_data_type,
        pixels,
    );
    return true;
}

gl_budgeted_define_2d_image_for_texture_bound_to_binding_target_of_active_texture_unit :: (
    budgeter: *GL_Budgeter,
    texture_binding_target: GLenum,
    image_target: GLenum,
    mipmap_level: GLint,
    internal_format: GLint,
    width: GLsizei,
    height: GLsizei,
    border: GLint,
    pixel_format: GLenum,
    pixel_data_type: GLenum,
    pixels: *void,
    pixel_byte_count: s64 = 0,
    data_lifetime: GL_Budgeted_Data_Lifetime = .COPY,
) -> bool {
    texture := gl_get_tracked_texture_bound_to_binding_target_of_active_texture_unit(
        texture_binding_target);
    if texture == 0 {
        log_error(
            "Cannot budget 2D texture definition: no texture is bound to target %",
            texture_binding_target);
        return false;
    }

    budgeted_data, owns_data := gl_budgeted_copy_or_borrow_data(
        pixels, pixel_byte_count, data_lifetime);
    operation := GL_Budgeted_Operation.{
        kind = .DEFINE_TEXTURE_2D,
        binding_target = image_target,
        captured_object = texture,
        captured_texture_unit = gl_state_metadata.active_texture_unit,
        captured_texture_binding_target = texture_binding_target,
        mipmap_level = mipmap_level,
        internal_format = internal_format,
        width = width,
        height = height,
        border = border,
        pixel_format = pixel_format,
        pixel_data_type = pixel_data_type,
        data = budgeted_data,
        data_byte_count = pixel_byte_count,
        owns_data = owns_data,
        total_work = max(cast(s64) 1, pixel_byte_count),
    };
    gl_budgeted_capture_unpack_state(*operation);
    gl_budgeted_append_operation(budgeter, operation);
    return true;
}

gl_define_2d_image_for_texture_bound_to_binding_target_of_active_texture_unit :: (
    budgeter: *GL_Budgeter,
    texture_binding_target: GLenum,
    image_target: GLenum,
    mipmap_level: GLint,
    internal_format: GLint,
    width: GLsizei,
    height: GLsizei,
    border: GLint,
    pixel_format: GLenum,
    pixel_data_type: GLenum,
    pixels: *void,
    pixel_byte_count: s64 = 0,
    data_lifetime: GL_Budgeted_Data_Lifetime = .COPY,
) -> bool {
    if budgeter {
        return gl_budgeted_define_2d_image_for_texture_bound_to_binding_target_of_active_texture_unit(
            budgeter,
            texture_binding_target,
            image_target,
            mipmap_level,
            internal_format,
            width,
            height,
            border,
            pixel_format,
            pixel_data_type,
            pixels,
            pixel_byte_count,
            data_lifetime,
        );
    }

    gl_define_texture_2d_image_for_active_texture_unit(
        image_target,
        mipmap_level,
        internal_format,
        width,
        height,
        border,
        pixel_format,
        pixel_data_type,
        pixels,
    );
    return true;
}

gl_budgeted_define_3d_image_for_texture_bound_to_binding_target_of_active_texture_unit :: (
    budgeter: *GL_Budgeter,
    binding_target: GLenum,
    mipmap_level: GLint,
    internal_format: GLint,
    width: GLsizei,
    height: GLsizei,
    depth: GLsizei,
    border: GLint,
    pixel_format: GLenum,
    pixel_data_type: GLenum,
    pixels: *void,
    pixel_byte_count: s64 = 0,
    data_lifetime: GL_Budgeted_Data_Lifetime = .COPY,
) -> bool {
    texture := gl_get_tracked_texture_bound_to_binding_target_of_active_texture_unit(binding_target);
    if texture == 0 {
        log_error("Cannot budget 3D texture definition: no texture is bound to target %", binding_target);
        return false;
    }

    budgeted_data, owns_data := gl_budgeted_copy_or_borrow_data(
        pixels, pixel_byte_count, data_lifetime);
    operation := GL_Budgeted_Operation.{
        kind = .DEFINE_TEXTURE_3D,
        binding_target = binding_target,
        captured_object = texture,
        captured_texture_unit = gl_state_metadata.active_texture_unit,
        mipmap_level = mipmap_level,
        internal_format = internal_format,
        width = width,
        height = height,
        depth = depth,
        border = border,
        pixel_format = pixel_format,
        pixel_data_type = pixel_data_type,
        data = budgeted_data,
        data_byte_count = pixel_byte_count,
        owns_data = owns_data,
        total_work = max(cast(s64) 1, pixel_byte_count),
    };
    gl_budgeted_capture_unpack_state(*operation);
    gl_budgeted_append_operation(budgeter, operation);
    return true;
}

gl_define_3d_image_for_texture_bound_to_binding_target_of_active_texture_unit :: (
    budgeter: *GL_Budgeter,
    binding_target: GLenum,
    mipmap_level: GLint,
    internal_format: GLint,
    width: GLsizei,
    height: GLsizei,
    depth: GLsizei,
    border: GLint,
    pixel_format: GLenum,
    pixel_data_type: GLenum,
    pixels: *void,
    pixel_byte_count: s64 = 0,
    data_lifetime: GL_Budgeted_Data_Lifetime = .COPY,
) -> bool {
    if budgeter {
        return gl_budgeted_define_3d_image_for_texture_bound_to_binding_target_of_active_texture_unit(
            budgeter,
            binding_target,
            mipmap_level,
            internal_format,
            width,
            height,
            depth,
            border,
            pixel_format,
            pixel_data_type,
            pixels,
            pixel_byte_count,
            data_lifetime,
        );
    }

    gl_define_3d_image_for_texture_bound_to_binding_target_of_active_texture_unit(
        binding_target,
        mipmap_level,
        internal_format,
        width,
        height,
        depth,
        border,
        pixel_format,
        pixel_data_type,
        pixels,
    );
    return true;
}

gl_budgeted_update_3d_subimage_of_texture_bound_to_binding_target_of_active_texture_unit :: (
    budgeter: *GL_Budgeter,
    binding_target: GLenum,
    mipmap_level: GLint,
    x_offset: GLint,
    y_offset: GLint,
    z_offset: GLint,
    width: GLsizei,
    height: GLsizei,
    depth: GLsizei,
    pixel_format: GLenum,
    pixel_data_type: GLenum,
    pixels: *void,
    pixel_byte_count: s64,
    bytes_per_row: s64 = 0,
    data_lifetime: GL_Budgeted_Data_Lifetime = .COPY,
) -> bool {
    if pixel_byte_count <= 0 || pixels == null return true;

    texture := gl_get_tracked_texture_bound_to_binding_target_of_active_texture_unit(binding_target);
    if texture == 0 {
        log_error("Cannot budget 3D texture update: no texture is bound to target %", binding_target);
        return false;
    }

    budgeted_data, owns_data := gl_budgeted_copy_or_borrow_data(
        pixels, pixel_byte_count, data_lifetime);
    operation := GL_Budgeted_Operation.{
        kind = .UPDATE_TEXTURE_3D_SUBIMAGE,
        binding_target = binding_target,
        captured_object = texture,
        captured_texture_unit = gl_state_metadata.active_texture_unit,
        mipmap_level = mipmap_level,
        x_offset = x_offset,
        y_offset = y_offset,
        z_offset = z_offset,
        width = width,
        height = height,
        depth = depth,
        pixel_format = pixel_format,
        pixel_data_type = pixel_data_type,
        data = budgeted_data,
        data_byte_count = pixel_byte_count,
        owns_data = owns_data,
        bytes_per_row = bytes_per_row,
        total_work = pixel_byte_count,
    };
    gl_budgeted_capture_unpack_state(*operation);
    gl_budgeted_append_operation(budgeter, operation);
    return true;
}

gl_update_3d_subimage_of_texture_bound_to_binding_target_of_active_texture_unit :: (
    budgeter: *GL_Budgeter,
    binding_target: GLenum,
    mipmap_level: GLint,
    x_offset: GLint,
    y_offset: GLint,
    z_offset: GLint,
    width: GLsizei,
    height: GLsizei,
    depth: GLsizei,
    pixel_format: GLenum,
    pixel_data_type: GLenum,
    pixels: *void,
    pixel_byte_count: s64,
    bytes_per_row: s64 = 0,
    data_lifetime: GL_Budgeted_Data_Lifetime = .COPY,
) -> bool {
    if budgeter {
        return gl_budgeted_update_3d_subimage_of_texture_bound_to_binding_target_of_active_texture_unit(
            budgeter,
            binding_target,
            mipmap_level,
            x_offset,
            y_offset,
            z_offset,
            width,
            height,
            depth,
            pixel_format,
            pixel_data_type,
            pixels,
            pixel_byte_count,
            bytes_per_row,
            data_lifetime,
        );
    }

    gl_update_3d_subimage_of_texture_bound_to_binding_target_of_active_texture_unit(
        binding_target,
        mipmap_level,
        x_offset,
        y_offset,
        z_offset,
        width,
        height,
        depth,
        pixel_format,
        pixel_data_type,
        pixels,
    );
    return true;
}

gl_budgeted_release_operation_data :: (operation: *GL_Budgeted_Operation) {
    if operation.owns_data && operation.data != null free(operation.data);
    operation.data = null;
    operation.owns_data = false;
}

gl_budgeted_with_captured_buffer_bound :: (
    operation: *GL_Budgeted_Operation,
    byte_offset: GLintptr,
    byte_count: GLsizeiptr,
    data: *void,
) {
    previous_vertex_array := gl_state_metadata.vertex_array;
    if operation.binding_target == GL_ELEMENT_ARRAY_BUFFER &&
       previous_vertex_array != operation.captured_vertex_array {
        gl_bind_vertex_array(operation.captured_vertex_array);
    }

    previous_buffer := gl_get_tracked_buffer_bound_to_binding_target(operation.binding_target);
    gl_bind_buffer_to_binding_target(operation.binding_target, operation.captured_object);
    gl_update_subdata_in_buffer_bound_to_binding_target(
        operation.binding_target, byte_offset, byte_count, data);
    gl_bind_buffer_to_binding_target(operation.binding_target, previous_buffer);

    if operation.binding_target == GL_ELEMENT_ARRAY_BUFFER &&
       previous_vertex_array != operation.captured_vertex_array {
        gl_bind_vertex_array(previous_vertex_array);
    }
}

gl_budgeted_bind_captured_texture :: (
    operation: *GL_Budgeted_Operation,
) -> previous_active_unit: GLenum, previous_texture: GLuint {
    texture_binding_target := ifx operation.captured_texture_binding_target != 0
        then operation.captured_texture_binding_target
        else operation.binding_target;
    active_unit := gl_state_metadata.active_texture_unit;
    bound_texture := gl_get_tracked_texture_bound_to_binding_target_of_texture_unit(
        texture_binding_target, operation.captured_texture_unit);
    gl_set_active_texture_unit(operation.captured_texture_unit);
    gl_bind_texture_to_binding_target_of_active_texture_unit(
        texture_binding_target, operation.captured_object);
    return active_unit, bound_texture;
}

gl_budgeted_restore_texture_binding :: (
    operation: *GL_Budgeted_Operation,
    previous_active_unit: GLenum,
    previous_texture: GLuint,
) {
    texture_binding_target := ifx operation.captured_texture_binding_target != 0
        then operation.captured_texture_binding_target
        else operation.binding_target;
    gl_bind_texture_to_binding_target_of_active_texture_unit(
        texture_binding_target, previous_texture);
    gl_set_active_texture_unit(previous_active_unit);
}

GL_Budgeted_Unpack_State :: struct {
    alignment: GLint;
    row_length: GLint;
    skip_pixels: GLint;
    skip_rows: GLint;
}

gl_budgeted_get_current_unpack_state :: () -> GL_Budgeted_Unpack_State {
    return .{
        alignment = gl_budgeted_tracked_pixel_store_or_default(GL_UNPACK_ALIGNMENT, 4),
        row_length = gl_budgeted_tracked_pixel_store_or_default(GL_UNPACK_ROW_LENGTH, 0),
        skip_pixels = gl_budgeted_tracked_pixel_store_or_default(GL_UNPACK_SKIP_PIXELS, 0),
        skip_rows = gl_budgeted_tracked_pixel_store_or_default(GL_UNPACK_SKIP_ROWS, 0),
    };
}

gl_budgeted_set_unpack_state :: (state: GL_Budgeted_Unpack_State) {
    gl_set_integer_pixel_storage_parameter(GL_UNPACK_ALIGNMENT, state.alignment);
    gl_set_integer_pixel_storage_parameter(GL_UNPACK_ROW_LENGTH, state.row_length);
    gl_set_integer_pixel_storage_parameter(GL_UNPACK_SKIP_PIXELS, state.skip_pixels);
    gl_set_integer_pixel_storage_parameter(GL_UNPACK_SKIP_ROWS, state.skip_rows);
}

gl_budgeted_set_captured_unpack_state :: (operation: *GL_Budgeted_Operation) {
    gl_budgeted_set_unpack_state(.{
        alignment = operation.unpack_alignment,
        row_length = operation.unpack_row_length,
        skip_pixels = operation.unpack_skip_pixels,
        skip_rows = operation.unpack_skip_rows,
    });
}

gl_budgeted_finish_operation :: (
    budgeter: *GL_Budgeter,
    operation: *GL_Budgeted_Operation,
) {
    remaining_work := max(cast(s64) 0, operation.total_work - operation.completed_work);
    operation.completed_work += remaining_work;
    budgeter.completed_work += remaining_work;
    gl_budgeted_release_operation_data(operation);
    budgeter.next_operation_index += 1;
}

gl_process_one_budgeted_operation :: (budgeter: *GL_Budgeter) {
    operation := *budgeter.operations[budgeter.next_operation_index];

    if operation.kind == .UPDATE_BUFFER_SUBDATA {
        remaining := operation.data_byte_count - operation.completed_byte_count;
        chunk_size := min(remaining, max(cast(s64) 1, budgeter.maximum_buffer_chunk_bytes));
        gl_budgeted_with_captured_buffer_bound(
            operation,
            operation.byte_offset + operation.completed_byte_count,
            cast(GLsizeiptr) chunk_size,
            operation.data + operation.completed_byte_count,
        );
        operation.completed_byte_count += chunk_size;
        operation.completed_work += chunk_size;
        budgeter.completed_work += chunk_size;
        if operation.completed_byte_count >= operation.data_byte_count {
            gl_budgeted_finish_operation(budgeter, operation);
        }
        return;
    }

    if operation.kind == .ALLOCATE_BUFFER_STORAGE {
        previous_vertex_array := gl_state_metadata.vertex_array;
        if operation.binding_target == GL_ELEMENT_ARRAY_BUFFER &&
           previous_vertex_array != operation.captured_vertex_array {
            gl_bind_vertex_array(operation.captured_vertex_array);
        }
        previous_buffer := gl_get_tracked_buffer_bound_to_binding_target(operation.binding_target);
        gl_bind_buffer_to_binding_target(operation.binding_target, operation.captured_object);

        if !operation.allocation_complete {
            gl_allocate_storage_for_buffer_bound_to_binding_target(
                operation.binding_target,
                operation.storage_byte_count,
                null,
                operation.usage,
            );
            operation.allocation_complete = true;
            allocation_work := cast(s64) operation.storage_byte_count;
            operation.completed_work += allocation_work;
            budgeter.completed_work += allocation_work;
        } else if operation.data_byte_count > 0 {
            remaining := operation.data_byte_count - operation.completed_byte_count;
            chunk_size := min(remaining, max(cast(s64) 1, budgeter.maximum_buffer_chunk_bytes));
            gl_update_subdata_in_buffer_bound_to_binding_target(
                operation.binding_target,
                operation.completed_byte_count,
                cast(GLsizeiptr) chunk_size,
                operation.data + operation.completed_byte_count,
            );
            operation.completed_byte_count += chunk_size;
            operation.completed_work += chunk_size;
            budgeter.completed_work += chunk_size;
        }

        gl_bind_buffer_to_binding_target(operation.binding_target, previous_buffer);
        if operation.binding_target == GL_ELEMENT_ARRAY_BUFFER &&
           previous_vertex_array != operation.captured_vertex_array {
            gl_bind_vertex_array(previous_vertex_array);
        }

        if operation.allocation_complete &&
           operation.completed_byte_count >= operation.data_byte_count {
            gl_budgeted_finish_operation(budgeter, operation);
        }
        return;
    }

    previous_active_unit, previous_texture := gl_budgeted_bind_captured_texture(operation);
    previous_unpack_state := gl_budgeted_get_current_unpack_state();

    if operation.kind == .DEFINE_TEXTURE_1D {
        gl_budgeted_set_captured_unpack_state(operation);
        gl_define_1d_image_for_texture_bound_to_binding_target_of_active_texture_unit(
            operation.binding_target,
            operation.mipmap_level,
            operation.internal_format,
            operation.width,
            operation.border,
            operation.pixel_format,
            operation.pixel_data_type,
            operation.data,
        );
        gl_budgeted_set_unpack_state(previous_unpack_state);
        gl_budgeted_restore_texture_binding(operation, previous_active_unit, previous_texture);
        gl_budgeted_finish_operation(budgeter, operation);
        return;
    }

    if operation.kind == .DEFINE_TEXTURE_2D {
        gl_budgeted_set_captured_unpack_state(operation);
        gl_define_texture_2d_image_for_active_texture_unit(
            operation.binding_target,
            operation.mipmap_level,
            operation.internal_format,
            operation.width,
            operation.height,
            operation.border,
            operation.pixel_format,
            operation.pixel_data_type,
            operation.data,
        );
        gl_budgeted_set_unpack_state(previous_unpack_state);
        gl_budgeted_restore_texture_binding(operation, previous_active_unit, previous_texture);
        gl_budgeted_finish_operation(budgeter, operation);
        return;
    }

    if operation.kind == .DEFINE_TEXTURE_3D {
        gl_budgeted_set_captured_unpack_state(operation);
        gl_define_3d_image_for_texture_bound_to_binding_target_of_active_texture_unit(
            operation.binding_target,
            operation.mipmap_level,
            operation.internal_format,
            operation.width,
            operation.height,
            operation.depth,
            operation.border,
            operation.pixel_format,
            operation.pixel_data_type,
            operation.data,
        );
        gl_budgeted_set_unpack_state(previous_unpack_state);
        gl_budgeted_restore_texture_binding(operation, previous_active_unit, previous_texture);
        gl_budgeted_finish_operation(budgeter, operation);
        return;
    }

    // Supplying bytes_per_row opts into row chunking and also states that the
    // source is tightly packed. Otherwise preserve the exact API operation as
    // one driver call.
    if operation.bytes_per_row > 0 && operation.height > 0 && operation.depth > 0 {
        rows_per_chunk := max(
            cast(s64) 1,
            budgeter.maximum_texture_chunk_bytes / operation.bytes_per_row,
        );
        total_rows := cast(s64) operation.height * cast(s64) operation.depth;
        layer := operation.completed_rows / cast(s64) operation.height;
        row_in_layer := operation.completed_rows % cast(s64) operation.height;
        rows_left_in_layer := cast(s64) operation.height - row_in_layer;
        row_count := min(rows_per_chunk, rows_left_in_layer, total_rows - operation.completed_rows);

        gl_set_integer_pixel_storage_parameter(GL_UNPACK_ALIGNMENT, 1);
        gl_set_integer_pixel_storage_parameter(GL_UNPACK_ROW_LENGTH, 0);
        gl_set_integer_pixel_storage_parameter(GL_UNPACK_SKIP_PIXELS, 0);
        gl_set_integer_pixel_storage_parameter(GL_UNPACK_SKIP_ROWS, 0);
        gl_update_3d_subimage_of_texture_bound_to_binding_target_of_active_texture_unit(
            operation.binding_target,
            operation.mipmap_level,
            operation.x_offset,
            operation.y_offset + cast(GLint) row_in_layer,
            operation.z_offset + cast(GLint) layer,
            operation.width,
            cast(GLsizei) row_count,
            1,
            operation.pixel_format,
            operation.pixel_data_type,
            operation.data + operation.completed_rows * operation.bytes_per_row,
        );

        completed_bytes := min(
            operation.data_byte_count - operation.completed_byte_count,
            row_count * operation.bytes_per_row,
        );
        operation.completed_rows += row_count;
        operation.completed_byte_count += completed_bytes;
        operation.completed_work += completed_bytes;
        budgeter.completed_work += completed_bytes;
        gl_budgeted_set_unpack_state(previous_unpack_state);
        gl_budgeted_restore_texture_binding(operation, previous_active_unit, previous_texture);

        if operation.completed_rows >= total_rows {
            gl_budgeted_finish_operation(budgeter, operation);
        }
        return;
    }

    gl_budgeted_set_captured_unpack_state(operation);
    gl_update_3d_subimage_of_texture_bound_to_binding_target_of_active_texture_unit(
        operation.binding_target,
        operation.mipmap_level,
        operation.x_offset,
        operation.y_offset,
        operation.z_offset,
        operation.width,
        operation.height,
        operation.depth,
        operation.pixel_format,
        operation.pixel_data_type,
        operation.data,
    );
    gl_budgeted_set_unpack_state(previous_unpack_state);
    gl_budgeted_restore_texture_binding(operation, previous_active_unit, previous_texture);
    gl_budgeted_finish_operation(budgeter, operation);
}

gl_process_budgeted_operations :: (
    budgeter: *GL_Budgeter,
    time_budget_seconds: float64 = 0.003,
) {
    if budgeter.next_operation_index >= budgeter.operations.count return;

    start_time := current_time_monotonic();
    did_work := false;
    while budgeter.next_operation_index < budgeter.operations.count {
        gl_process_one_budgeted_operation(budgeter);
        did_work = true;

        // Always make forward progress even if the first indivisible call is
        // slower than the requested budget.
        if did_work && time_budget_seconds > 0.0 &&
           to_float64_seconds(current_time_monotonic() - start_time) >= time_budget_seconds {
            break;
        }
    }
}

gl_budgeted_operations_complete :: (budgeter: *GL_Budgeter) -> bool {
    return budgeter.next_operation_index >= budgeter.operations.count;
}

gl_budgeted_operations_progress :: (budgeter: *GL_Budgeter) -> float32 {
    if budgeter.total_work <= 0 return ifx gl_budgeted_operations_complete(budgeter) then 1.0 else 0.0;
    return clamp(
        cast(float32) budgeter.completed_work / cast(float32) budgeter.total_work,
        0.0,
        1.0,
    );
}

deinit :: (budgeter: *GL_Budgeter) {
    for *operation: budgeter.operations {
        gl_budgeted_release_operation_data(operation);
    }
    array_free(budgeter.operations);
    budgeter.* = .{};
}
