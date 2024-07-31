class_name StageButton extends TextureButton

@export var stage_path : String

func _ready():
	assert(stage_path)
	pressed.connect(_load_stage)

func _load_stage():
	LoadManager.load_scene(stage_path)
