class_name StageInfo extends Resource

@export var selected_stage_path : String
@export var locked : bool = false

func _init() -> void:
	if OS.is_debug_build():
		locked = false
