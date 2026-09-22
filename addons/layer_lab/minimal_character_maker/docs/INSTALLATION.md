# Installation

For a standalone demo:

1. Extract the archive. It creates one `2D Minimal - Character Maker_Godot` folder instead of placing `addons/` directly beside the ZIP.
2. In Godot Project Manager, choose Import and select that folder's `project.godot`.
3. Wait for the initial import to finish, then press F6 or F5. The launcher opens the complete 1920x1080 character maker demo automatically.

For an existing project:

1. Open the extracted product folder and copy only its `addons/` directory into the root of your Godot 4.7.1 project.
2. Wait for the 901 PNG files to import. No EditorPlugin needs to be enabled.
3. Run `res://addons/layer_lab/minimal_character_maker/demo/main.tscn`, or drag `character/minimal_character.tscn` into your own scene.

Every platform that Godot 4.7.1 can export to is supported. There are no platform-specific native binaries, so no additional conditions apply. The PNG files in this package use straight alpha and can be used as they are.

When installing together with other products, merge the `addons/` directory found inside each product-named folder. Do not copy a packaged demo `project.godot` over an existing game project. This product does not use a shared core directory.
