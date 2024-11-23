## StageAgent
# MAIN FUNCTION: Manages interactions with the tilemap, mouse movement/position.
# ADDITIONAL: Serves as the 2D position reference for all entites and containers of the stage
class_name Stage
extends Node2D

#region Variables
const SELECTOR_INVALID_COLOR : Color = Color(3.5,2,2)
const CASHBACK_FACTOR : float = 0.65
const MOVEMENT_COST_FACTOR : float = 0.20

## Stage configuration
@export var stage_info : StageInfo

@export_group('Node Connections')
@export var modulate_layer : CanvasModulate

@export_group('Stage Tools')
@export var check_coordinate : bool = false
@export var stage_songs : Array[String] = []

## Main node references
@onready var nexus : Nexus = $Nexus
@onready var stage_agent : StageAgent = $StageAgent
@onready var stage_camera : StageCamera = $StageCamera
@onready var turn_manager: TurnManager = $StageAgent/TurnManager
@onready var stage_path : Path2D = $StagePath
@onready var background_parallax : ParallaxBackground = $StageEffects/BackgroundParallax
@onready var selector : Panel = $Selector

## Containers
@onready var entity_container: Node2D = $Containers/EntityContainer
@onready var object_container: Node2D = $Containers/ObjectContainer
@onready var projectile_container: Node2D = $Containers/ProjectileContainer
@onready var coin_container: Node2D = $Containers/CoinContainer

## TileMapLayers
@onready var GROUND_LAYER : TileMapLayer = $GroundLayer
@onready var OBJECT_LAYER : TileMapLayer = $ObjectLayer
@onready var FOREGROUND_LAYER : TileMapLayer = $ForegroundLayer

const SELECTION_TILE : Vector2i = Vector2i(0,4)
const TILE : Dictionary = {
	DEFAULT = Vector2i(7,0),
	BLOCKED = Vector2i(0,3),
	SELECT = Vector2i(0,4),
	TARGET = Vector2i(2,3)
}

var tile_size : Vector2i = Vector2i(32, 32)
var stage_buildings : Array[Node2D]: set = _set_state_buildings
var selected_object : TileObject #? Selected object node storage
var stored_object : TileObject #? Object that can be positioned or moved
var object_dict : Dictionary #? Arranged by tile_position
var previous_selected_cell : Vector2i #? draw_width
var previous_queried_cell : Vector2i #? Used for input resetting
#endregion

#region Main functions
func _ready() -> void:
	StageManager.start_stage(self)
	AudioManager.play_music(stage_songs, 0, false, true)
	
	UI.mouse_on_ui_changed.connect(_on_mouse_on_ui_changed)
	selector.size = tile_size
	
	background_parallax.set_visible(true)
	if !modulate_layer.visible: modulate_layer.visible = true

func _process(_delta) -> void:
	selector.global_position = position_to_tile(get_global_mouse_position()) * tile_size
	
	if check_coordinate: #? Output tile coordinate on screen
		var current_mouse_pos = get_global_mouse_position()
		var tile_position = position_to_tile(current_mouse_pos)

func _input(_event) -> void:
	if Input.is_action_just_pressed('click'):
		select_tile(position_to_tile(get_global_mouse_position()))

func _on_mouse_on_ui_changed(present : bool) -> void:
	selector.set_visible(!present)

func _set_state_buildings(input_array : Array) -> Array[Node2D]: ## Reorder based on distance to nexus, so that enemies always focus based on a clear order
	var order : Array[Array]
	var new_array : Array[Node2D]
	for n in input_array:
		order.append([n, n.building_order])
	order.sort_custom(func(a, b): return a[1] < b[1])
	for b in order:
		new_array.append(b[0])
	stage_buildings = new_array
	return new_array
#endregion

#region Tile management
## Converts a Vector2 coordinate into an accurate tile position
func position_to_tile(position_vector : Vector2) -> Vector2i: return GROUND_LAYER.local_to_map(position_vector)

func snap_to_tile(position_vector : Vector2) -> Vector2: return GROUND_LAYER.map_to_local(position_to_tile(position_vector))

func query_tile(layer : TileMapLayer, tile_position : Vector2i, custom_data_layer_id : int = 0): ## Query tile metadata
	var tile_data = layer.get_cell_tile_data(tile_position)
	if UI.interface.mouse_on_ui: return false #? Tile is invalid if the cursor is currently outside visible map (over UI elements)
	if tile_data: return tile_data.get_custom_data_by_layer_id(custom_data_layer_id)
	else: return false

