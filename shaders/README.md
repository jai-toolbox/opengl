# OpenGL shaders

These shaders belong to the `tbx/opengl` backend and are kept beside the code
that owns their OpenGL programs.

## Directory layout

- `src/` contains the hand-written legacy GLSL and its local `#include` files.
- `out/` contains the preprocessed legacy GLSL consumed by OpenGL renderers.
- `generated/` contains GLSL translated from the backend-neutral GPU-style Jai
  sources in `tbx/software_rasterizer/gpu_style_shaders`.
- `programs/` describes the vertex/fragment pair and renderer options for each
  generated OpenGL renderer.

The generated renderer files embed their GLSL at Jai compile time using paths
relative to `tbx/opengl`. Applications therefore do not need to copy an
additional `data/shaders` tree beside their executable.

## Regeneration

From a project root containing `src/tbx`, run:

```sh
/path/to/jai/bin/jai-linux src/tbx/opengl/regenerate_shaders.jai
```

That command performs the complete sequence:

1. Preprocess `shaders/src` into `shaders/out`.
2. Translate the shared GPU-style Jai shaders into `shaders/generated`.
3. Regenerate the typed OpenGL renderer files in `renderers/`.

OpenGL still compiles and links the embedded GLSL into driver-specific programs
when each renderer is initialized.
