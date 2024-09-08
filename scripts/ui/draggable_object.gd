class_name DraggableObject extends Node2D

signal object_inserted
signal object_picked

const INPUT_COOLDOWN : float = 0.2
const DEFAULT_ORB_ICON : Texture2D = preload("res://assets/sprites/misc/orb.png")

@export var active_slot : Slot #? Currently active slot
@export var home_slot : Slot #? Slot on which it returns if something goes wrong or the screen which it was positioned gets closed
@export var source_object : bool = false
@export var element : Element

@onready var object_collision = $ObjectCollision
@onready var object_collision_area = $ObjectCollision/ObjectCollisionArea

var offset : Vector2
var initial_position : Vector2
var object_type : int
var target_slot : Slot #? Slot selected between overlapping bodies 

var locked : bool = false
var draggable : bool = false
var is_inside_dropable : bool = false

func _ready() -> void:
	if !active_slot: active_slot = home_slot
	object_type = element.element_type

func _set_draggable(drag : bool) -> void:
	draggable = drag
	if drag: scale = Vector2(1.05, 1.05)
	else: scale = Vector2(1, 1)

#? UI bool 'is_dragging' serves as a control point to prevent multiple dragging actions, preventing dragging multiple objects
func _on_object_collision_mouse_entered() -> void: if !UI.is_dragging: _set_draggable(true) #? Activate object when mouse enters it collision shape
func _on_object_collision_mouse_exited() -> void: if !UI.is_dragging: _set_draggable(false) #? Deactivate object

#? Body detection handling
func _on_object_collision_body_entered(body) -> void: if body is Slot or body.is_in_group('dropable'): body.hovered = true; is_inside_dropable = true; target_slot = body
func _on_object_collision_body_exited(body) -> void: if body is Slot or body.is_in_group('dropable'): body.hovered = false; is_inside_dropable = false

func _process(_delta) -> void:
	if draggable:
		if object_collision.get_overlapping_bodies().size() > 1 and InputEventMouseMotion: #? Overlapping bodies solution
			var distance_array : Array = []
			is_inside_dropable = true
			for o in object_collision.get_overlapping_bodies(): distance_array.append([o, global_position.distance_to(o.global_position)])
			distance_array.sort()
			target_slot = distance_array[0][0] #? Closest target slot
		
		if Input.is_action_just_pressed('click'): #? Click action
			if locked: return
			object_picked.emit()
			UI.is_dragging = true
			_set_draggable(true)
			initial_position = global_position
			offset = get_global_mouse_position() - global_position
		
		if Input.is_action_just_pressed('alt'): #? Cancel with alt (Right mouse button)
			object_picked.emit()
			UI.is_dragging = false
			_return_to_slot(true)
		
		if Input.is_action_pressed('click'): global_position = get_global_mouse_position() - offset #? Drag
		elif Input.is_action_just_released('click'): #? Release
			print('Released click')
			UI.is_dragging = false
			if target_slot: _insert(target_slot)
			else: _return_to_slot()

func _return_to_slot(force : bool = false) -> void:
	UI.is_dragging = false
	object_picked.emit()
	if !is_instance_valid(active_slot) or force: active_slot = home_slot
	print(self.name + ' returning to slot ' + str(active_slot.get_path()))
	_insert(active_slot)

func _insert(slot : Slot) -> bool:
	_set_draggable(false)
	if is_instance_valid(slot):
		var release_tween = get_tree().create_tween()
		var request = slot.request_insert(self)
		if request: #? Slot available and inserting object
			print('Insertion successful')
			active_slot = slot
			object_inserted.emit()
			release_tween.tween_property(self, "global_position", slot.global_position, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
			reparent(active_slot)
		else: #? Failed to insert
			print('Insertion failed')
			if is_instance_valid(slot.active_object): return _replace_slot(active_slot, slot) #? Failed because there's already an self there. Will switch place with this self if it's already on a slot
			else: return false
		return true #? Object successfully inserted and returning positively
	else: return false

func _replace_slot(previous_slot : Slot, next_slot : Slot) -> bool:
	if next_slot.is_output: return false
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

func _destroy():
	queue_free()
