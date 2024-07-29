class_name Stage
extends Node2D

@export_group('Stage Properties')
@export var default_initial_coins : int = 100

@export_group('Node Connections')
@export var tilemap : TileMap
@export var modulate_layer : CanvasModulate

@export_group('Stage Tools')
@export var check_coordinate : bool = false

const SELECTION_TILE : Vector2i = Vector2i(0,4)

enum Layer {
	GROUND_LAYER = 0,
	OBJECT_LAYER = 1,
	INTERACT_LAYER = 2,
	FOREGROUND_LAYER = 3
}

# var objects : Array[Object]
var previous_selected_cell : Vector2i

func _ready():
	# for o in $Containers/ObjectContainer.get_children(): objects.append(o)
	if !modulate_layer.visible: modulate_layer.visible = true
	# tilemap.set_layer_modulate(3, Color.WHITE) # Makes foreground opacity full

func _process(delta):
	if check_coordinate:
		var current_mouse_pos = get_global_mouse_position()
		var tile_position = position_to_tile(current_mouse_pos)
		UI.hud.debug_label.set_text(str(tile_position))

func _input(event):
	if Input.is_action_just_pressed('click'): select_tile(position_to_tile(get_global_mouse_position()))

func position_to_tile(position_vector : Vector2) -> Vector2i: ## Converts a Vector2 coordinate into an accurate tile position
	return tilemap.local_to_map(position_vector)

func query_tile(layer : Layer, tile_position : Vector2i, custom_data_layer_id : int = 0):
	var tile_data = tilemap.get_cell_tile_data(layer, tile_position)
	if tile_data: return tile_data.get_custom_data_by_layer_id(custom_data_layer_id)
	else: return false

func select_tile(tile_position):
	if previous_selected_cell: tilemap.erase_cell(Layer.INTERACT_LAYER, previous_selected_cell)
	tilemap.set_cell(Layer.INTERACT_LAYER, tile_position, 0, SELECTION_TILE)
	
	var data
	var tile_data = tilemap.get_cell_tile_data(Layer.GROUND_LAYER, tile_position)
	var object_data = tilemap.get_cell_tile_data(Layer.OBJECT_LAYER, tile_position)
	if tile_data: data = tile_data.get_custom_data_by_layer_id(0)
	UI.hud.tile_description_label.set_text(str(data))
	
	previous_selected_cell = tile_position

func insert_tile_object(tile_object : Object) -> bool: # Returns true if object is successfully placed, and false if not
	var tile_position = position_to_tile(get_global_mouse_position())
	var coordinates : Vector2 = tilemap.map_to_local(tile_position)
	var query = query_tile(Layer.OBJECT_LAYER, tile_position)
	if !query is bool: return false
	
	tilemap.set_cell(Layer.OBJECT_LAYER, tile_position, 0, Vector2i(8,0))
	tile_object.global_position = coordinates
	tile_object.reparent($Containers/ObjectContainer)
	# objects.append(tile_object)
	return true
