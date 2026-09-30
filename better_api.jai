/*
terminology used by this OpenGL wrapper file

the definitions are ordered so each definition only depends on terminology
introduced above it.

fundamental OpenGL concepts

- driver or implementation: the software that implements OpenGL and translates
  API calls into work for the graphics hardware.
- context: one OpenGL instance created by the driver and associated with a
  thread and usually a window. It contains driver-managed resources and
  settings.
- state: values remembered by the current context between API calls.
- object: a driver-managed resource owned by a context.
- object name, handle, or id: a GLuint integer that identifies an object. The
  value identifies driver-managed state; it is not a CPU pointer to the data.
- create: ask the driver for a new object name.
- delete: release an object name and its driver-managed resources.
- enum token: a named GLenum integer such as GL_TEXTURE_2D or GL_LESS. An
  enum token selects one meaning from a set understood by an API call.
- state slot: one place in the context where an object name or setting is
  remembered.
- binding target: an enum token that selects a state slot and the kind of
  operation associated with that slot. A target is not an object.
- bind: store an object name in the state slot selected by a binding target.
- bound object: the object whose name is currently stored in a selected state
  slot. Later calls can operate on this object without receiving its name.
- active: the context selection used implicitly by later calls. Specific
  kinds of active selections are defined below.
- parameter: a named property of an object or the context.
- set a parameter: replace the current value of a parameter.
- query a parameter: read the current value of a parameter.

graphics pipeline input and output

- graphics pipeline: the ordered processing stages that turn submitted geometry
  into output values for covered locations.
- vertex: one geometric input record, such as a mesh position together with
  values associated with that position.
- primitive mode: the rule for assembling vertices, such as GL_POINTS,
  GL_LINES, or GL_TRIANGLES.
- primitive: one point, line, or triangle assembled according to a primitive
  mode.
- rasterization: conversion of a primitive into covered output locations and
  interpolated values.
- fragment: one candidate contribution produced by rasterization. Later tests
  determine whether it is discarded or accepted.

shaders and uniforms

- shader: code compiled for one programmable graphics pipeline stage.
- vertex shader: a shader that processes one submitted vertex and produces a
  transformed vertex plus values for later stages.
- fragment shader: a shader that processes one fragment and produces output
  values such as color.
- shader program: one or more linked shader stages that can execute together.
- active shader program: the shader program selected by
  gl_set_active_shader_program. Draws and uniform setter calls use this program.
- uniform: shader input state shared by many shader invocations instead of
  being supplied separately to each invocation.
- uniform location: a program-specific integer identifying one uniform. A
  location obtained from one shader program must not be used with another.

buffers and vertex input

- buffer: an object containing linear byte storage. A buffer has no intrinsic
  interpretation; its binding target and the operation determine how its bytes
  are used.
- buffer binding target: a binding target for a buffer, such as
  GL_ARRAY_BUFFER, GL_ELEMENT_ARRAY_BUFFER, or GL_UNIFORM_BUFFER.
- buffer bound to a binding target: the buffer object currently selected for
  operations using that buffer binding target.
- buffer storage: the byte allocation owned by a buffer object.
- initial data: optional CPU bytes copied into newly allocated buffer storage.
  Passing null allocates storage without supplying its contents.
- usage: a hint such as GL_STATIC_DRAW or GL_DYNAMIC_DRAW describing how the
  application expects to update and use buffer storage.
- byte offset: a position measured in bytes from the beginning of buffer
  storage.
- subdata: a byte range written into buffer storage that already exists.
- vertex array: a vertex array object, commonly called a VAO. It records how
  vertex data is read and which buffer supplies vertex-selection integers.
- bound vertex array: the vertex array currently selected by
  gl_bind_vertex_array.
- vertex attribute: one named field of a vertex, such as position, normal,
  texture coordinates, color, bone indices, or bone weights.
- attribute location: a program-specific integer identifying one vertex shader
  input.
- vertex attribute pointer: the configuration that tells a vertex array which
  buffer contains an attribute and how to decode its component count, type,
  stride, normalization, and starting byte offset.
- element or index buffer: the buffer bound to GL_ELEMENT_ARRAY_BUFFER while a
  vertex array is bound. The vertex array remembers this binding.
- index: an integer in an element buffer that selects one vertex.
- draw call: an API call that asks the graphics pipeline to process vertices
  with the active shader program and current rendering state.
- non-indexed draw: a draw call that processes a consecutive vertex range.
- indexed draw: a draw call that reads indices from the element buffer recorded
  by the bound vertex array and uses them to select vertices.

textures and sampling

- texture: an object containing stored sample data together with sampling
  parameters.
- texel: one stored element of a texture.
- texture dimensionality: the coordinate shape used to address texels. A 1D
  texture has width, a 2D texture has width and height, and a 3D texture has
  width, height, and depth.
- texture binding target: a binding target describing a texture kind and
  dimensionality, such as GL_TEXTURE_1D, GL_TEXTURE_2D, GL_TEXTURE_2D_ARRAY,
  GL_TEXTURE_3D, or GL_TEXTURE_CUBE_MAP.
- texture unit: one numbered group of context state slots. Each texture unit has
  one slot for each texture binding target and makes its bound textures
  available to shaders. Unit numbers begin at 0.
- sampler uniform: a uniform whose integer value selects a texture unit. The
  shader value 0 selects unit 0; it does not contain a texture object name.
- active texture unit: the texture unit selected by
  gl_set_active_texture_unit. Texture binding and most texture manipulation
  calls use this unit implicitly. GL_TEXTURE0 selects unit 0,
  GL_TEXTURE0 + 1 selects unit 1, and so on.
- texture binding: the association between a texture object and one texture
  binding target slot inside one texture unit.
- texture bound to a binding target of the active texture unit: the texture
  object found by first taking the active texture unit and then taking the slot
  named by the texture binding target. Texture calls without a texture handle
  operate on this implicit object.
- texture array: a texture containing multiple same-sized image slices.
- texture array layer: one image slice inside a texture array. Selecting a
  layer chooses the slice without choosing its resolution.
- cubemap: a texture containing six square directions used to represent values
  surrounding a point.
- cubemap face: one of the six square directions stored in a cubemap.
- texture level or mipmap level: one numbered resolution inside a texture.
  Level 0 is the full-resolution image, level 1 normally halves each spatial
  dimension, and later levels continue halving until reaching 1x1. Texture
  array layer count and cubemap face count do not shrink with the level.
- base level: the highest-resolution mipmap level used for sampling, normally
  level 0.
- mipmap: the sequence of progressively smaller texture levels used to reduce
  aliasing and sampling cost when a texture appears small on screen.
- texture image: texel storage defined for one texture level and image target.
  For a texture array, one level contains every layer. For a cubemap, each face
  has an image at every level.
- texture storage: driver-managed memory owned by a texture for its texture
  images.
- internal format: the representation used by the driver to store texels, such
  as GL_RGBA8 or a compressed format. It determines GPU memory layout and
  precision.
- pixel format: the channel arrangement of CPU data transferred to or from a
  texture image, such as GL_RGBA.
- pixel data type: the scalar representation of transferred channel values,
  such as GL_UNSIGNED_BYTE or GL_FLOAT.
- texture coordinate: one or more values supplied to a texture sampling
  operation to select a location in a texture.
- texture parameter: state stored on a texture object that controls its storage
  or sampling behavior.
- filter: the rule used to reconstruct a sampled value from nearby texels and,
  when a texture covers fewer output locations than texels, possibly nearby
  mipmap levels.
- wrap mode: the rule used when texture coordinates fall outside the normal
  coordinate interval.
- compressed texture: a texture whose internal format stores texels in
  compressed blocks. CPU upload data may still use an unpacked pixel format.
- compressed image size: the byte count occupied by one compressed texture
  level, including all layers when the texture is an array.
- subimage update: replacement of a region inside texture storage that was
  already defined.
- pixel storage parameter: context state describing the CPU memory layout of
  rows transferred between CPU memory and OpenGL.
- pack alignment: row alignment used when OpenGL writes pixel data into CPU
  memory.
- unpack alignment: row alignment used when OpenGL reads pixel data from CPU
  memory.

framebuffers and rendering destinations

- framebuffer: a collection of images that can receive rendering output.
- default framebuffer: the framebuffer supplied by the window system.
- renderbuffer: an object containing image storage intended for framebuffer
  use rather than shader texture sampling.
- framebuffer object: an application-created framebuffer that can use
  application-selected images as rendering destinations.
- attachment: a named framebuffer slot that can refer to a texture image or a
  renderbuffer.
- color buffer: image storage attached to a framebuffer for fragment color
  output.
- depth buffer: image storage attached to a framebuffer for fragment depth.
- stencil buffer: image storage attached to a framebuffer for integer values
  used to accept or reject fragments.
- draw framebuffer: the framebuffer that receives draw and clear operations.
- read framebuffer: the framebuffer used as the source of pixel read and copy
  operations.
- framebuffer binding target: a binding target selecting the draw framebuffer,
  read framebuffer, or both. The tokens are GL_DRAW_FRAMEBUFFER,
  GL_READ_FRAMEBUFFER, and GL_FRAMEBUFFER.
- draw buffer: the color attachment or default-framebuffer destination that
  receives fragment color. This term is unrelated to a buffer object.
- read buffer: the color source selected for framebuffer read operations. This
  term is also unrelated to a buffer object.
- framebuffer status or completeness: whether a framebuffer has a valid
  combination of attachments for its requested role.
- viewport: the rectangle that maps graphics pipeline output positions to
  pixel coordinates in the rendering destination.
- pixel readback: copying values from the read framebuffer into CPU memory.
- clear value: a context value used by a later clear operation.
- clear: filling selected framebuffer images with their configured clear
  values.

fragment tests and blending

- depth test: comparison between an incoming fragment depth and the value in the
  depth buffer. A failing fragment is discarded before it updates framebuffer
  images.
- depth-test pass condition: the comparison rule, such as GL_LESS or GL_EQUAL.
- depth write: whether a fragment that passes testing may replace the value in
  the depth buffer.
- blending: combining an incoming fragment value with the value already stored
  in a draw buffer.
- source blend factor: the multiplier applied to the incoming fragment value.
- destination blend factor: the multiplier applied to the stored draw-buffer
  value.
- wireframe mode: triangle rasterization that emits triangle edges instead of
  filled interiors.

how to read a long wrapper name

`gl_get_integer_parameter_for_texture_level_bound_to_binding_target_of_active_texture_unit`
means:

1. gl_set_active_texture_unit previously selected one texture unit.
2. a texture binding previously associated a texture with a texture binding
   target inside that unit.
3. the binding_target argument selects that target slot.
4. the mipmap_level argument selects one texture level in the bound texture.
5. the parameter_name argument selects the parameter to query at that level.
6. the resulting integer is written through parameter_value.

these explicit names expose state that the original OpenGL function names leave
implicit.
*/

