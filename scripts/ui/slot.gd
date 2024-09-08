## Slot
# Acts as a placeable input
# Physical slot with 2D properties extending from StaticBody2D
# Has to be that way to detect CollisionShapes and element movement
class_name Slot extends StaticBody2D

signal slot_changed

const DEFAULT_SLOT_SIZE : Vector2 = Vector2(48, 48)
const SHAPE_RADIUS : float = 48

@export_enum('GENERIC:0','ELEMENT:1', 'ESSENCE:2') var slot_type : int = 0
@export var is_output : bool = false
@onready var color_rect = $ColorRect

var active_object : DraggableObject
var slot_locked : bool = false
var hovered : bool = false: set = _set_hover

func _ready(): 
	UI.drag_changed.connect(_drag_toggled)
	if active_object: active_object.object_picked.connect(_remove_object)

func _drag_toggled(drag_status):
	if is_output and drag_status: modulate = Color(1.5, 0.5, 0.5); return #? Drag active
	elif is_output and !drag_status: modulate = Color.WHITE; return # Drag inactive
	if OS.is_debug_build(): if color_rect: color_rect.set_visible(drag_status)

func request_insert(object : DraggableObject) -> bool:
	var object_type : int = object.element.element_type
	if slot_type != 0 and object_type != slot_type:
		printerr('Slot not compatible')
		return false
	
	if !is_instance_valid(active_object): #? Successful
		active_object = object
		active_object.object_picked.connect(_remove_object)
		slot_changed.emit()
		return true
	else:
		printerr('Slot refusing {0} insertion due to being already full with {1}'.format({0:object.name,1:active_object.name}))
		return false

func _remove_object(destroy : bool = false) -> void:
	slot_changed.emit()
	if is_instance_valid(active_object):
		active_object.object_picked.disconnect(_remove_object)
		active_object = null
	
	if destroy: active_object._destroy()

func spawn_output(output : String, phantom : bool):
	if !is_output: push_error('Trying to generate output on a input slot')
	var output_object : Object
	add_child(output_object)

func _set_hover(is_hovering : bool):
	if is_output: return
	if is_hovering: modulate = Color(1.2, 1.2, 1.2)
	else: modulate = Color.WHITE

func _on_visibility_changed(): if active_object and !is_visible_in_tree(): active_object._return_to_slot()
