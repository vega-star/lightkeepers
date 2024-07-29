class_name LightShape extends CollisionShape2D

@export var default_color : Color = Color.WHITE
@export var test_oscillation : bool = true

const BASE_RADIUS : float = 128
const MIN_SIZE : float = 0.9
const MAX_SIZE : float = 1.5

var time : float = 0
var frequency = 0.05
var amplitude = 1

var light_color : Color:
	set(new_color):
		assert(new_color is Color)
		light_color = new_color
		$ShapePointLight.color = new_color
var size : float = 1.0 : set = _size_change

func _ready():
	light_color = default_color
	shape = CircleShape2D.new()
	shape.radius = BASE_RADIUS * size

func _size_change(new_size):
	size = new_size
	shape.radius = BASE_RADIUS * size
	$ShapePointLight.texture_scale = 1 * size

func _physics_process(delta):
	time += delta
	if test_oscillation:
		var wave = abs(sin(2 * PI * frequency * time) * amplitude)
		size *= size + (1 * wave)
