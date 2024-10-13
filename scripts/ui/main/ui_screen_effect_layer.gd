extends CanvasLayer

const effects_dict : Dictionary = {
	'Tecnogarten' = {
		'palette' = preload('res://assets/shaders/palette/technogarten-1x.png'),
		'default_strength' = 0.5,
		'source' = 'https://lospec.com/palette-list/tag/technogarten'
	},
	'Quirky 11' = {
		'palette' = preload('res://assets/shaders/palette/technogarten-1x.png'),
		'default_strength' = 0.7,
		'source' = 'https://lospec.com/palette-list/quirky-11'
	}
}

@onready var effect_rect = $EffectRect

@export_category('Graphic Effects')

func _change_effect(effect_id : String, strength : float = 0):
	effect_rect.material.set_shader_parameter("Palette", effects_dict[effect_id]['palette'])
	if strength > 0: effect_rect.modulate = Color(1, 1, 1, strength)
	else: effect_rect.modulate = Color(1, 1, 1, effects_dict[effect_id]['default_strength'])
