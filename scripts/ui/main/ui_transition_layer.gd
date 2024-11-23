extends CanvasLayer

const bg_forward_color : Color = Color(0.047, 0.035, 0.059)
const bg_compatibility_color : Color = Color(0.243, 0.208, 0.275)

@onready var shader : MeshInstance2D = $ScreenTransition/Shader
@onready var animation_node : AnimationPlayer = $ScreenTransition/FadeAnimation
@onready var fade_time : float = 1.2

signal fade_output(mode)

var speed_scale : float: set = _set_speed_scale

func _ready():
	var bg_color : Color = ProjectSettings.get_setting("application/boot_splash/bg_color")
	shader.material.set_shader_parameter("color", bg_color)
	
	## Renderer check
	# var renderer = ProjectSettings.get_setting("rendering/renderer/rendering_method")
	# match renderer:
	#	"forward_plus": shader.material.set_shader_parameter("color", bg_forward_color)
	#	"gl_compatibility": shader.material.set_shader_parameter("color", bg_compatibility_color)
	#	_: printerr('RENDERER INVALID | Current renderer: {0}'.format({0:renderer}))
	pass

func _set_speed_scale(new_speed : float):
	speed_scale = new_speed
	animation_node.speed_scale = new_speed

func fade(mode):
	shader.scale = get_viewport().size
	shader.position = get_viewport().size / 2
	match mode:
		0, 'IN':
			animation_node.play('FADE')
			AudioManager.set_pause(false)
			fade_output.emit(mode)
		1, 'OUT':
			animation_node.play_backwards('FADE')
			AudioManager.set_pause(true)
			fade_output.emit(mode)
