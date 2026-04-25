Local_To_World_Matrix_Pool :: struct {
    NUM_MATRICES :: 1024;
    current_index : u32 = 0;
    free_indices : [..] u32;
    matrices : [NUM_MATRICES] Matrix4;
    gl_uniform_buffer_handle : GLuint;
}

init :: (using pool : *Local_To_World_Matrix_Pool) {
    for 0..NUM_MATRICES-1
        matrices[it] = Matrix4_Identity;

    glGenBuffers(1, *gl_uniform_buffer_handle);
    glBindBuffer(GL_UNIFORM_BUFFER, gl_uniform_buffer_handle);
    glBufferData(GL_UNIFORM_BUFFER, NUM_MATRICES * size_of(Matrix4), matrices.data, GL_DYNAMIC_DRAW);
    glBindBufferBase(GL_UNIFORM_BUFFER, 0, gl_uniform_buffer_handle);
}

deinit :: (using pool : *Local_To_World_Matrix_Pool) {
    array_free(free_indices);
    glDeleteBuffers(1, *gl_uniform_buffer_handle);
    gl_uniform_buffer_handle = 0;
    current_index = 0;
}

alloc_index :: (using pool : *Local_To_World_Matrix_Pool) -> u32, bool {
    if free_indices.count > 0 {
        return pop(*free_indices), true;
    }
    if current_index >= NUM_MATRICES {
        log("ran out of local_to_world matrix slots");
        return 0, false;
    }
    idx := current_index;
    current_index += 1;
    return idx, true;
}

free_index :: (using pool : *Local_To_World_Matrix_Pool, idx : u32) {
    matrices[idx] = Matrix4_Identity;
    array_add(*free_indices, idx);
}

set_matrix :: (using pool : *Local_To_World_Matrix_Pool, idx : u32, matrix : Matrix4) {
    matrices[idx] = matrix;
}

upload_to_gpu :: (using pool : *Local_To_World_Matrix_Pool) {
    glBindBuffer(GL_UNIFORM_BUFFER, gl_uniform_buffer_handle);
    glBindBufferBase(GL_UNIFORM_BUFFER, 0, gl_uniform_buffer_handle);
    glBufferSubData(GL_UNIFORM_BUFFER, 0, size_of(Matrix4) * current_index, matrices.data);
}
