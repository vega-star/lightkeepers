class_name DraggableObjectSprite extends Sprite2D

const DEFAULT_ORB_TEXTURE = preload("res://assets/sprites/misc/orb.png")

var element_sprite : Sprite2D
var element_orb : Sprite2D

func _ready() -> void:
	element_orb = Sprite2D.new()
	add_child(element_orb)
