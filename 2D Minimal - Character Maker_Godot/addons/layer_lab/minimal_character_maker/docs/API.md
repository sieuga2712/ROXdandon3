# LayerLabMinimalCharacter API

The global class `LayerLabMinimalCharacter extends Node2D` (`runtime/minimal_character.gd`) provides the public API of the Unity `PartsManager` with the same semantics.

## Part Types and Categories

- 18 PartsType values: `Eye`, `Hair`, `Helmet`, `Beard`, `Chest`, `Sword`, `Axe`, `Bow`, `Shield`, `Wand`, `Staff`, `Spear`, `Blunt`, `Crossbow`, `SubItem`, `Arrow`, `HelmetHair`, `Skin`
- 8 UI categories: `Hair`, `Eye`, `Beard`, `Skin`, `Helmet`, `Chest`, `HandRight` (Sword, Axe, Bow, Wand, Staff, Spear, Blunt, Crossbow), `HandLeft` (Shield, SubItem)
- 4 color targets: `Skin` (Body, Head), `Hair` (Hair, Hair_Helmet), `Eye` (Eye, not exposed in the UI), `Beard` (Beard)
- `Arrow` and `HelmetHair` are synchronized automatically and are not controlled directly. `Eye` and `Skin` cannot be unequipped or hidden.

## State

| Property | Description |
|---|---|
| `active_indices: Dictionary` | Current index per type. `-1` means not equipped |
| `visibility: Dictionary` | Visibility flag per type |
| `colors: Dictionary` | `Color` per color target |
| `configuration: Dictionary` (`@export_storage`) | Configuration for saved scenes. Applied in `_ready()` when not empty |
| `default_animation: StringName` (`@export`) | Starting animation when no configuration exists (default `Idle`) |
| `CONFIGURATION_VERSION = 1` | Configuration schema version. Higher versions are rejected |

## Static Functions

- `load_catalog() -> Dictionary`: Loads `character/catalog.json` (cached)
- `load_presets() -> Array`: Loads the 10 Unity presets from `character/presets.json` (`{"is_empty", "parts", "colors", "visibility"}`)

## Initialization and Queries

- `initialize()`: Reproduces the Unity `Init()` behavior: index 0, only the first subtype of each group visible, Arrow and HelmetHair hidden, white colors, and HelmetHair synchronized
- `get_all_parts_types() -> PackedStringArray`, `get_ui_categories() -> Dictionary`
- `get_display_name(type)`, `can_toggle(type)`, `can_change_color(type)`, `get_color_target(type)`
- `get_parts_count(type) -> int`: Number of sprites. `Skin` has no sprites and falls back to its thumbnail count (1)
- `get_active_index(type) -> int`, `is_parts_visible(type) -> bool`, `is_equipped(type) -> bool`
- `get_thumbnail_path(type, index) -> String`, `get_thumbnail(type, index) -> Texture2D`: Arrow thumbnails 10 through 14 are missing in the original asset as well and return an empty path or `null`

## Changing Parts

- `equip_parts(type, index)`: Clamps the index to 0 through count-1 and equips the part. Restores visibility if the part was hidden. HandRight weapons synchronize Arrow, `Hair` copies the same index to `HelmetHair`, and `Helmet` synchronizes HelmetHair
- `unequip_parts(type)`: Sets the index to -1 and hides the part for `can_toggle` types only. Bow and Crossbow synchronize Arrow, and Helmet synchronizes HelmetHair (unequipping `Hair` does not synchronize, matching Unity)
- `toggle_parts(type, is_visible)`: Keeps the index and switches the visibility
- `next_parts(type)` / `prev_parts(type)`: Cycles through the parts
- `set_color(target, color)` / `get_color(target)`: Applies independent RGB values to the target renderers' `self_modulate`; Skin therefore does not tint child Hair, Eye, or Beard sprites, while alpha remains controlled by the animations
- `randomize_all()`: Picks one type per right-hand and left-hand group, unequips Beard and Helmet with 50% probability, and randomizes the Skin, Hair, and Beard colors (saturation 0.4 to 1, value 0.5 to 1)
- `randomize_colors()`, `reset_all()` (re-emits every signal after initialization), `copy_from(other)`
- `apply_preset(item)` / `to_preset() -> Dictionary`
- `get_configuration() -> Dictionary` / `apply_configuration(config) -> bool`

## Animation

- `get_animation_names() -> PackedStringArray`: The 16 animations in Unity Animator state order
- `play_animation(name: StringName, speed := 1.0) -> bool`: Restores the setup pose, then plays the animation (equivalent to Unity Write Defaults)
- `stop_animation(reset_to_setup_pose := true)`, `reset_pose()`, `get_current_animation() -> String`, `has_animation(name)`, `get_animation_player() -> AnimationPlayer`
- `set_facing_left(facing_left)`: Flips the sign of the X scale

## Signals

| Signal | Arguments | Emitted |
|---|---|---|
| `parts_changed` | `(type_name: String, index: int)` | On equip, unequip (-1), and `reset_all` |
| `parts_visibility_changed` | `(type_name: String, is_visible: bool)` | On visibility changes, synchronization, and `reset_all` |
| `color_changed` | `(target: String, color: Color)` | On `set_color` and `reset_all` |
| `animation_event` | `(function_name: String, string_parameter: String)` | On the clip events `OnAttackHit` (Attack, 1.0 s) and `OnSkillHit` (Skill, 0.867 s) |
| `animation_changed` | `(animation_name: String)` | On `play_animation` |

## Sorting and Coordinates

- The Unity `sortingOrder` values 1 through 13 are preserved as cumulative `z_index` values under the parent. Use the root `z_index` to move the depth of the whole character.
- Positions are converted as `(x × 100, -y × 100)` px, rotation signs are inverted, and sprite origins are centered (only `Gravestone` uses BottomCenter, converted to `offset (0, -32.5)`).
