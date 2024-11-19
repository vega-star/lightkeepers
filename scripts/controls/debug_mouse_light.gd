## Mouse light
## Makes your long-range turrets see enemies far away without the need of a lamp
class_name MouseLight
extends Node2D

@export var max_intensity : float = 2.5
@export var min_intensity : float = 0
@export var change_intensity : bool = false

const BASE_INTENSITY : float = 1500
const LIGHT_SHAPE_SCENE = preload("res://components/systems/light_shape.tscn")

var light_shape : LightShape
var intensity : float = 1

func _ready():
	var light_area : LightArea = get_tree().get_first_node_in_group("light_area")
	light_shape = LIGHT_SHAPE_SCENE.instantiate()
	light_area.add_child.call_deferred(light_shape)

func _process(_delta):
	global_position = get_global_mouse_position()
	light_shape.global_position = global_position
