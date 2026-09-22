# Quick Start

To explore every creator control first, run `res://addons/layer_lab/minimal_character_maker/demo/main.tscn`. The packaged standalone project opens this scene automatically when it is the only installed Character Maker product.

Opening this scene in the Godot editor shows the complete serialized map, character instance, panels, part thumbnails, color picker, and animation controls. Running it binds the interactions and refreshes catalog-dependent list entries.

Every active demo button has centered hover, press, and release feedback. `Save Character` is available in editor builds and saves the current character as a reusable `.tscn` together with a 512x512 transparent PNG preview; it does not save the complete demo scene.

```gdscript
var character := preload("res://addons/layer_lab/minimal_character_maker/character/minimal_character.tscn").instantiate() as LayerLabMinimalCharacter
add_child(character)
character.scale = Vector2.ONE * 2.254  # Unity demo: instance scale 2.0872 × 108 px/unit ÷ 100 px/unit

character.equip_parts("Helmet", 3)          # Fourth helmet
character.unequip_parts("Beard")            # Remove the beard
character.toggle_parts("Sword", false)      # Hide the sword
character.toggle_parts("Bow", true)         # Show the bow (arrow and bowstring synchronize automatically)
character.set_color("Hair", Color("7DE8A7"))
character.randomize_all()                   # Randomize parts and colors
character.apply_preset(LayerLabMinimalCharacter.load_presets()[0])
character.play_animation(&"Attack")
character.animation_event.connect(func(name: String, _parameter: String) -> void: print(name))  # OnAttackHit / OnSkillHit
```

- Adding the scene to the tree runs `initialize()` automatically, which produces the Unity `PartsManager.Init()` default state (sword, shield, helmet, and beard equipped, other weapons hidden).
- If you call `initialize()` and configure parts before adding the scene to the tree, `_ready()` does not revert them.
- Use `get_configuration()` / `apply_configuration()` or the exported `configuration` property to handle saved configurations.
