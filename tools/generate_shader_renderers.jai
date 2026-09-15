#import "Basic";
#import "Math";
#import "GL";
#import "String";
#import "File";
#import "File_Utilities";
#import "Hash_Table";

#import,file "../first_fit_virtual_allocator.jai";

create_shader_program :: (vertex_source: string, fragment_source: string) -> program_handle: GLuint, success: bool {
    return 0, false;
}

#load "../renderer_generation_per_shader.jai";

main :: () {
    create_code_to_render_stuff_with_shader_program_files();
}
