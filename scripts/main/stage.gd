class_name Stage
extends Node2D

@export_group('Node Connections')
@export var tilemap : TileMap
@export var modulate_layer : CanvasModulate # 
@export var light_container : Node2D # Stores a lot of PointLight2D nodes
@export var light_area_container : Area2D # Detects enemies inside light

@export_group('Stage Tools')
@export var check_coordinate : bool = false

@onready var parallax_background = $ParallaxBackground

func _ready():
	if !modulate_layer.visible: modulate_layer.visible = true
	# tilemap.set_layer_modulate(3, Color.WHITE) # Makes foreground opacity full
