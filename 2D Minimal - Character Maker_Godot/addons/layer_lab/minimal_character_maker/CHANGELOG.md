# Changelog

## 1.0.0-rc.5 — 2026-09-08

- Added the Art Maker button response to every active demo button: 1.025x hover scale, 0.94x pressed scale with a blue tint, and a 0.14-second release transition.
- Registered runtime-generated part-list buttons as well as serialized controls while preserving each button's original scale, modulation, click area, and selected state.
- Renamed `Save Scene` to `Save Character` because the action saves the configured character scene and its 512x512 preview rather than the complete demo scene.

## 1.0.0-rc.4 — 2026-09-08

- Isolated Skin, Hair, Eye, and Beard RGB with `self_modulate` so changing the skin color no longer tints child sprites in the character hierarchy.
- Preserved the existing `modulate:a` animation tracks so Unity SpriteRenderer alpha animation remains independent from creator color channels.
- Added runtime and full-demo regressions for changing Skin while keeping Hair, Eye, and Beard colors unchanged.

## 1.0.0-rc.3 — 2026-09-08

- Serialized the complete map, character instance, creator panels, color picker, part thumbnails, and animation controls into `demo/main.tscn` so the demo is visible and editable before running it in the Godot editor.
- Kept catalog-dependent list rebuilding and all creator interactions in the runtime script while binding them to the serialized nodes.
- Added source and distribution checks that reject a one-node runtime-only demo shell.

## 1.0.0-rc.2 — 2026-09-04

- Added the complete 1920x1080 character maker demo, including its UI, sample map, and bitmap-only fonts, inside the standalone product directory.
- Packaged the archive inside one product-named folder with `project.godot` and a shared launcher so the extracted folder can be imported and run directly in Godot.
- Kept existing-project installation available by copying only the nested `addons/` directory.

## 1.0.0-rc.1 — 2026-09-02

- First release candidate that converts the Unity `2D Minimal-CharacterMaker` asset into native 2D resources for Godot 4.7.1.
- Converted the `Character.prefab` rig with 43 nodes and 36 Sprite2D nodes, 16 AnimationClips (60 fps, 370 tracks), and the `OnAttackHit` and `OnSkillHit` events.
- Added the `LayerLabMinimalCharacter` runtime, which reproduces the `PartsManager` behavior: equip, unequip, and hide for 18 part types, exclusive display within groups, automatic HelmetHair and Arrow synchronization, 4 color targets, randomization, 10 Unity presets, and saved configurations.
- Copied 849 part PNG files byte-identically (snake_case) together with the catalog and preset JSON files.
- Verified macOS and Windows exports at runtime (no GDExtension required).
- Standardized all buyer-facing documentation and runtime comments in English.
- External sale remains on hold until the original artwork rights have been verified.
