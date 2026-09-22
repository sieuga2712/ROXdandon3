# Updating and Uninstalling

## Update

1. Check the current version in `VERSION` and `CHANGELOG.md`.
2. Overwrite `addons/layer_lab/minimal_character_maker/` with the directory from the new archive. `textures/`, `character/`, and `runtime/` are generated files, so do not edit them directly.
3. Saved scenes (`configuration`) keep working as long as the schema version stays at 1. `apply_configuration()` rejects higher versions.
4. After updating, run the example scene once to check the parts and animations.

## Uninstall

Delete the `addons/layer_lab/minimal_character_maker/` directory. Game scenes that instantiate this product's scene and the saved scenes under `res://layer_lab_generated/minimal_character_maker/` will no longer open, so clean them up first.
