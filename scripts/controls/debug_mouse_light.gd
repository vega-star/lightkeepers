extends PointLight2D

@export var reference_object : Node2D
@export var max_intensity : float = 2.5
@export var min_intensity : float = 0

const base_intensity : float = 1500
var intensity : float = 1
var change_intensity : bool = false

func _ready():
	assert(reference_object)

func _process(delta):
	global_position = get_global_mouse_position()

func _physics_process(delta):
	if change_intensity: update_intensity()

func update_intensity():
	var distance = global_position.distance_to(reference_object.global_position)
	var dampening = distance
	
	intensity = 10 / (base_intensity - (base_intensity - distance))
	intensity = clamp(intensity, min_intensity, max_intensity)
	print(1 * intensity)
	energy = 1 * intensity
