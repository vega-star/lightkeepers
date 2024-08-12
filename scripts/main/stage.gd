## Stage
# MAIN FUNCTION: Manages interactions with the tilemap, mouse movement/position.
# ADDITIONAL: Serves as the 2D position reference for all entites and containers of the stage
class_name Stage
extends Node2D

@export_group('Node Connections')
@export var modulate_layer : CanvasModulate

@export_group('Stage Tools')
@export_range(0, 1.0) var cashback_factor : float = 0.4
@export var check_coordinate : bool = false

@onready var tilemap = $TileMap
@onready var stage_manager = $StageManager
@onready var stage_path = $StagePath

@export var stage_songs : Array[String] = []

const SELECTION_TILE : Vector2i = Vector2i(0,4)
const TILE : Dictionary = {
	'DEFAULT' = Vector2i(7,0),
	'BLOCKED' = Vector2i(0,3),
	'SELECT' = Vector2i(0,4),
	'TARGET' = Vector2i(2,3)
}

enum Layer {
	GROUND_LAYER = 0,
	OBJECT_LAYER = 1,
	INTERACT_LAYER = 2,
	FOREGROUND_LAYER = 3
}

var object_dict : Dictionary
var previous_selected_cell : Vector2i
var previous_queried_cell : Vector2i

func _ready():
	if !modulate_layer.visible: modulate_layer.visible = true
	AudioManager.play_music(stage_songs, 0, false, true)
	UI.start_stage()

func _process(delta):
	if check_coordinate:
		var current_mouse_pos = get_global_mouse_position()
		var tile_position = position_to_tile(current_mouse_pos)
		UI.HUD.debug_label.set_text(str(tile_position))

func _input(event):
	if Input.is_action_just_pressed('click'): select_tile(position_to_tile(get_global_mouse_position()))
	if Input.is_action_just_pressed('alt'): deselect_tile()

#? Converts a Vector2 coordinate into an accurate tile position
func position_to_tile(position_vector : Vector2) -> Vector2i: return tilemap.local_to_map(position_vector)

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
	# var object = object_dict[tile_position]['node']
	if tile_data: data = tile_data.get_custom_data_by_layer_id(0)
	UI.HUD.tile_description_label.set_text(str(data))
	previous_selected_cell = tile_position

func deselect_tile(): tilemap.erase_cell(Layer.INTERACT_LAYER, previous_selected_cell)

func query_tile_insertion(tile_position : Vector2i = Vector2i.ZERO) -> bool:
	if tile_position == Vector2i.ZERO: tile_position = position_to_tile(get_global_mouse_position())
	 
	tilemap.set_cell(Layer.INTERACT_LAYER, tile_position, 0, TILE.TARGET)
	if previous_queried_cell != tile_position: 
		tilemap.erase_cell(Layer.INTERACT_LAYER, previous_queried_cell)
		previous_queried_cell = tile_position
	
	var object_query = query_tile(Layer.OBJECT_LAYER, tile_position)
	var tile_query = query_tile(Layer.GROUND_LAYER, tile_position, 1)
	var foreground_query = query_tile(Layer.FOREGROUND_LAYER, tile_position)
	
	if (object_query is Dictionary): return false # Returns negatively if an object is already placed there
	elif (foreground_query is Dictionary): return false # Returns negatively if there's foreground tiles above it
	elif (tile_query is bool): # Ground can be detected everywhere but we need to know if it's placeable
		if (!tile_query): return false # Returns negatively if tile is not placeable
		else: return true # Returns positively
	else: return false # Returns negatively, for a placeable tile in ground layer wasn't found

func insert_tile_object(tile_object : Object) -> bool: # Returns true if object is successfully placed, and false if not
	var tile_position : Vector2i = position_to_tile(get_global_mouse_position())
	var tile_cost : int = tile_object.tower_cost
	var coordinates : Vector2 = tilemap.map_to_local(tile_position)
	var query_result : bool = query_tile_insertion(tile_position)
	
	if (!query_result): return false # Recheck. Only returns negatively if invalidated in a series of checks
	if (tile_cost > stage_manager.coins): return false # Returns negatively turret is more expensive than current total coins
	
	## Clear
	tilemap.erase_cell(Layer.INTERACT_LAYER, previous_queried_cell)
	
	## Register
	object_dict[tile_position] = {'node': tile_object}
	
	## Insert
	tilemap.set_cell(Layer.OBJECT_LAYER, tile_position, 0, TILE.DEFAULT)
	tile_object.global_position = coordinates
	tile_object.reparent($Containers/ObjectContainer)
	stage_manager.change_coins(tile_object.tower_cost)
	
	return true ## Return sucessfully

func request_removal() -> bool:
	var object : Node
	var tile_position : Vector2i = position_to_tile(get_global_mouse_position())
	if object_dict.has(tile_position): object = object_dict[tile_position]['node']
	if !object: return false
	
	var tower_value : int = roundi(object.tower_cost * cashback_factor)
	var request : bool = await UI.EVENT.request_confirmation('Confirm Demolish', 'Demolishing this turret will grant you back {0} coins'.format({0: tower_value}), 'CONFIRM', 'CANCEL')
	# await UI.EVENT.confirmation
	
	if request: 
		remove_tile_object(tile_position, object)
		stage_manager.change_coins(tower_value, true)
		return true
	else: return false

func remove_tile_object(tile_position : Vector2i, object : Node):
	object.queue_free()
	tilemap.erase_cell(Layer.OBJECT_LAYER, tile_position)
	object_dict.erase(tile_position)

#func insert_data(tile_position : Vector2i, key : String, value : Variant, layer : Layer = Layer.OBJECT_LAYER): ## TODO
	# var tile_data = tilemap.get_cell_tile_data(layer, tile_position)
	# tilemap.set_custom_data_layer_name(layer_index: int, layer_name: String)
