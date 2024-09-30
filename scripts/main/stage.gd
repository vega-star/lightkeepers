## Stage
# MAIN FUNCTION: Manages interactions with the tilemap, mouse movement/position.
# ADDITIONAL: Serves as the 2D position reference for all entites and containers of the stage
class_name Stage
extends Node2D

#region Variables
const CASHBACK_FACTOR : float = 0.65

@export_group('Node Connections')
@export var modulate_layer : CanvasModulate

@export_group('Stage Tools')
@export var check_coordinate : bool = false
@export var stage_songs : Array[String] = []

@onready var stage_manager : StageManager = $StageManager
@onready var turn_manager: TurnManager = $StageManager/TurnManager
@onready var stage_path : Path2D = $StagePath
@onready var GROUND_LAYER : TileMapLayer = $GroundLayer
@onready var OBJECT_LAYER : TileMapLayer = $ObjectLayer
@onready var INTERACTION_LAYER : TileMapLayer = $InteractionLayer
@onready var FOREGROUND_LAYER : TileMapLayer = $ForegroundLayer

const SELECTION_TILE : Vector2i = Vector2i(0,4)
const TILE : Dictionary = {
	'DEFAULT' = Vector2i(7,0),
	'BLOCKED' = Vector2i(0,3),
	'SELECT' = Vector2i(0,4),
	'TARGET' = Vector2i(2,3)
}

var selected_object : TileObject #? Selected object node storage
var object_dict : Dictionary #? Arranged by tile_position
var previous_selected_cell : Vector2i #? draw_width
var previous_queried_cell : Vector2i #? Used for input resetting
#endregion

#region Main functions
func _ready() -> void:
	if !modulate_layer.visible: modulate_layer.visible = true
	LoadManager._scene_is_stage = true
	AudioManager.play_music(stage_songs, 0, false, true)
	UI.start_stage()

func _process(_delta) -> void:
	if check_coordinate: #? Output tile coordinate on screen
		var current_mouse_pos = get_global_mouse_position()
		var tile_position = position_to_tile(current_mouse_pos)
		UI.HUD.debug_label.set_text(str(tile_position))

func _input(_event) -> void:
	if Input.is_action_just_pressed('click'): select_tile(position_to_tile(get_global_mouse_position()))
	if Input.is_action_just_pressed('alt'): deselect_tile()

func finish_stage() -> void:
	UI.end_stage()
#endregion

#region Tile management
## Converts a Vector2 coordinate into an accurate tile position
func position_to_tile(position_vector : Vector2) -> Vector2i: return GROUND_LAYER.local_to_map(position_vector)

func snap_to_tile(position_vector : Vector2) -> Vector2: return GROUND_LAYER.map_to_local(position_to_tile(position_vector))

## Query tile metadata
func query_tile(layer : TileMapLayer, tile_position : Vector2i, custom_data_layer_id : int = 0):
	var tile_data = layer.get_cell_tile_data(tile_position)
	if tile_data: return tile_data.get_custom_data_by_layer_id(custom_data_layer_id)
	else: return false

func select_tile(tile_position):
	if previous_selected_cell: deselect_tile()
	INTERACTION_LAYER.set_cell(tile_position, 0, SELECTION_TILE)
	var data
	var tile_data = GROUND_LAYER.get_cell_tile_data(tile_position)
	var object_data = OBJECT_LAYER.get_cell_tile_data(tile_position)
	if object_dict.has(tile_position): selected_object = object_dict[tile_position]['node']
	
	if is_instance_valid(selected_object):
		if selected_object is Tower: UI.HUD.tower_panel.load_tower(selected_object)
		selected_object.visible_range = true
	
	if tile_data: data = tile_data.get_custom_data_by_layer_id(0)
	UI.HUD.tile_description_label.set_text(str(data))
	previous_selected_cell = tile_position

