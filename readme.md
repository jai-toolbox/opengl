this module helps us use opengl in a way that allows us to actually focus on making high level graphical systems, it automates the creation of VBO/VAO away and for every shader you get, you get a collection of code that automates a lot of the annoyances of setting up that shader. 

Think of it like this, for every shader, you get a renderer thing and a renderable, you just have to construct renderables, buffer them into the renderer, queue it up for rendering and then render it. What was just described is the classic retained rendering mode, which is useful for when there are permanent objects that should stay around for a while.

We also support rendering transient, smaller geometry using immediate rendering, which you can see for yourself in the renderers.

# specific notes for particular shaders


## border normal
The border normal shader escapes regular usage because it actually requires the object be drawn with a regular shader first, to make this concrete just check this out:

```jai 
normal_renderer: Camera_Per_Object_Transform_Color_Renderer;
border_renderer: Camera_Per_Object_Transform_Normal_Border_Renderer;

init(*normal_renderer);
init(*border_renderer);

normal_renderable: Camera_Per_Object_Transform_Normal_Renderable;
border_renderable: Camera_Per_Object_Transform_Normal_Border_Renderable;

assign_geometry(*normal_renderable, my_geometry);
assign_geometry(*border_renderable, my_geometry);

buffer_object(*normal_renderer, *normal_renderable);
buffer_object(*border_renderer, *border_renderable);

transform := make_translation_matrix4(0, 0, 0);
set_local_to_world_matrix(*normal_renderer, normal_renderable, transform);
set_local_to_world_matrix(*border_renderer, border_renderable, transform);

while running {
    // this doesn't clear anything yet, just sets what value to use when clearing
    glClearColor(0.07, 0.13, 0.17, 1.0);

    // color buffer: fill every pixel with the clear color we just set
    // depth buffer: reset every pixel's depth to 1.0 (far plane)
    // stencil buffer: reset every pixel's stencil value to 0
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);

    // turn on stencil testing. every fragment will now be checked against the stencil buffer before being written to the screen
    glEnable(GL_STENCIL_TEST);

    // configure what happens to the stencil buffer value when:
    //   arg 1 - stencil test fails:                    GL_KEEP (don't change it)
    //   arg 2 - stencil passes but depth test fails:   GL_KEEP (don't change it)
    //   arg 3 - both stencil and depth pass:           GL_REPLACE (write the reference value)
    glStencilOp(GL_KEEP, GL_KEEP, GL_REPLACE);

    // Pass 1: draw bordered object normally, write 1s to stencil

    // set the stencil test rule:
    //   GL_ALWAYS = stencil test always passes, every fragment gets through
    //   1         = the reference value, this is what gets written on GL_REPLACE
    //   0xFF      = bitmask applied before comparing
    // so: every fragment that passes the depth test writes 1 into the stencil buffer
    glStencilFunc(GL_ALWAYS, 1, 0xFF);

    // enable writing to the stencil buffer, 0xFF means all bits are writable
    glStencilMask(0xFF);

    // bind the normal shader program. all draw calls use this shader until another glUseProgram is called
    glUseProgram(normal_renderer.shader_program_gl_handle);

    set_camera_to_clip_uniform(*normal_renderer, camera_to_clip);
    set_world_to_camera_uniform(*normal_renderer, world_to_camera);

    queue_render(*normal_renderer, normal_renderable);

    // draw the object normally, everywhere it draws a pixel, the stencil buffer gets a 1, after this the stencil buffer looks like:
    //   0 0 0 0 0 0 0
    //   0 0 1 1 1 0 0
    //   0 1 1 1 1 1 0
    //   0 0 1 1 1 0 0
    //   0 0 0 0 0 0 0
    render(*normal_renderer);

    // Pass 2: draw border, only where stencil != 1

    // only pass the stencil test if the stencil value at this pixel is NOT equal to 1.
    // so fragments can only draw where the original object didn't draw
    glStencilFunc(GL_NOTEQUAL, 1, 0xFF);

    // disable writing to the stencil buffer. we don't want the border to modify stencil values
    glStencilMask(0x00);

    // turn off depth testing so the border isn't hidden behind other geometry. we want the outline to always be visible
    glDisable(GL_DEPTH_TEST);

    // switch to the border shader which extrudes vertices along normals
    glUseProgram(border_renderer.shader_program_gl_handle);

    set_camera_to_clip_uniform(*border_renderer, camera_to_clip);
    set_world_to_camera_uniform(*border_renderer, world_to_camera);
    set_border_thickness_uniform(*border_renderer, 0.03);
    set_rgb_color_uniform(*border_renderer, .{1.0, 0.5, 0.0});

    queue_render(*border_renderer, border_renderable);

    // draw the same geometry but extruded outward. because of the stencil test, only pixels
    // that fall OUTSIDE the original object silhouette get drawn, which is the border
    //   B B B B B B B B B
    //   B B B X X X B B B     X = blocked by stencil (original object)
    //   B B X X X X X B B    B = passes stencil, drawn as border
    //   B B X X X X X B B
    //   B B B X X X B B B
    //   B B B B B B B B B
    render(*border_renderer);

    // re-enable stencil writing so next frame's glClear can actually clear the stencil buffer
    glStencilMask(0xFF);

    // reset stencil test to always pass with reference value 0, clean state for next frame
    glStencilFunc(GL_ALWAYS, 0, 0xFF);

    // re-enable depth testing
    glEnable(GL_DEPTH_TEST);

    // Pass 3: draw everything else normally, no stencil

    // disable stencil testing entirely, the rest of the scene doesn't need it
    glDisable(GL_STENCIL_TEST);

    glUseProgram(normal_renderer.shader_program_gl_handle);
    set_camera_to_clip_uniform(*normal_renderer, camera_to_clip);
    set_world_to_camera_uniform(*normal_renderer, world_to_camera);

    // queue all other objects that don't need borders
    queue_render(*normal_renderer, some_other_renderable);
    queue_render(*normal_renderer, another_renderable);
    queue_render(*normal_renderer, yet_another_renderable);

    render(*normal_renderer);

    swap_buffers(window);
}
```
