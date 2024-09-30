class_name KeybindButton extends Button

@export var sound_when_pressed : String = "clicky button 4"
@export var sound_when_focus : String = "sci fi click 3"
@export var sound_when_hovered : String = ""
@export var sound_when_key_registered : String = ""
@export var keybind : String = ""

var do_set = false

# Foundation learned from a tutorial from Rungeon, most parts had to be rewritten due to changes in Godot 4.2 and new functions were added
# Source: https://www.youtube.com/watch?v=WHGHevwhXCQ
# Github: https://github.com/trolog/godotKeybindingTutorial

func _pressed():
	text = ""
	Options.settings_changed = true
	do_set = true

func _input(event):
	if(do_set):
		if(event is InputEventKey):
			self.focus_mode = Control.FOCUS_NONE #? Prevents some control issues
			var key = InputEventKey.new()
			key.keycode = int(Options.key_dict[keybind])
			InputMap.action_erase_event(keybind, key) ; print('Deleting {0} from {1}'.format({0: keybind, 1:key})) #? Delete the old input
			InputMap.action_add_event(keybind, event) #? Add the new key for this action
			text = OS.get_keycode_string(event.keycode).to_upper() #? Return to the UI
			Options.key_dict[keybind] = int(event.keycode) #? Update the key_dict with the keycode function. Needs to be string, as dicts don't store value types
			do_set = false #? Stop keybind process
			self.focus_mode = Control.FOCUS_ALL
			_emit_sound(sound_when_key_registered)

func _emit_sound(sound_id : String): AudioManager.emit_sound_effect(Vector2.ZERO, sound_id)
func _on_pressed(): _emit_sound(sound_when_pressed)
func _on_focus_entered(): _emit_sound(sound_when_focus)
func _on_mouse_entered(): _emit_sound(sound_when_hovered)
