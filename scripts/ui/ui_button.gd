class_name UIButton extends Button

@export var sound_when_pressed : String = ""
@export var sound_when_focus : String = ""
@export var sound_when_hovered : String = ""

func _emit_sound(sound_id : String): AudioManager.emit_sound_effect(self.global_position, sound_id, "Master")

func _on_pressed(): _emit_sound(sound_when_pressed)
func _on_focus_entered(): _emit_sound(sound_when_focus)
func _on_mouse_entered(): _emit_sound(sound_when_hovered)