enable_wireframe_mode :: () { glPolygonMode(GL_FRONT_AND_BACK, GL_LINE); }
disable_wireframe_mode :: () { glPolygonMode(GL_FRONT_AND_BACK, GL_FILL); }

gl_set_depth_writes_enabled :: glDepthMask;
gl_set_depth_test_pass_condition :: glDepthFunc;

gl_discard_fragments_that_fail_depth_test :: (enabled: bool) {
    if enabled then glEnable(GL_DEPTH_TEST);
    else glDisable(GL_DEPTH_TEST);
}

gl_enable_blending :: () { glEnable(GL_BLEND); }
gl_disable_blending :: () { glDisable(GL_BLEND); }

gl_set_blend_function :: (source_factor: GLenum, destination_factor: GLenum) {
    glBlendFunc(source_factor, destination_factor);
}

gl_set_separate_blend_function :: (
    source_rgb_factor: GLenum,
    destination_rgb_factor: GLenum,
    source_alpha_factor: GLenum,
    destination_alpha_factor: GLenum,
) {
    glBlendFuncSeparate(
        source_rgb_factor,
        destination_rgb_factor,
        source_alpha_factor,
        destination_alpha_factor,
    );
}

gl_clear_depth_buffer :: () { glClear(GL_DEPTH_BUFFER_BIT); }

