# Troubleshooting

## The character is not visible

- Confirm that `initialize()` ran after the scene was added to the tree and that `catalog.json` exists under `addons/layer_lab/minimal_character_maker/character/`.
- If the Output panel shows `cannot read res://...catalog.json`, confirm that the whole directory was installed at the same path.

## A part index is not the expected value

- `equip_parts()` clamps the index to 0 through `get_parts_count()-1`. The index order follows the same case-insensitive file name sort as Unity.

## The bow or crossbow arrow is not visible

- Arrow and Bolt visibility is determined by both the Bow or Crossbow visibility and the animation alpha curves. Matching the original behavior, they appear only while Attack, Double Attack, Jump Attack, or Skill is playing.

## Part alpha remains after switching animations

- `play_animation()` restores the setup pose. If you called `AnimationPlayer.play()` directly, call `reset_pose()` first.

## Problems appear only in exported builds

- This product never reads the original import files, so export-specific problems are not expected. If you use a custom export filter, include the whole `addons/layer_lab/minimal_character_maker/` directory.

## Known Quirks of the Original Asset

- 10 of the 15 Arrow thumbnails are broken references in the original asset as well, so they are empty (not exposed in the UI).
- `Skin` has no sprites and only one thumbnail, so `get_parts_count("Skin")` returns 1.
- Matching Unity, unequipping `Hair` does not re-synchronize HelmetHair.
