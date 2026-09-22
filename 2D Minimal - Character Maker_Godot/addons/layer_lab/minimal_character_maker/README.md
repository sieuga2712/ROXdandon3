# Layer Lab Minimal Character Maker for Godot

Layer Lab Minimal Character Maker is a standalone product that converts the Unity `2D Minimal-CharacterMaker` asset into native 2D resources for Godot 4.7.1. It uses only `Node2D`, `Sprite2D`, and `AnimationPlayer`, with no Spine runtime or GDExtension.

1. Extract the archive. It creates one `2D Minimal - Character Maker_Godot` folder.
2. Import that folder's `project.godot` in Godot Project Manager and press F6 or F5 to run the complete demo.
3. To add the asset to an existing project, copy only the extracted folder's `addons/` directory into your project root.
4. Instantiate `character/minimal_character.tscn` in your game scene and use the `LayerLabMinimalCharacter` API.

The demo gives every active button the same responsive hover, press, and release motion used by the Art Maker demos. In an editor build, `Save Character` writes only the configured character scene and its 512x512 preview to `res://layer_lab_generated/minimal_character_maker/`.

## Contents

| Item | Count |
|---|---:|
| Part types (PartsType) | 18 (8 UI categories) |
| Part, character, and thumbnail PNG files | 849 |
| Animations | 16 (Idle, Walk, Attack, Skill, Run, Roll, Jump, Jump Attack, Dance, Victory, Defeat, Stun, Dead1, Dead2, Dead3, Double Attack) |
| Unity presets | 10 |
| Rig nodes / Sprite2D nodes | 43 / 36 |

## Directories

- `runtime/minimal_character.gd`: The `LayerLabMinimalCharacter` runtime
- `character/`: Rig scene, `AnimationLibrary`, `catalog.json`, and `presets.json`
- `textures/`: Byte-identical copies of the original PNG files (lowercase snake_case paths)
- `demo/`: Complete editor-visible 1920x1080 character maker scene, sample map, UI, and bitmap-only fonts
- `examples/`: Minimal integration example
- `docs/`: Installation, quick start, API, export, update, troubleshooting, and compatibility guides

This product can be installed in the same project as the Casual and Fantasy Character Maker products and the Enemy Monster products. Its only global class is `LayerLabMinimalCharacter`, which does not conflict with the other products.

Review `DISTRIBUTION_BLOCKED.md` before selling or distributing this package.
