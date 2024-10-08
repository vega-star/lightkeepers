class_name MouseLight
extends PointLight2D

@export var max_intensity : float = 2.5
@export var min_intensity : float = 0
@export var change_intensity : bool = false

const BASE_INTENSITY : float = 1500
const LIGHT_SHAPE_SCENE = preload("res://components/systems/light_shape.tscn")

var nexus
var light_shape : LightShape
var intensity : float = 1

func _ready(): 
	nexus = get_tree().get_first_node_in_group('nexus')
	var light_area = get_tree().get_first_node_in_group('light_area')
	light_shape = LIGHT_SHAPE_SCENE.instantiate()
	light_area.add_child.call_deferred(light_shape)

func _process(_delta):
	global_position = get_global_mouse_position()
	light_shape.global_position = get_global_mouse_position()

func _physics_process(_delta):
	if change_intensity: update_intensity()

func update_intensity():
	var distance = global_position.distance_to(nexus.global_position)
	# var dampening = distance
	
	intensity = 10 / (BASE_INTENSITY - (BASE_INTENSITY - distance))
	intensity = clamp(intensity, min_intensity, max_intensity)
	print(1 * intensity)
	energy = 1 * intensity
