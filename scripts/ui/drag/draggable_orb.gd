## DraggableOrb
## Complex drag-n-drop class with multiple functions to fit in slots, create towers, all the fun things
## Tried my best to not clusterize these functions
class_name DraggableOrb extends Node2D

signal orb_picked
signal orb_inserted

const ELEMENT_COLORS : Dictionary = {
	"fire": Color.ORANGE_RED,
	"water": Color.BLUE,
	"air": Color.CYAN,
	"earth": Color.SADDLE_BROWN,
	"cursed": Color.CRIMSON }
const INPUT_COOLDOWN : float = 0.2
const DEFAULT_ORB_ICON : Texture2D = preload("res://assets/sprites/misc/orb.png")

#region Variables
@export var active_slot : Slot #? Currently active slot
@export var home_slot : Slot #? Slot on which it returns if requested or something goes wrong
@export var element_register : ElementRegister: set = _set_element_reg
@export var element : Element: set = _set_element
@export var debug : bool = false

@onready var orb_sprite : Sprite2D = $Orb
@onready var orb_element_sprite : DraggableOrbSprite = $Orb/OrbElement
@onready var orb_collision : Area2D = $OrbCollision
@onready var orb_collision_area : CollisionShape2D = $OrbCollision/OrbCollisionArea
@onready var element_label : Label = $ElementLabel

var target_slot : Slot #? Slot selected between overlapping bodies 

var orb_type : int
var offset : Vector2
var initial_position : Vector2

var locked : bool = false
var volatile : bool = false
var draggable : bool = false
var is_inside_dropable : bool = false
var force_show_label : bool = false

var prop_tower : Tower
var valid_tower : bool: set = _on_tower_validation
#endregion 

#region Main processes
func _ready() -> void:
	assert(orb_collision.input_pickable)
	if !active_slot: active_slot = home_slot
	orb_type = element.element_type
	if !force_show_label: element_label.visible = false

func _set_element_reg(new_reg : ElementRegister) -> void: ## Runs first
	element_register = new_reg
	element = element_register.element

func _set_element(new_element : Element) -> void: ## Runs in sequence after register is updated
	element = new_element
	orb_type = new_element.element_type
	if !is_node_ready(): await ready
	element_label.set_text(TranslationServer.tr(element.element_id.to_upper()).capitalize())
	set_name(new_element.element_id.capitalize() + "Orb")

## External drag switch
#? UI bool 'is_dragging' serves as a control point to prevent multiple dragging actions
func _on_orb_collision_mouse_entered() -> void: if !UI.is_dragging: _set_draggable(true) #? Activate orb when mouse enters it collision shape
func _on_orb_collision_mouse_exited() -> void: if !UI.is_dragging: _set_draggable(false) #? Deactivate orb

func _unhandled_input(event : InputEvent) -> void:
	var n_event : InputEventMouseMotion
	if event is InputEventScreenTouch: #? Touch compatibility
		if event.pressed:
			n_event = InputEventMouseMotion.new()
			n_event.button_mask = MOUSE_BUTTON_MASK_LEFT
			n_event.position = event.position
			n_event.pressed = event.pressed
		Input.parse_input_event(n_event)

func _process(_delta) -> void:
	if draggable and !locked: #? Dragging processes
		if orb_collision.get_overlapping_bodies().size() > 1 and InputEventMouseMotion: #? Overlapping bodies solution
			var distance_array : Array = []
			is_inside_dropable = true
			for o in orb_collision.get_overlapping_bodies(): distance_array.append([o, global_position.distance_to(o.global_position)])
			distance_array.sort()
			target_slot = distance_array[0][0] #? Closest target slot
		
		if Input.is_action_just_pressed('click'): #? Click action
			if locked: return
			if UI.is_dragging: _set_draggable(false) #? Already dragging a orb. Can only pick one per time
			UI.is_dragging = true
			
			_instantiate_tower()
			orb_picked.emit()
			initial_position = global_position
			offset = get_global_mouse_position() - global_position
		
		if Input.is_action_just_pressed('alt'): #? Cancel with alt (Right mouse button)
			if active_slot == home_slot: return
			orb_picked.emit()
			UI.is_dragging = false
			_return_to_slot(true)
		
		if Input.is_action_pressed('click'): # Hold / Drag
			global_position = get_global_mouse_position() - offset
			valid_tower = StageManager.active_stage.query_tile_insertion()
		
		elif Input.is_action_just_released('click'): #? Release
			UI.is_dragging = false
			if valid_tower: _invoke_tower()
			elif target_slot: _insert(target_slot)
			else: _return_to_slot()

