## Control slot
# Stores a Slot that is a 2D node with positional properties, but can also be stored into other containers
# This node is useful to attach slots in UI without getting to modify the slots itself!
class_name ControlSlot extends CenterContainer

signal control_slot_changed

const MINIMUM_SIZE : Vector2 = Vector2(96,96)

@onready var quantity_label = $OffsetControl/QuantityLabel
@onready var slot = $Slot : set = _config_slot

@export var slot_register : ElementRegister : set = _config_register

func _ready():
	slot.slot_changed.connect(_on_slot_changed)
	set_custom_minimum_size(MINIMUM_SIZE)

func _config_slot(new_slot : Slot):
	slot = new_slot
	slot.slot_changed.connect(_on_slot_changed)

func _config_register(reg : ElementRegister):
	slot_register = reg
	slot_register.element_quantity_changed.connect(_on_quantity_changed)
	if quantity_label: quantity_label.text = str(slot_register.quantity)
	# set_tooltip_text(reg.element.element_id.capitalize())

func _on_slot_changed(): control_slot_changed.emit()

func _on_quantity_changed(): quantity_label.text = str(slot_register.quantity)
