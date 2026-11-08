#scope_file
Capture_File :: #import "File";
Image_Write :: #import "stb_image_write";
#scope_export

// Read the currently bound read framebuffer through better_api. PNG rows are
// flipped for image-file convention; raw float captures retain OpenGL's order.
gl_write_bound_read_framebuffer_png :: (path: string, width: s32, height: s32) -> bool {
    pixels: [..] u8;
    defer array_free(pixels);
    array_resize(*pixels,cast(int) width*height*3);
    alignment: GLint;
    gl_get_integer_state_parameter(GL_PACK_ALIGNMENT,*alignment);
    gl_set_pixel_readback_row_alignment(1);
    defer gl_set_pixel_readback_row_alignment(alignment);
    gl_read_pixels_from_bound_read_framebuffer(0,0,xx width,xx height,GL_RGB,GL_UNSIGNED_BYTE,pixels.data);
    for row: 0..height/2-1 {
        for col: 0..width*3-1 swap(*pixels[row*width*3+col],*pixels[(height-row-1)*width*3+col]);
    }
    return Image_Write.stbi_write_png(temp_c_string(path),width,height,3,pixels.data,width*3) != 0;
}

gl_write_bound_read_framebuffer_rgba32f :: (path: string, width: s32, height: s32) -> bool {
    pixels: [..] Vector4;
    defer array_free(pixels);
    array_resize(*pixels,cast(int) width*height);
    gl_read_pixels_from_bound_read_framebuffer(0,0,xx width,xx height,GL_RGBA,GL_FLOAT,pixels.data);
    return Capture_File.write_entire_file(path,string.{pixels.count*size_of(Vector4),cast(*u8) pixels.data});
}
