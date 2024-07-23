extends PointLight2D

func _ready():
	pass # Replace with function body.

func _process(delta):
	global_position = get_global_mouse_position()
