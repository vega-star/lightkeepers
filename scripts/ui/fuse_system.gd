## Fuse System
# System that interprets input actions such as object insertion and button presses to fuse elements
# It calls upon ElementManager to do most of its actions, as ElementManager is a pure script and does not have an UI to interact with
class_name FuseSystem extends Control

signal fuse_successful
signal fuse_failed

@export var delete_when_fused : bool = false

@onready var input_1 : Slot = $InputSlot1/Slot
@onready var input_2 : Slot = $InputSlot2/Slot
@onready var output_slot : ControlSlot = $OutputSlot
@onready var confirm_button : TextureButton = $OutputSlot/OffsetControl/ConfirmButton

var current_combination : String
var result_element : Element
var result_element_reg : ElementRegister

func _ready():
	input_1.slot_changed.connect(_check_slots)
	input_2.slot_changed.connect(_check_slots)
	confirm_button.pressed.connect(_on_confirm_button_pressed)

func _check_slots():
	if input_1.active_object and input_2.active_object:
		confirm_button.set_visible(true)
		_check_combination()
	else: confirm_button.set_visible(false)

func _check_combination() -> Element:
	if !is_instance_valid(input_1.active_object) and !is_instance_valid(input_2.active_object): return null
	var first_element = input_1.active_object.element.element_id
	var second_element = input_2.active_object.element.element_id
	var combination = ElementManager.combine(first_element, second_element)
	if combination:
		result_element = ElementManager.fuse(combination)
		return result_element
	else: return null

func _on_confirm_button_pressed(): _fuse()

func _fuse() -> bool:
	if !result_element: return false ## Invalid element
	else:
		ElementManager.add_element(result_element, 1, 1)
		input_1.active_object._return_to_slot(true)
		input_1._remove_object(delete_when_fused)
		input_2.active_object._return_to_slot(true)
		input_2._remove_object(delete_when_fused)
		result_element = null
		result_element_reg = null
	return true
