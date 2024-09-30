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
@onready var slot_effects : CPUParticles2D = $OutputSlot/Slot/SlotEffects

const MOVEMENT_OFFSET : Vector2 = Vector2(64, 64)

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
		_remove_prop()
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
	if is_instance_valid(input_2.active_object): second_element = input_2.active_object.element.element_id
	else: return null
	var combination = ElementManager.combine(first_element, second_element)
	if combination:
		result_element = ElementManager.fuse(combination)
		if invoke_prop:
			prop_object = ElementManager._set_object(output_slot.slot, result_element, 'Prop')
			prop_object.locked = true
			prop_object.force_show_label = true
			prop_object.element_label.set_visible(true)
			slot_effects.emitting = true
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
		result_element_reg = ElementManager.add_element(result_element, 2, 1)
		result_position = get_node(result_element_reg.control_slot).global_position
		if delete_when_fused: pop(true)
		else: pop()
		result_element = null
		result_element_reg = null
		invoke_prop = true
	fuse_done.emit(true)
	return true

## Remove objects from input slots
func pop(destroy : bool = false) -> void:
	if !is_instance_valid(input_1.active_object) or !is_instance_valid(input_2.active_object): return 
	if destroy:
		input_1._destroy_active_object()
		input_2._destroy_active_object()
		return
	input_1.active_object._return_to_slot(true)
	input_2.active_object._return_to_slot(true)

func _remove_prop() -> void:
	if is_instance_valid(prop_object):
		if !UI.HUD.elements_storage_panel.visible: 
			$"../../../../Shop/ShopButtons/ShopButtonsContainer/ElementsButton".set_pressed(true)
			UI.HUD._on_shop_button_pressed(1) #? Show elements menu
		prop_object.queue_free()
		prop_object = null
		slot_effects.emitting = false
		
		## TODO: Prop animation
		# prop_object.volatile = true
		# await get_tree().create_timer(0.3).timeout
		# prop_object._move_to(result_position + MOVEMENT_OFFSET)

func _on_visibility_changed() -> void:
	if !visible: _remove_prop()