gl_set_active_shader_program :: (program: GLuint) { glUseProgram(program); }
gl_clear_active_shader_program :: () { glUseProgram(0); }
gl_delete_shader_program :: (program: GLuint) { glDeleteProgram(program); }

gl_set_active_texture_unit :: (texture_unit: GLenum) {
    glActiveTexture(texture_unit);
}

gl_bind_texture_to_binding_target_of_active_texture_unit :: (target: GLenum, texture: GLuint) {
    glBindTexture(target, texture);
}

gl_define_texture_2d_image_for_active_texture_unit :: glTexImage2D;
gl_set_integer_parameter_for_texture_bound_to_binding_target_of_active_texture_unit :: glTexParameteri;

gl_get_integer_parameter_for_texture_level_bound_to_binding_target_of_active_texture_unit :: (
    binding_target: GLenum,
    mipmap_level: GLint,
    parameter_name: GLenum,
    parameter_value: *GLint,
) {
    glGetTexLevelParameteriv(
        binding_target,
        mipmap_level,
        parameter_name,
        parameter_value,
    );
}

gl_define_1d_image_for_texture_bound_to_binding_target_of_active_texture_unit :: (
    binding_target: GLenum,
    mipmap_level: GLint,
    internal_format: GLint,
    width: GLsizei,
    border: GLint,
    pixel_format: GLenum,
    pixel_data_type: GLenum,
    pixels: *void,
) {
    glTexImage1D(
        binding_target,
        mipmap_level,
        internal_format,
        width,
        border,
        pixel_format,
        pixel_data_type,
        pixels,
    );
}

