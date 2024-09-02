## Slot
# Acts as a placeable input
# Physical slot with 2D properties extending from StaticBody2D
# Has to be that way to detect CollisionShapes and element movement
class_name Slot extends StaticBody2D

signal slot_changed
signal slot_emptied
signal slot_filled

const DEFAULT_SLOT_SIZE : Vector2 = Vector2(48, 48)
const SHAPE_RADIUS : float = 48

@export_enum('GENERIC:0','ELEMENT:1', 'ESSENCE:2') var slot_type : int = 0
@export var is_output : bool = false
@onready var color_rect = $ColorRect

var object_in_slot : DraggableObject
var slot_locked : bool = false
var hovered : bool = false: set = _set_hover

func _ready():
	UI.drag_changed.connect(_drag_toggled)

func _drag_toggled(drag_status):
	if is_output and drag_status: 
		modulate = Color(1.5, 0.5, 0.5)
		return
	elif is_output and !drag_status:
		modulate = Color.WHITE
		return
	if OS.is_debug_build(): if color_rect: color_rect.set_visible(drag_status)

func request_insert(object) -> bool:
	if is_output or !visible: return false
	
	var object_type : int = object.object_type
	
	if slot_type != 0 and object_type != slot_type:
		printerr('Slot not compatible')
		return false
	
	if !object_in_slot:
		object_in_slot = object
		object_in_slot.object_picked.connect(object_removed)
		slot_filled.emit()
		return true
	else:
		return false

func object_removed(forced : bool = false):
	if forced: object_in_slot._return_pos(forced)
	object_in_slot.object_picked.disconnect(object_removed)
	object_in_slot = null
	slot_emptied.emit()

func spawn_output(output : String, phantom : bool):
	if !is_output: push_error('Trying to generate output on a input slot')
	var output_object : Object
	add_child(output_object)

func _set_hover(is_hovering : bool):
	if is_output: return
	if is_hovering: modulate = Color(1.2, 1.2, 1.2)
	else: modulate = Color.WHITE

func _on_visibility_changed():
	if object_in_slot and !is_visible_in_tree(): object_in_slot._return_pos(true)

func _on_slot_emptied(): slot_changed.emit()
func _on_slot_filled(): slot_changed.emit()
func _on_slot_changed(): pass
