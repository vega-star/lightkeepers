class_name LightArea
extends Area2D

@export var verbose_detection : bool = false

var light_shapes : Array[CollisionShape2D]

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	# merge_shapes()

func merge_shapes():
	for s in get_children():
		light_shapes.append(s)
	print(light_shapes)

func toggle_enemy_visibility(enemy, toggle : bool):
	pass

func _on_area_entered(area):
	if verbose_detection: print('%s is an area and entered light area' % area.name)

func _on_area_exited(area):
	if verbose_detection: print('%s is an area and exited light area' % area.name)

func _on_body_entered(body):
	if body is Enemy: body.on_sight = true
	if verbose_detection: print('%s is an body and entered light area' % body.name)

func _on_body_exited(body):
	if body is Enemy: body.on_sight = false
	if verbose_detection: print('%s is an body and exited light area' % body.name)
