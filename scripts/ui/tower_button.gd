extends Panel

@export var target_tower_scene : PackedScene
# var tower_scene : PackedScene

var tower : Node
var valid : bool

func _ready():
	pass

func _on_gui_input(event):
	if Input.is_action_pressed("alt") or Input.is_action_pressed("escape"):
		if is_instance_valid(tower):
			tower.light_shape.queue_free()
			tower.queue_free()
		valid = false
		release_focus()
	
	if event is InputEventMouseButton and event.button_mask == 1 and valid: # Left mouse click
		tower = target_tower_scene.instantiate()
		tower.global_position = event.global_position
		tower.visible_range = true
		add_child(tower)
		tower.process_mode = Node.PROCESS_MODE_DISABLED
	elif event is InputEventMouseMotion and event.button_mask == 1 and valid: # Left mouse hold
		tower.global_position = event.global_position
	elif event is InputEventMouseButton and event.button_mask == 0 and valid: # Left mouse released
		tower.visible_range = false
		var stage = get_tree().get_first_node_in_group('stage')
		stage.insert_tile_object(tower)
		tower._adapt_in_tile()
		tower.process_mode = Node.PROCESS_MODE_INHERIT

func _on_focus_entered():
	valid = true
