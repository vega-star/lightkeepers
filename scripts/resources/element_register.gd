## ElementRegister
# Stores information about an specific element in runtime such as quantity, node paths on UI, etc.
# Used to interact with elements without actually modifying the element itself
class_name ElementRegister extends Resource

signal element_quantity_changed

@export var element : Element
@export var control_slot : NodePath
@export var slot : NodePath
@export var quantity : int: set = set_quantity

var debug : bool = true

func set_quantity(new_quantity : int):
	quantity = new_quantity
	element_quantity_changed.emit()
	if debug: print(element.element_id, ' | Quantity updated: ', quantity)
