extends CanvasLayer

@export var set_invisible : bool = true

func _ready() -> void:
	set_visible(!set_invisible)
	match ProjectSettings.get_setting_with_override("rendering/renderer/rendering_method"):
		"forward_plus": #? Not needed. Will use compositor
			pass # queue_free()
		"mobile", "gl_compatibility", _: #? Using a shader as replacement until compositors are compatible with GL/Mobile
			set_visible(true)
