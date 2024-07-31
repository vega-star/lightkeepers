class_name TowerButton extends Panel

@export_enum('TOWER', 'LIGHT', 'DECORATION') var object_type : String = 'TOWER'
@export var reference_rect : ReferenceRect
@export var target_tower_scene : PackedScene

@onready var cost_label = $CostLabel
@onready var tower_sprite = $TowerSprite

var stage : Node
var tower : Node
var stored_cost : int
var valid : bool
var position_valid : bool = true

func _ready():
	stage = get_tree().get_first_node_in_group('stage')
	var load_tower = target_tower_scene.instantiate()
	stored_cost = load_tower.tower_cost
	cost_label.set_text(str(stored_cost))
	tower_sprite.set_texture(load_tower.get_node('TowerSprite').get_texture())
	
	load_tower.queue_free()

func _on_gui_input(event):
	if Input.is_action_pressed("alt") or Input.is_action_pressed("escape"):
		if is_instance_valid(tower):
			tower.light_shape.queue_free()
			tower.queue_free()
		position_valid = false
		valid = false
		release_focus()
	
	if event is InputEventMouseButton and event.button_mask == 1 and valid: # Left mouse click
		tower = target_tower_scene.instantiate()
		tower.global_position = event.global_position
		tower.visible_range = true
		tower.top_level = true
		add_child(tower)
		tower.process_mode = Node.PROCESS_MODE_DISABLED
	elif event is InputEventMouseMotion and event.button_mask == 1: # Left mouse hold
		if is_instance_valid(tower): tower.global_position = event.global_position
		else: return
		
		if !stage: 
			stage = get_tree().get_first_node_in_group('stage')
			return
		
		var stage_query = stage.query_tile_insertion()
		if !stage_query: tower.set_modulate(Color.BROWN) # Position invalid
		else: tower.set_modulate(Color.WHITE) # Position valid
	elif event is InputEventMouseButton and event.button_mask == 0 and valid: # Left mouse released
		tower.visible_range = false
		tower.top_level = false
		var insert = stage.insert_tile_object(tower)
		if !insert: # Couldn't insert object because insertion failed
			tower.queue_free()
			return
		tower._adapt_in_tile()
		tower.process_mode = Node.PROCESS_MODE_INHERIT

func _on_focus_entered(): valid = true #? Simply resets valid when clicked again. Wouldn't work without this line!
