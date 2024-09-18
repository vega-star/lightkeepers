class_name LightArea
extends Area2D

@export var verbose_detection : bool = false

func _on_area_entered(area) -> void:
	if verbose_detection: print('%s is an area and entered light area' % area.name)

func _on_area_exited(area) -> void:
	if verbose_detection: print('%s is an area and exited light area' % area.name)

func _on_body_entered(body) -> void:
	if body is Enemy: body.on_sight = true
	if verbose_detection: print('%s is an body and entered light area' % body.name)

func _on_body_exited(body) -> void:
	if body is Enemy: body.on_sight = false
	if verbose_detection: print('%s is an body and exited light area' % body.name)
