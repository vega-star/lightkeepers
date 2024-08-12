class_name DraggableObject extends Node2D

signal object_dragged
signal object_picked
signal source_quantity_change(previous_quantity : int, change : int)

const HC_OFFSET = Vector2(64, 64)

@export var container : Node
@export var home_container : Container ## Return to this node position if something goes wrong or the screen which it was positioned gets closed
@export var source_object : bool = false ## Instead of moving the object, creates another one
@export var element : Element

@onready var object_collision = $ObjectCollision
@onready var object_collision_area = $ObjectCollision/ObjectCollisionArea

var offset : Vector2
var initial_position : Vector2

var object : Object = self
var object_type : int
var slot_reference : Slot
var slot_occupied : Slot
var metadata : Dictionary

var source_quantity : int = 1
var volatile : bool = false

var locked : bool = false
var draggable : bool = false
var is_inside_dropable : bool = false
var dropable_occupied : bool = false

func _ready():
	if !home_container: if owner is Container: home_container = owner
	object_type = element.element_type

func _process(delta):
	if draggable:
		if !is_instance_valid(object): return
		
		if object_collision.get_overlapping_bodies().size() > 1 and InputEventMouseMotion: # If colliding with multiple slots, choose the closest one
			var distance_array : Array = []
			is_inside_dropable = true
			for o in object_collision.get_overlapping_bodies():
				distance_array.append([o, global_position.distance_to(o.global_position)])
			distance_array.sort()
			slot_reference = distance_array[0][0]
		
		if Input.is_action_just_pressed('click'): # Click
			if locked: return
			
			UI.is_dragging = true
			object_picked.emit()
			
			object.initial_position = object.global_position
			offset = get_global_mouse_position() - global_position
		
		if Input.is_action_just_pressed('alt'):
			object_picked.emit()
			UI.is_dragging = false
			_return_pos(true)
		
		if Input.is_action_pressed('click'): # Drag
			object.global_position = get_global_mouse_position() - offset
		elif Input.is_action_just_released('click'): # Release
			UI.is_dragging = false
			var tween = get_tree().create_tween()
			var slot_available : bool
			
			# print('INPUT | Inserting {0} into {1} | AVAILABLE: {2} | DROPABLE: {3}'.format({0:self.name, 1:slot_reference, 2: slot_available, 3: is_inside_dropable}))
			
			if is_instance_valid(slot_reference):
				slot_available = slot_reference.request_insert(object)
				
				if slot_available: # Inserting into slot
					tween.tween_property(object, "global_position", slot_reference.global_position, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
					slot_occupied = slot_reference
				else: # Failed to insert
					var object_in_slot = slot_reference.object_in_slot
					if object_in_slot and slot_occupied: # Failed because there's already an object there. Will switch place with this object if it's already on a slot
						var object_tween = get_tree().create_tween()
						
						object_in_slot.object_picked.emit()
						slot_occupied.request_insert(object_in_slot)
						object_tween.tween_property(object_in_slot, "global_position", slot_occupied.global_position, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
						
						slot_reference.request_insert(object)
						tween.tween_property(object, "global_position", slot_reference.global_position, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
						slot_occupied = slot_reference
					else: _return_pos()
					
					if volatile: queue_free()
			else:
				_return_pos()
			
			# object_collision_area.set_disabled(true)
			# object_collision_area.set_disabled(false)
			draggable = false

func _return_pos(return_to_home : bool = false):
	var tween = get_tree().create_tween()
	
	if is_instance_valid(home_container) and return_to_home:
		initial_position = home_container.global_position + HC_OFFSET
		slot_occupied = null
		tween.tween_property(object, "global_position", initial_position, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	else: 
		tween.tween_property(object, "global_position", initial_position, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)

func _on_object_collision_body_entered(body):
	if body.is_in_group('dropable'):
		if body is Slot: body.hovered = true
		is_inside_dropable = true
		slot_reference = body

func _on_object_collision_body_exited(body):
	if body.is_in_group('dropable'):
		if body is Slot: body.hovered = false
		is_inside_dropable = false

func _on_object_collision_mouse_entered(): 
	if !UI.is_dragging: _set_draggable(true)
func _on_object_collision_mouse_exited(): 
	if !UI.is_dragging: _set_draggable(false)

func _set_draggable(drag : bool) -> void:
	# print('SET DRAG TO %s' % str(drag))
	draggable = drag
	match drag:
		true:
			scale = Vector2(1.05, 1.05)
		false:
			scale = Vector2(1, 1)

func _on_source_quantity_change(previous_quantity, change):
	source_quantity += change
	if source_quantity == 0: locked = true
	else: locked = false
