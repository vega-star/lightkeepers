class_name DraggableObject extends Node2D

signal object_picked
signal object_inserted

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
@export var home_slot : Slot #? Slot on which it returns if something goes wrong or the screen which it was positioned gets closed
@export var element : Element: set = _set_element
@export var debug : bool = false

@onready var object_collision : Area2D = $ObjectCollision
@onready var object_collision_area : CollisionShape2D = $ObjectCollision/ObjectCollisionArea
@onready var object_element_sprite : Sprite2D = $ObjectElement
@onready var element_label : Label = $ElementLabel
@onready var object_orb : Sprite2D = $ObjectOrb

var offset : Vector2
var initial_position : Vector2
var object_type : int
var target_slot : Slot #? Slot selected between overlapping bodies 

var force_show_label : bool = false
var locked : bool = false
var volatile : bool = false
var draggable : bool = false
var is_inside_dropable : bool = false
#endregion 

#region Main processes
func _ready() -> void:
	assert(object_collision.input_pickable)
	if !active_slot: active_slot = home_slot
	object_type = element.element_type
	if !force_show_label: $ElementLabel.visible = false

func _set_element(new_element : Element) -> void:
	element = new_element
	object_type = new_element.element_type
	if !is_node_ready(): await ready
	element_label.set_text(TranslationServer.tr(element.element_id.to_upper()).capitalize())
	if ELEMENT_COLORS.has(element.element_id):
		object_orb.material = object_orb.material.duplicate()
		object_orb.material.set("shader_parameter/line_color", ELEMENT_COLORS[element.element_id])

func _process(_delta) -> void:
	if draggable and !locked: #? Dragging processes
		if object_collision.get_overlapping_bodies().size() > 1 and InputEventMouseMotion: #? Overlapping bodies solution
			var distance_array : Array = []
			is_inside_dropable = true
			for o in object_collision.get_overlapping_bodies(): distance_array.append([o, global_position.distance_to(o.global_position)])
			distance_array.sort()
			target_slot = distance_array[0][0] #? Closest target slot
		
		if Input.is_action_just_pressed('click'): #? Click action
			if locked: return
			if UI.is_dragging: _set_draggable(false) #? Already dragging a object. Can only pick one per time
			UI.is_dragging = true
			object_picked.emit()
			initial_position = global_position
			offset = get_global_mouse_position() - global_position
		
		if Input.is_action_just_pressed('alt'): #? Cancel with alt (Right mouse button)
			if active_slot == home_slot: return
			object_picked.emit()
			UI.is_dragging = false
			_return_to_slot(true)
		
		if Input.is_action_pressed('click'): global_position = get_global_mouse_position() - offset #? Drag
		
		elif Input.is_action_just_released('click'): #? Release
			UI.is_dragging = false
			if target_slot: _insert(target_slot)
			else: _return_to_slot()
#endregion

#region Collision Controls
## Body detection
#? Uses a series of conditions to detect if is_inside_dropable is true. In case there are multiple bodies, there's a solution for that below
func _on_object_collision_body_entered(body) -> void: 
	if body is Slot or body.is_in_group('dropable'): 
		body.hovered = true; is_inside_dropable = true
		target_slot = body

func _on_object_collision_body_exited(body) -> void: 
	if body is Slot or body.is_in_group('dropable'): 
		body.hovered = false; is_inside_dropable = false

## Internal drag switch
#? Defines if object follows mouse and enables all object behaviors
func _set_draggable(drag : bool) -> void:
	draggable = drag
	if drag:
		$ElementLabel.visible = true
		scale = Vector2(1.05, 1.05)
	else:
		if !force_show_label: $ElementLabel.visible = false
		scale = Vector2(1, 1)

## External drag switch
#? UI bool 'is_dragging' serves as a control point to prevent multiple dragging actions
func _on_object_collision_mouse_entered() -> void: if !UI.is_dragging: _set_draggable(true) #? Activate object when mouse enters it collision shape
func _on_object_collision_mouse_exited() -> void: if !UI.is_dragging: _set_draggable(false) #? Deactivate object
#endregion

#region Slot controls
func _move_to(position : Vector2) -> void:
	var move_tween = get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	move_tween.tween_property(self, "global_position", position, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	if volatile: #? Delete this object after returning
		await move_tween.finished
		queue_free()

func _return_to_slot(return_home : bool = false) -> void:
	UI.is_dragging = false
	if !is_instance_valid(target_slot) or return_home: active_slot = home_slot
	_insert(active_slot)

func _insert(slot : Slot) -> bool:
	_set_draggable(false)
	if is_instance_valid(slot):
		var request = slot.request_insert(self)
		if request: #? Slot available and inserting object
			active_slot = slot
			object_inserted.emit()
			_move_to(slot.global_position)
			reparent(active_slot)
		else: #? Failed to insert
			if is_instance_valid(slot.active_object): return _replace_slot(active_slot, slot) #? Failed because slot is occupied. Will replace such object.
			else: #! Failed in every check
				push_warning('Object failed to insert in every instance. If force is true, then the target slot will be fully cleansed!')
				assert(home_slot)
				var forced_request = home_slot.request_insert(self)
				if !forced_request: push_error('Home slot ', home_slot.get_path() ,' is not receiving such object with element ', self.element.element_id)
				active_slot = home_slot
				object_inserted.emit()
				_move_to(home_slot.global_position)
				reparent(home_slot)
				return true
		return true #? Object successfully inserted and returning positively
	else: return false

func _replace_slot(_previous_slot : Slot, next_slot : Slot) -> bool: #? Switch objects position
	if _previous_slot.is_output and !next_slot.is_output: #? Target object is ocuppying an input slot but cannot be switched.
		next_slot.active_object._return_to_slot(true)
		next_slot._remove_object()
		_insert(next_slot)
		return true
	
	if next_slot.is_output: _return_to_slot(true); return false
	if active_slot == next_slot: _return_to_slot(true); return false
	
	var target_object = next_slot.active_object
	
	active_slot._remove_object()
	next_slot._remove_object()
	target_object._insert(active_slot)
	_insert(next_slot)
	return true

func _on_object_inserted() -> void:
	UI.is_dragging = false
	object_collision_area.set_disabled(true)
	await get_tree().create_timer(INPUT_COOLDOWN).timeout
	object_collision_area.set_disabled(false)

func _destroy() -> void:
	object_picked.emit()
	queue_free()
#endregion
