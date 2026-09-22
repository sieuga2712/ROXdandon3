# Exporting a Game

1. Install the official export templates for Godot 4.7.1.
2. Create a preset for the target platform and run a debug export first.
3. This product has no GDExtension or external binaries, so the platform preset needs no additional settings.
4. `catalog.json` and `presets.json` are packed into the PCK as Godot JSON resources and read with `load()` at runtime. The runtime does not depend on the original import files, so characters do not disappear in exported builds (verified on macOS universal and Windows x86_64).
5. macOS universal exports (including arm64) require the project setting `rendering/textures/vram_compression/import_etc2_astc=true`.
6. If generated scenes are loaded only through string paths in code, include that directory in the export filter.

Keeping lossless import settings for the thumbnail and part PNG files is recommended.
