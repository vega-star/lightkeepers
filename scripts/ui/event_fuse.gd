extends Event

signal fuse_successful
signal fuse_failed

## Fuse
# Will merge two Elements into a complex Essence

@onready var input_1 = $InputSlots/InputSlot1/Slot
@onready var input_2 = $InputSlots/InputSlot2/Input2
@onready var output = $OutputSlot/Output
@onready var close_event_button = $CloseEventButton
@onready var confirm_button = $ConfirmButton

var current_combination : String

func _ready():
	input_1.slot_changed.connect(_check_slots)
	input_2.slot_changed.connect(_check_slots)
	_set_event_ready()

func _input(event):
	if has_focus() and Input.is_action_pressed('escape'): _close_event()

func _on_close_event_button_pressed(): _close_event()

func _check_slots():
	if input_1.object_in_slot and input_2.object_in_slot: confirm_button.set_visible(true)
	else: confirm_button.set_visible(false)

func _on_confirm_button_pressed():
	var first_element = input_1.object_in_slot.element.element_id
	var second_element = input_2.object_in_slot.element.element_id
	var combination = EventManager.combine(first_element, second_element)
	print(combination)
	
	input_1.object_removed(true)
	input_2.object_removed(true)
