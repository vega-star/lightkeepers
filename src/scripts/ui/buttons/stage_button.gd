class_name StageButton extends Button

@export var stage_selection : StageInfo

func _ready():
	assert(stage_selection.selected_stage_path)
	pressed.connect(_load_stage)

func _load_stage():
	LoadManager.load_scene(stage_selection.selected_stage_path)
