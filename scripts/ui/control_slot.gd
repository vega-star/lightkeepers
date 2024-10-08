## Control slot
# Stores a Slot that is a 2D node with positional properties, but can also be stored into other containers
# This node is useful to attach slots in UI without getting to modify the slots itself!
class_name ControlSlot extends CenterContainer

signal control_slot_changed

const MINIMUM_SIZE : Vector2 = Vector2(96,96)

@onready var slot : Slot = $Slot : set = _config_slot

@export var slot_register : ElementRegister : set = _config_register
@export var toggle_based_on_quantity : bool = true

func _ready() -> void:
	slot.slot_changed.connect(_on_slot_changed)
	set_custom_minimum_size(MINIMUM_SIZE)

func _config_slot(new_slot : Slot) -> void:
	slot = new_slot
	slot.slot_changed.connect(_on_slot_changed)

func _config_register(reg : ElementRegister) -> void:
	if slot_register: slot_register.element_quantity_changed.disconnect(_on_quantity_changed)
	slot_register = reg
	slot_register.element_quantity_changed.connect(_on_quantity_changed)
	$OffsetControl/QuantityLabel.text = str(slot_register.quantity)

func _on_slot_changed() -> void: control_slot_changed.emit()

func _on_quantity_changed(new_quantity : int) -> void: $OffsetControl/QuantityLabel.text = str(new_quantity)