func deselect_tile() -> void:
	INTERACTION_LAYER.erase_cell(previous_selected_cell)
	UI.HUD.object_description_label.set_text("")
	if is_instance_valid(selected_object): selected_object.visible_range = false
	selected_object = null

func query_tile_insertion(tile_position : Vector2i = Vector2i.ZERO) -> bool: #? Returns true if tile is valid
	if tile_position == Vector2i.ZERO: tile_position = position_to_tile(get_global_mouse_position())
	 
	INTERACTION_LAYER.set_cell(tile_position, 0, TILE.TARGET)
	if previous_queried_cell != tile_position: 
		INTERACTION_LAYER.erase_cell(previous_queried_cell)
		previous_queried_cell = tile_position
	
	var object_query = query_tile(OBJECT_LAYER, tile_position)
	var tile_query = query_tile(GROUND_LAYER, tile_position, 1)
	var foreground_query = query_tile(FOREGROUND_LAYER, tile_position)
	
	if (object_query is Dictionary): return false # Returns negatively if an object is already placed there
	elif (foreground_query is Dictionary): return false # Returns negatively if there's foreground tiles above it
	elif (tile_query is bool): # Ground can be detected everywhere but we need to know if it's placeable
		if (!tile_query): return false # Returns negatively if tile is not placeable
		else: return true # Returns positively
	else: return false # Returns negatively, for a placeable tile in ground layer wasn't found

func insert_tile_object(tile_object : TileObject) -> bool: #? Called from turret/object button when inserted into a tile
	var tile_position : Vector2i = position_to_tile(get_global_mouse_position())
	var tile_cost : int = tile_object.default_tower_cost
	var coordinates : Vector2 = GROUND_LAYER.map_to_local(tile_position)
	var query_result : bool = query_tile_insertion(tile_position)
	
	#! Returns true if object is successfully placed, and false if not.
	if (!query_result): return false # Recheck. Only returns negatively if invalidated in a series of checks
	if (tile_cost > stage_manager.coins): return false # Returns negatively turret is more expensive than current total coins
	
	## Clear
	INTERACTION_LAYER.erase_cell(previous_queried_cell)
	
	## Register
	tile_object.tile_position = tile_position
	object_dict[tile_position] = {
		'node': tile_object
	}
	
	## Insert
	OBJECT_LAYER.set_cell(tile_position, 0, TILE.DEFAULT)
	tile_object.global_position = coordinates
	tile_object.reparent($Containers/ObjectContainer)
	stage_manager.change_coins(tile_object.default_tower_cost)
	
	return true ## Return sucessfully

func request_removal(tile_position : Vector2i = Vector2i.MIN) -> bool:
	var object : Node
	if tile_position == Vector2i.MIN: tile_position = position_to_tile(get_global_mouse_position())
	if object_dict.has(tile_position): object = object_dict[tile_position]['node']
	if !object: return false
	
	var tower_value : int = roundi(object.tower_value * CASHBACK_FACTOR)
	var request : bool = await UI.EVENT.request_confirmation(
		'CONFIRM',
		'{0} {1} {2}'.format({0: TranslationServer.tr('DEMOLISH_REQUEST_TEXT'), 1: tower_value, 2: TranslationServer.tr('COINS').to_lower()}),
		'CONFIRM', 'CANCEL'
	)
	
	if request:
		remove_tile_object(tile_position, object)
		stage_manager.change_coins(tower_value, true)
		return true
	else: return false

func remove_tile_object(tile_position : Vector2i, object : TileObject) -> void:
	object.remove_object()
	OBJECT_LAYER.erase_cell(tile_position)
	object_dict.erase(tile_position)

#func insert_data(tile_position : Vector2i, key : String, value : Variant, layer : Layer = Layer.OBJECT_LAYER): ## TODO
	# var tile_data = tilemap.get_cell_tile_data(layer, tile_position)
	# tilemap.set_custom_data_layer_name(layer_index: int, layer_name: String)
#endregion
