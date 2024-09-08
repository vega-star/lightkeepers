## Fuse
# Will merge two Elements into a complex Essence
class_name FuseSystem extends Control

signal fuse_successful
signal fuse_failed

@export var delete_when_fused : bool = false

@onready var input_1 : Slot = $InputSlot1/Slot
@onready var input_2 : Slot = $InputSlot2/Slot
@onready var output : Slot = $OutputSlot/Output
@onready var confirm_button : TextureButton = $OutputSlot/OffsetControl/ConfirmButton

var current_combination : String

func _ready():
	input_1.slot_changed.connect(_check_slots)
	input_2.slot_changed.connect(_check_slots)
	confirm_button.pressed.connect(_on_confirm_button_pressed)

func _check_slots():
	if input_1.active_object and input_2.active_object: confirm_button.set_visible(true)
	else: confirm_button.set_visible(false)

func _on_confirm_button_pressed():
	var first_element = input_1.active_object.element.element_id
	var second_element = input_2.active_object.element.element_id
	var combination = EventManager.combine(first_element, second_element)
	if combination: EventManager.fuse(combination)
	
	input_1.active_object._return_to_slot(true)
	input_1._remove_object(delete_when_fused)
	input_2.active_object._return_to_slot(true)
	input_2._remove_object(delete_when_fused)