gl_define_3d_image_for_texture_bound_to_binding_target_of_active_texture_unit :: (
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
) {
    glTexImage3D(
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
}

gl_update_3d_subimage_of_texture_bound_to_binding_target_of_active_texture_unit :: (
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
) {
    glTexSubImage3D(
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
}

gl_set_float_parameter_for_texture_bound_to_binding_target_of_active_texture_unit :: (
    binding_target: GLenum,
    parameter_name: GLenum,
    parameter_value: GLfloat,
) {
    glTexParameterf(binding_target, parameter_name, parameter_value);
}

gl_set_float_vector_parameter_for_texture_bound_to_binding_target_of_active_texture_unit :: (
    binding_target: GLenum,
    parameter_name: GLenum,
    parameter_values: *GLfloat,
) {
    glTexParameterfv(binding_target, parameter_name, parameter_values);
}

gl_get_float_values_for_state_parameter :: (
    parameter_name: GLenum,
    values: *GLfloat,
) {
    glGetFloatv(parameter_name, values);
}

gl_set_integer_pixel_storage_parameter :: (
    parameter_name: GLenum,
    parameter_value: GLint,
) {
    glPixelStorei(parameter_name, parameter_value);
}

gl_create_texture :: () -> GLuint {
    texture: GLuint;
    glGenTextures(1, *texture);
    return texture;
}

gl_create_textures :: (textures: [] GLuint) {
    if textures.count == 0 return;
    glGenTextures(cast(GLsizei) textures.count, textures.data);
}

gl_delete_texture :: (texture: GLuint) {
    glDeleteTextures(1, *texture);
}

gl_delete_textures :: (textures: [] GLuint) {
    if textures.count == 0 return;
    glDeleteTextures(cast(GLsizei) textures.count, textures.data);
}

gl_create_framebuffer :: () -> GLuint {
    framebuffer: GLuint;
    glGenFramebuffers(1, *framebuffer);
    return framebuffer;
}

gl_delete_framebuffer :: (framebuffer: GLuint) {
    glDeleteFramebuffers(1, *framebuffer);
}

gl_create_renderbuffer :: () -> GLuint {
    renderbuffer: GLuint;
    glGenRenderbuffers(1, *renderbuffer);
    return renderbuffer;
}

gl_delete_renderbuffer :: (renderbuffer: GLuint) {
    glDeleteRenderbuffers(1, *renderbuffer);
}

gl_create_vertex_array :: () -> GLuint {
    vertex_array: GLuint;
    glGenVertexArrays(1, *vertex_array);
    return vertex_array;
}

gl_delete_vertex_array :: (vertex_array: GLuint) {
    glDeleteVertexArrays(1, *vertex_array);
}

gl_create_buffer :: () -> GLuint {
    buffer: GLuint;
    glGenBuffers(1, *buffer);
    return buffer;
}

gl_delete_buffer :: (buffer: GLuint) {
    glDeleteBuffers(1, *buffer);
}

gl_allocate_storage_for_buffer_bound_to_binding_target :: (
    binding_target: GLenum,
    byte_count: GLsizeiptr,
    initial_data: *void,
    usage: GLenum,
) {
    glBufferData(binding_target, byte_count, initial_data, usage);
}

gl_bind_framebuffer_to_binding_target :: (
    binding_target: GLenum,
    framebuffer: GLuint,
) {
    glBindFramebuffer(binding_target, framebuffer);
}

gl_bind_renderbuffer :: (renderbuffer: GLuint) {
    glBindRenderbuffer(GL_RENDERBUFFER, renderbuffer);
}

gl_allocate_storage_for_bound_renderbuffer :: (
    internal_format: GLenum,
    width: GLsizei,
    height: GLsizei,
) {
    glRenderbufferStorage(GL_RENDERBUFFER, internal_format, width, height);
}

gl_attach_renderbuffer_to_framebuffer_bound_to_binding_target :: (
    framebuffer_binding_target: GLenum,
    attachment: GLenum,
    renderbuffer: GLuint,
) {
    glFramebufferRenderbuffer(
        framebuffer_binding_target,
        attachment,
        GL_RENDERBUFFER,
        renderbuffer,
    );
}

gl_attach_2d_texture_image_to_framebuffer_bound_to_binding_target :: (
    framebuffer_binding_target: GLenum,
    attachment: GLenum,
    texture_image_target: GLenum,
    texture: GLuint,
    mipmap_level: GLint,
) {
    glFramebufferTexture2D(
        framebuffer_binding_target,
        attachment,
        texture_image_target,
        texture,
        mipmap_level,
    );
}

gl_get_status_of_framebuffer_bound_to_binding_target :: (
    binding_target: GLenum,
) -> GLenum {
    return glCheckFramebufferStatus(binding_target);
}

gl_set_draw_buffer_for_bound_draw_framebuffer :: (draw_buffer: GLenum) {
    glDrawBuffer(draw_buffer);
}

gl_set_read_buffer_for_bound_read_framebuffer :: (read_buffer: GLenum) {
    glReadBuffer(read_buffer);
}

gl_set_viewport_rectangle :: (
    x: GLint,
    y: GLint,
    width: GLsizei,
    height: GLsizei,
) {
    glViewport(x, y, width, height);
}

gl_set_color_buffer_clear_value :: (
    red: GLfloat,
    green: GLfloat,
    blue: GLfloat,
    alpha: GLfloat,
) {
    glClearColor(red, green, blue, alpha);
}

gl_clear_color_and_depth_buffers :: () {
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

gl_generate_mipmap_levels_for_texture_bound_to_binding_target_of_active_texture_unit :: (
    binding_target: GLenum,
) {
    glGenerateMipmap(binding_target);
}

gl_read_pixels_from_bound_read_framebuffer :: (
    x: GLint,
    y: GLint,
    width: GLsizei,
    height: GLsizei,
    pixel_format: GLenum,
    pixel_data_type: GLenum,
    destination: *void,
) {
    glReadPixels(
        x, y, width, height,
        pixel_format, pixel_data_type, destination,
    );
}

gl_set_pixel_readback_row_alignment :: (alignment: GLint) {
    glPixelStorei(GL_PACK_ALIGNMENT, alignment);
}

gl_get_uniform_location_in_shader_program :: (
    shader_program: GLuint,
    uniform_name: *GLchar,
) -> GLint {
    return glGetUniformLocation(shader_program, uniform_name);
}
gl_bind_vertex_array :: (vertex_array: GLuint) {
    glBindVertexArray(vertex_array);
}

gl_bind_buffer_to_binding_target :: (binding_target: GLenum, buffer: GLuint) {
    glBindBuffer(binding_target, buffer);
}

gl_update_subdata_in_buffer_bound_to_binding_target :: (
    binding_target: GLenum,
    byte_offset: GLintptr,
    byte_count: GLsizeiptr,
    data: *void,
) {
    glBufferSubData(binding_target, byte_offset, byte_count, data);
}

gl_get_vertex_attribute_location_in_shader_program :: (
    shader_program: GLuint,
    attribute_name: *GLchar,
) -> GLint {
    return glGetAttribLocation(shader_program, attribute_name);
}

gl_enable_vertex_attribute_array :: (attribute_index: GLuint) {
    glEnableVertexAttribArray(attribute_index);
}

gl_define_vertex_attribute_pointer :: (
    attribute_index: GLuint,
    component_count: GLint,
    component_type: GLenum,
    normalized: GLboolean,
    byte_stride: GLsizei,
    pointer: *void,
) {
    glVertexAttribPointer(
        attribute_index,
        component_count,
        component_type,
        normalized,
        byte_stride,
        pointer,
    );
}

gl_define_integer_vertex_attribute_pointer :: (
    attribute_index: GLuint,
    component_count: GLint,
    component_type: GLenum,
    byte_stride: GLsizei,
    pointer: *void,
) {
    glVertexAttribIPointer(
        attribute_index,
        component_count,
        component_type,
        byte_stride,
        pointer,
    );
}

gl_draw_vertices_from_bound_vertex_array :: (
    primitive_mode: GLenum,
    first_vertex: GLint,
    vertex_count: GLsizei,
) {
    glDrawArrays(primitive_mode, first_vertex, vertex_count);
}

gl_draw_indexed_vertices_from_bound_vertex_array :: (
    primitive_mode: GLenum,
    index_count: GLsizei,
    index_type: GLenum,
    indices: *void,
) {
    glDrawElements(primitive_mode, index_count, index_type, indices);
}

GL_Framebuffer_State :: struct {
    draw_framebuffer: GLuint;
    read_framebuffer: GLuint;
    viewport: [4] GLint;
    draw_buffer: GLenum;
    read_buffer: GLenum;
}

gl_capture_framebuffer_state :: () -> GL_Framebuffer_State {
    result: GL_Framebuffer_State;
    integer_value: GLint;

    glGetIntegerv(GL_DRAW_FRAMEBUFFER_BINDING, *integer_value);
    result.draw_framebuffer = cast(GLuint) integer_value;
    glGetIntegerv(GL_READ_FRAMEBUFFER_BINDING, *integer_value);
    result.read_framebuffer = cast(GLuint) integer_value;
    glGetIntegerv(GL_VIEWPORT, result.viewport.data);
    glGetIntegerv(GL_DRAW_BUFFER, *integer_value);
    result.draw_buffer = cast(GLenum) integer_value;
    glGetIntegerv(GL_READ_BUFFER, *integer_value);
    result.read_buffer = cast(GLenum) integer_value;

    return result;
}

gl_restore_framebuffer_state :: (state: GL_Framebuffer_State) {
    gl_bind_framebuffer_to_binding_target(GL_DRAW_FRAMEBUFFER, state.draw_framebuffer);
    gl_set_draw_buffer_for_bound_draw_framebuffer(state.draw_buffer);
    gl_bind_framebuffer_to_binding_target(GL_READ_FRAMEBUFFER, state.read_framebuffer);
    gl_set_read_buffer_for_bound_read_framebuffer(state.read_buffer);
    gl_set_viewport_rectangle(
        state.viewport[0],
        state.viewport[1],
        cast(GLsizei) state.viewport[2],
        cast(GLsizei) state.viewport[3],
    );
}

gl_set_uniform_1f_on_active_shader_program :: (location: GLint, value: GLfloat) {
    glUniform1f(location, value);
}

gl_set_uniform_1i_on_active_shader_program :: (location: GLint, value: GLint) {
    glUniform1i(location, value);
}

gl_set_uniform_1ui_on_active_shader_program :: (location: GLint, value: GLuint) {
    glUniform1ui(location, value);
}

gl_set_uniform_2f_on_active_shader_program :: (location: GLint, x: GLfloat, y: GLfloat) {
    glUniform2f(location, x, y);
}

gl_set_uniform_3f_on_active_shader_program :: (location: GLint, x: GLfloat, y: GLfloat, z: GLfloat) {
    glUniform3f(location, x, y, z);
}

gl_set_uniform_4f_on_active_shader_program :: (location: GLint, x: GLfloat, y: GLfloat, z: GLfloat, w: GLfloat) {
    glUniform4f(location, x, y, z, w);
}

gl_set_uniform_matrix_3fv_on_active_shader_program :: (location: GLint, count: GLsizei, transpose: GLboolean, values: *GLfloat) {
    glUniformMatrix3fv(location, count, transpose, values);
}

gl_set_uniform_matrix_4fv_on_active_shader_program :: (location: GLint, count: GLsizei, transpose: GLboolean, values: *GLfloat) {
    glUniformMatrix4fv(location, count, transpose, values);
}
