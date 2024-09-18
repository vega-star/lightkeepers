## Fuse System
# System that interprets input actions such as object insertion and button presses to fuse elements
# It calls upon ElementManager to do most of its actions, as ElementManager is a pure script and does not have an UI to interact with
class_name FuseSystem extends Control

signal fuse_done(status : bool)

@export var delete_when_fused : bool = true
@export var invoke_prop : bool = true

@onready var input_1 : Slot = $InputSlot1/Slot
@onready var input_2 : Slot = $InputSlot2/Slot
@onready var output_slot : ControlSlot = $OutputSlot
@onready var confirm_button : TextureButton = $OutputSlot/OffsetControl/ConfirmButton

var current_combination : String
var prop_object : DraggableObject
var result_element : Element
var result_element_reg : ElementRegister
var result_position : Vector2

func _ready():
	input_1.slot_changed.connect(_check_slots)
	input_2.slot_changed.connect(_check_slots)
	confirm_button.pressed.connect(_on_confirm_button_pressed)

func _check_slots():
	if input_1.active_object and input_2.active_object:
		confirm_button.set_visible(true)
		_check_combination()
	else:
		_remove_prop()
		confirm_button.set_visible(false)

func _check_combination() -> Element:
	var first_element : String
	var second_element : String
	if is_instance_valid(input_1.active_object): first_element = input_1.active_object.element.element_id
	else: return null
	if is_instance_valid(input_1.active_object): second_element = input_2.active_object.element.element_id
	else: return null
	var combination = ElementManager.combine(first_element, second_element)
	if combination:
		result_element = ElementManager.fuse(combination)
		if invoke_prop:
			prop_object = ElementManager._set_object(output_slot.slot, result_element, 'Prop')
			prop_object.locked = true
		return result_element
	else: return null

func _on_confirm_button_pressed(): _fuse()

func _fuse() -> bool:
	_remove_prop()
	if !result_element:
		fuse_done.emit(false)
		return false ## Invalid element
	else:
		invoke_prop = false
		result_element_reg = ElementManager.add_element(result_element, 1, 1)
		result_position = get_node(result_element_reg.control_slot).global_position
		if delete_when_fused:
			input_1._destroy_active_object()
			input_2._destroy_active_object()
		else:
			input_1.active_object._return_to_slot(true)
			input_2.active_object._return_to_slot(true)
		result_element = null
		result_element_reg = null
		invoke_prop = true
	fuse_done.emit(true)
	return true

func _remove_prop() -> void:
	if is_instance_valid(prop_object):
		var modulate_tween = get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		prop_object.volatile = true
		if !UI.HUD.essence_slots.visible: $"../../../../Shop/ShopButtons/ShopButtonsContainer/ElementsButton".pressed
		prop_object._move_to(result_position)
		modulate_tween.tween_property(prop_object, "modulate", Color.TRANSPARENT, 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
		prop_object = null