func select_tile(tile_position):
	if UI.interface.mouse_on_ui: return #? Do not interact if mouse is in interface controls
	
	if previous_selected_cell: deselect_tile()
	var data
	var tile_data = GROUND_LAYER.get_cell_tile_data(tile_position)
	var object_data = OBJECT_LAYER.get_cell_tile_data(tile_position)
	if object_dict.has(tile_position): selected_object = object_dict[tile_position]['node']
	
	if is_instance_valid(selected_object):
		if selected_object is Tower: UI.interface.tower_panel.load_tower(selected_object)
		else: UI.interface.tower_panel._move(false)
		selected_object.visible_range = true
	
	if tile_data: data = tile_data.get_custom_data_by_layer_id(0)
	#TODO: UI.interface.tile_description_label.set_text(str(data))
	previous_selected_cell = tile_position

func deselect_tile() -> void:
	if UI.interface.mouse_on_ui: return #? Do not interact if mouse is in interface controls
	#TODO: UI.interface.object_description_label.set_text("")
	if is_instance_valid(selected_object): selected_object.visible_range = false
	selected_object = null

func query_tile_insertion(tile_position : Vector2i = Vector2i.ZERO) -> bool: #? Returns true if tile is valid
	if UI.interface.mouse_on_ui: return false #? Mouse is off limits on top of a control node
	
	if tile_position == Vector2i.ZERO: tile_position = position_to_tile(get_global_mouse_position())
	
	var object_query = query_tile(OBJECT_LAYER, tile_position)
	var tile_query = query_tile(GROUND_LAYER, tile_position, 1)
	var foreground_query = query_tile(FOREGROUND_LAYER, tile_position)
	
	if object_dict.has(tile_position): return false #? Tile space is occupied
	elif (object_query is Dictionary) or (foreground_query is Dictionary): return false # Returns negatively if tile is invalid
	elif (tile_query is bool): # Ground can be detected everywhere but we need to know if it's placeable
		if !tile_query: return false # Returns negatively if tile is not placeable
		else: return true # Returns positively
	else: return false # Returns negatively, for a placeable tile in ground layer wasn't found

func insert_tile_object( ## Called from turret/object button when inserted into a tile
		tile_object : TileObject,
		tile_position : Vector2i = position_to_tile(get_global_mouse_position())
	) -> bool:
	var tile_cost : int = tile_object.tower_value
	var coordinates : Vector2 = GROUND_LAYER.map_to_local(tile_position)
	var query_result : bool = query_tile_insertion(tile_position)
	
	#! Returns true if object is successfully placed, and false if not.
	if (!query_result): return false # Recheck. Only returns negatively if invalidated in a series of checks
	if (tile_cost > stage_agent.coins): return false # Returns negatively turret is more expensive than current total coins
	
	## Register
	tile_object.tile_position = tile_position
	object_dict[tile_position] = {'node': tile_object}
	
	## Insert
	# OBJECT_LAYER.set_cell(tile_position, 0, TILE.DEFAULT)
	tile_object.global_position = coordinates
	tile_object.reparent($Containers/ObjectContainer)
	stage_agent.change_coins(tile_object.tower_value)
	
	return true ## Return sucessfully

func request_removal(tile_position : Vector2i = Vector2i.MIN) -> bool:
	var object : Node
	if tile_position == Vector2i.MIN: tile_position = position_to_tile(get_global_mouse_position())
	if object_dict.has(tile_position): object = object_dict[tile_position]['node']
	if !object: return false
	
	var tower_value : int = roundi(object.tower_value * CASHBACK_FACTOR)
	var request : bool = await UI.event_layer.request_confirmation(
		'CONFIRM',
		'{0} {1} {2}'.format({0: TranslationServer.tr('DEMOLISH_REQUEST_TEXT'), 1: tower_value, 2: TranslationServer.tr('COINS').to_lower()}),
		'CONFIRM', 'CANCEL'
	)
	
	if request:
		remove_tile_object(tile_position, object)
		if object is Tower:
			if object.tower_upgrades.tower_element_reg: #? Return elements when tower sold
				object.tower_upgrades.tower_element_reg.quantity += 1
		stage_agent.change_coins(tower_value, true)
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

#region Single object management
#func _instantiate_tower(element_register : ElementRegister) -> void: #TODO
#	stored_object = ElementManager.TOWER_ROOT_SCENE.instantiate()
#	stored_object.element_register = element_register
#	object_container.add_child(stored_object)
#endregion
