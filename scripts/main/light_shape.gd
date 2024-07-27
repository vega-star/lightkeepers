class_name LightShape extends CollisionShape2D

@onready var shape_light = $ShapePointLight

@export var test_oscillation : bool = true

const MIN_SIZE : float = 0.9
const MAX_SIZE : float = 1.5

var time : float = 0
var frequency = 0.05
var amplitude = 1

var size : float = 1.0 : set = _size_change

func _ready():
	pass

func _size_change(new_size):
	# size = clampf(new_size, MIN_SIZE, MAX_SIZE)
	size = new_size
	shape.radius = 1 * size
	shape_light.texture_scale = 1 * size

func _physics_process(delta):
	time += delta
	if test_oscillation:
		var wave = abs(sin(2 * PI * frequency * time) * amplitude)
		size *= size + (1 * wave)
