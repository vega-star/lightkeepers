class_name Stage
extends Node2D

@export_group('Node Connections')
@export var tilemap : TileMap
@export var modulate_layer : CanvasModulate # 
@export var light_container : Node2D # Stores a lot of PointLight2D nodes

@export_group('Stage Tools')
@export var check_coordinate : bool = false

@onready var parallax_background = $ParallaxBackground

func _ready():
	if !modulate_layer.visible: modulate_layer.visible = true

func _position_to_tile(position_vector : Vector2) -> Vector2i: return tilemap.local_to_map(position_vector)

func _process(delta):
	if check_coordinate:
		var current_mouse_pos = get_global_mouse_position()
		UI.hud.debug_label.set_text(str(_position_to_tile(current_mouse_pos)))

func _input(event):
	if Input.is_action_just_pressed('click'):
		pass
