extends Panel

@onready var source_sprite = $Sprite

var stage : Node
var sprite : Sprite2D
var valid : bool
var position_valid : bool = true

func _ready():
	stage = get_tree().get_first_node_in_group('stage')

func _on_gui_input(event):
	if !stage: stage = get_tree().get_first_node_in_group('stage')
	
	if Input.is_action_pressed("alt") or Input.is_action_pressed("escape"):
		if is_instance_valid(sprite):
			sprite.queue_free()
		valid = false
		release_focus()
	
	if event is InputEventMouseButton and event.button_mask == 1 and valid: # Left mouse click
		sprite = Sprite2D.new()
		sprite.set_texture(source_sprite.get_texture())
		sprite.global_position = event.global_position
		add_child(sprite)
	elif event is InputEventMouseMotion and event.button_mask == 1: # Left mouse hold
		if is_instance_valid(sprite): sprite.global_position = event.global_position
		else: return
		
		if !is_instance_valid(stage): return
		
		var stage_query = stage.query_tile_insertion()
		if !stage_query: sprite.set_modulate(Color.WHITE) # Position invalid
		else: sprite.set_modulate(Color.DIM_GRAY) # Position valid
	elif event is InputEventMouseButton and event.button_mask == 0 and valid: # Left mouse released
		if !is_instance_valid(stage): return
		var request = await stage.request_removal()
		sprite.queue_free()
		if !request: # Couldn't insert object because insertion failed
			return

func _on_focus_entered(): valid = true #? Simply resets valid when clicked again. Wouldn't work without this line!
