class_name Tower extends Node2D

signal tower_disabled
signal tower_destroyed

const light_shape_scene = preload("res://components/light_shape.tscn")

@export_group('Tower Properties')
@export_range(0, 100) var light_range : float
@export_range(0, 1500) var tower_range : int

@onready var tower_aim = $TowerAim
@onready var cooldown_timer = $CooldownTimer

var target : Object
var light_shape : LightShape

func _ready():
	var light_area = get_tree().get_first_node_in_group('light_area')
	light_shape = light_shape_scene.instantiate()
	light_area.add_child(light_shape)
