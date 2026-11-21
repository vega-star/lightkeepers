class_name LightShape extends CollisionShape2D

@export var base_energy : float = 0.5
@export var noise : NoiseTexture2D
@export var default_color : Color = Color.WHITE
@export var oscillation : bool = false

@onready var shape_point_light : PointLight2D = $ShapePointLight

const BASE_RADIUS : float = 128
const MIN_SIZE : float = 0.9
const MAX_SIZE : float = 1.5

var time : float = 0
var frequency = 0.05
var amplitude = 1
var size : float = 1.0 : set = _size_change
var light_color : Color:
	set(new_color):
		assert(new_color is Color)
		light_color = new_color
		shape_point_light.color = new_color

func _ready():
	light_color = default_color
	shape = CircleShape2D.new()
	shape.radius = BASE_RADIUS * size

func _size_change(new_size):
	if !is_node_ready(): await ready
	size = new_size
	shape.radius = BASE_RADIUS * size
	shape_point_light.texture_scale = 1 * size

func _physics_process(delta):
	if oscillation:
		time += delta
		var sampled_noise = abs(noise.noise.get_noise_1d(time))
		shape_point_light.energy = base_energy * sampled_noise
