class_name Slot extends StaticBody2D

signal slot_emptied
signal slot_filled

const DEFAULT_SLOT_SIZE : Vector2 = Vector2(48, 48)
const SHAPE_RADIUS : float = 48

@export_enum('PRIMARY:0', 'ESSENCE:1') var slot_type : int
@export var is_output : bool = false

@onready var color_rect = $ColorRect

var object_in_slot : DraggableObject

var slot_locked : bool = false
var available : bool = true
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
	
	color_rect.set_visible(drag_status)

func request_insert(object) -> bool:
	if is_output: return false
	
	if available:
		object_in_slot = object
		object_in_slot.object_picked.connect(object_removed)
		
		available = false
		return true
	else: return false

func object_removed():
	available = true
	object_in_slot.object_picked.disconnect(object_removed)
	object_in_slot = null

func generate_output(output : String, phantom : bool):
	if !is_output: push_error('Trying to generate output on a input slot')
	var output_object
	
	add_child(output_object)

func _set_hover(is_hovering : bool):
	if is_output: return
	
	if is_hovering: modulate = Color(1.2, 1.2, 1.2)
	else: modulate = Color.WHITE
