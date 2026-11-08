# OpenGL shaders

These shaders belong to the `tbx/opengl` backend and are kept beside the code
that owns their OpenGL programs.

## Directory layout

- `src/` contains the hand-written legacy GLSL and its local `#include` files.
- `out/` contains the preprocessed legacy GLSL consumed by OpenGL renderers.
- `generated/` contains GLSL translated from the backend-neutral virtual GPU Jai
  sources in `tbx/virtual_gpu_rendering/shaders`.
- `programs/` describes the vertex/fragment pair and renderer options for each
  generated OpenGL renderer.

The generated renderer files embed their GLSL at Jai compile time using paths
relative to `tbx/opengl`. Applications therefore do not need to copy an
additional `data/shaders` tree beside their executable.

## Regeneration

From a project root containing `modules/tbx`, run:

```sh
/path/to/jai/bin/jai-linux modules/tbx/opengl/generation/regenerate_shaders.jai
```

That command performs the complete sequence:

1. Preprocess `shaders/src` into `shaders/out`.
2. Run `virtual_gpu_rendering/tools/generate_shaders.jai` to translate
   the shared Jai shaders into `shaders/generated` and write their `.program`
   descriptors into `shaders/programs`.
3. Read those descriptors and regenerate the OpenGL renderer files in `renderers/`.

The shared module owns shader selection, Jai-to-GLSL compilation and descriptor
generation. OpenGL owns descriptor reading and renderer generation. The shared
tool accepts output directories from its caller and imports no graphics backend.

OpenGL still compiles and links the embedded GLSL into driver-specific programs
when each renderer is initialized.

Application-specific Jai pipelines write their own GLSL and `.program`
descriptor together in the requested output directory. The same descriptor
processor generates their OpenGL renderers. Optional `jai_bindings` preserve
native vertex and uniform types for the generated upload helpers.