func _toggle_orb(toggle : bool) -> void:
	var toggle_tween : Tween = get_tree().create_tween()
	var modulation : Color
	if toggle: modulation = Color.WHITE
	else: modulation = Color(1,1,1,0.1)
	toggle_tween.tween_property(self, "modulate", modulation, 0.3)
#endregion

#region Slot controls
func _move_to(new_position : Vector2) -> void: ## Smooth movement to a specific position
	var move_tween = get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	move_tween.tween_property(self, "global_position", new_position, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	if volatile: #? Delete this orb after returning
		await move_tween.finished
		queue_free()

func _return_to_slot(return_home : bool = false) -> void: ## Return orb to home slot
	UI.is_dragging = false
	if !is_instance_valid(target_slot) or return_home: active_slot = home_slot
	_insert(active_slot)

func _insert(slot : Slot) -> bool: ##? Insert orb into a new slot
	_set_draggable(false)
	if is_instance_valid(slot):
		var request = slot.request_insert(self)
		if request: #? Slot available and inserting orb
			active_slot = slot
			orb_inserted.emit()
			_move_to(slot.global_position)
			reparent(active_slot)
		else: #? Failed to insert
			if is_instance_valid(slot.active_orb): return _replace_slot(active_slot, slot) #? Failed because slot is occupied. Will replace such orb.
			else: #! Failed in every check
				push_warning('Orb failed to insert in every instance. If force is true, then the target slot will be fully cleansed!')
				assert(home_slot)
				var forced_request = home_slot.request_insert(self)
				if !forced_request: push_error('Home slot ', home_slot.get_path() ,' is not receiving such orb with element ', self.element.element_id)
				active_slot = home_slot
				orb_inserted.emit()
				_move_to(home_slot.global_position)
				reparent(home_slot)
				return true
		return true #? Orb successfully inserted and returning positively
	else: return false

func _replace_slot(_previous_slot : Slot, next_slot : Slot) -> bool: #? Switch orbs position
	if _previous_slot.is_output and !next_slot.is_output: #? Target orb is ocuppying an input slot but cannot be switched.
		next_slot.active_orb._return_to_slot(true)
		next_slot._remove_orb()
		_insert(next_slot)
		return true
	
	if next_slot.is_output: _return_to_slot(true); return false
	if active_slot == next_slot: _return_to_slot(true); return false
	
	var target_orb = next_slot.active_orb
	
	active_slot._remove_orb()
	next_slot._remove_orb()
	target_orb._insert(active_slot)
	_insert(next_slot)
	return true

func _on_orb_inserted() -> void:
	UI.is_dragging = false
	orb_collision_area.set_disabled(true)
	await get_tree().create_timer(INPUT_COOLDOWN).timeout
	orb_collision_area.set_disabled(false)

func destroy() -> void:
	orb_picked.emit()
	queue_free()
#endregion

#region Collision Controls
## Body detection
#? Uses a series of conditions to detect if is_inside_dropable is true. In case there are multiple bodies, there's a solution for that below
func _on_orb_collision_body_entered(body) -> void: 
	if body is Slot or body.is_in_group('dropable'): 
		body.hovered = true; is_inside_dropable = true
		target_slot = body

func _on_orb_collision_body_exited(body) -> void: 
	if body is Slot or body.is_in_group('dropable'): 
		body.hovered = false; is_inside_dropable = false

## Internal drag switch
#? Defines if orb follows mouse and enables all orb behaviors
func _set_draggable(drag : bool) -> void:
	if debug: print(self.name, ' is draggable? - ', str(draggable))
	draggable = drag
	if drag:
		element_label.visible = true
		scale = Vector2(1.05, 1.05)
	else:
		if !force_show_label: element_label.visible = false
		scale = Vector2(1, 1)
#endregion

#region Tower functions
func _instantiate_tower() -> void:
	prop_tower = ElementManager.TOWER_ROOT_SCENE.instantiate()
	prop_tower.element_register = element_register
	add_child(prop_tower)

func _on_tower_validation(is_tower_valid : bool) -> void:
	valid_tower = is_tower_valid
	_toggle_orb(!valid_tower)

func _invoke_tower() -> bool:
	assert(StageManager.active_stage)
	assert(prop_tower)
	var insert = StageManager.active_stage.insert_tile_object(prop_tower)
	if !insert:
		prop_tower.remove_object()
		_return_to_slot(true)
		printerr('Tower insertion failed'); return false #? Couldn't insert orb because insertion failed
	else: destroy()
	prop_tower._adapt_in_tile()
	prop_tower.process_mode = Node.PROCESS_MODE_INHERIT
	prop_tower.tower_placed.emit()
	return true
#endregion
