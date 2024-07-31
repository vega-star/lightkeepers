extends CanvasLayer

const effects_dict : Dictionary = {
	'Tecnogarten' = {
		'palette' = preload('res://assets/shaders/palette/technogarten-1x.png'),
		'default_strength' = 0.6
	}
}

@onready var effect_rect = $EffectRect

@export_category('Graphic Effects')

@export_category('Layer Properties')
@export var volatile : bool = false ## Autodestructs when loaded. Useful to test the graphic effects while building new scenes

func _ready():
	if volatile: queue_free()
