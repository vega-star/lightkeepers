class_name TowerButton extends Panel

signal tower_selected
signal tower_placed

@export_enum('TOWER', 'LIGHT', 'DECORATION') var object_type : String = 'TOWER'
@export var reference_rect : ReferenceRect
@export var target_tower_scene : PackedScene

@onready var cost_label = $CostLabel
@onready var tower_sprite = $TowerSprite

var num_towers_placed : int = 0
var stage : Stage
var tower : TileObject
var tower_name : String
var stored_cost : int
var valid : bool
var position_valid : bool = true

func _ready():
	stage = get_tree().get_first_node_in_group('stage')
	await _update_button()

func _update_button():
	var load_tower : Tower = target_tower_scene.instantiate()
	stored_cost = load_tower.default_tower_cost
	cost_label.set_text(str(stored_cost))
	tower_sprite.set_texture(load_tower.tower_icon)
	set_tooltip_text(TranslationServer.tr(load_tower.name.to_upper()))
	tower_name = load_tower.tower_name
	load_tower.queue_free()

func _on_gui_input(event) -> void:
	if Input.is_action_pressed("alt") or Input.is_action_pressed("escape"):
		if is_instance_valid(tower): tower.remove_object()
		position_valid = false
		valid = false
		release_focus()
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if is_instance_valid(tower): tower.remove_object()
	
	if event is InputEventMouseButton and event.button_mask == 1 and valid: # Left mouse click. Runs only once
		tower_selected.emit()
		tower = target_tower_scene.instantiate()
		tower.global_position = event.global_position
		tower.visible_range = true
		tower.top_level = true
		tower.prop = true
		add_child(tower)
		tower.process_mode = Node.PROCESS_MODE_DISABLED
	
	elif event is InputEventMouseMotion and event.button_mask == 1: # Left mouse hold
		if !stage: stage = get_tree().get_first_node_in_group('stage'); return
		if is_instance_valid(tower): 
			tower.global_position = get_global_mouse_position()
			# tower.global_position = stage.snap_to_tile(event.global_position) # stage.snap_to_tile(get_global_mouse_position())
		else: return
		
		var stage_query = stage.query_tile_insertion()
		if !stage_query: tower.set_modulate(Color.BROWN) # Position invalid
		else: tower.set_modulate(Color.WHITE) # Position valid
	
	elif event is InputEventMouseButton and event.button_mask == 0 and valid: _try_insert() # Left mouse released

func _on_focus_entered(): valid = true #? Simply resets valid when clicked again. Wouldn't work without this line!

func _on_tower_placed(): num_towers_placed += 1

#region Tower controls
func _try_insert() -> bool:
	if !stage: stage = get_tree().get_first_node_in_group('stage'); assert(stage)
	
	tower.visible_range = false
	tower.top_level = false
	var insert = stage.insert_tile_object(tower)
	if !insert: tower.remove_object(); return false #? Couldn't insert object because insertion failed
	
	tower._adapt_in_tile()
	tower.process_mode = Node.PROCESS_MODE_INHERIT
	tower_placed.emit()
	tower = null
	return true
