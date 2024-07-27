## Enemy prototype
# Intended to follow a Line2D only and not have a Navigation2D guiding it. Performs better because of it, but it is quite uninteresting to look at and fight.
class_name SimpleEnemy
extends Node2D

@export_group('Enemy Properties')
@export_enum('creep') var enemy_class = 'creep'
@export var base_health : int = 10
@export var base_speed : int = 50

@export_group('Node Connections')
@export var navigation_agent : NavigationAgent2D
@export var enemy_sprite : Sprite2D
@export var enemy_area : Area2D
@export var enemy_path : Path2D

var target : Node2D : set = _set_target
var target_position : Vector2

func _set_enemy_properties():
	pass

func _ready():
	await _set_enemy_properties()
	
	enemy_area.area_entered.connect(light_entered)
	enemy_area.area_exited.connect(light_exited)

func _physics_process(delta):
	if enemy_path: enemy_path.set_progress(enemy_path.get_progress() + base_speed * delta)

func _set_target(node : Node2D): 
	target = node
	target_position = node.global_position

func light_entered(area):
	if area is LightArea: print('%s entered light' % self.name)

func light_exited(area):
	if area is LightArea: print('%s exited light' % self.name)
