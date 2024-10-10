## Slot
# Acts as a placeable input
# Physical slot with 2D properties extending from StaticBody2D
# Has to be that way to detect CollisionShapes and element movement
class_name Slot extends StaticBody2D

signal register_changed
signal slot_object_picked(reg : ElementRegister)
signal slot_changed

const HOVERED_COLOR : Color = Color(1.5, 1.5, 1.5)
const LOCKED_COLOR : Color = Color(1.5, 0.5, 0.5)
const RESTOCK_COOLDOWN : float = 0.3
const DEFAULT_SLOT_SIZE : Vector2 = Vector2(48, 48)
const SHAPE_RADIUS : float = 48

@export_enum('GENERIC:0','ELEMENT:1', 'ESSENCE:2') var slot_type : int = 0
@export var element_register : ElementRegister: set = _set_reg
@export var active_object : DraggableObject: set = _set_object
@export var is_output : bool = false
@export var is_separator : bool = false
@export var slot_locked : bool = false
@export var debug : bool = false

var hovered : bool = false: set = _set_hover

func _ready() -> void: 
	UI.drag_changed.connect(_drag_toggled)

#region Object Controls
func _set_object(new_object : DraggableObject) -> void:
	if is_instance_valid(active_object): active_object.object_picked.disconnect(_remove_object)
	if !new_object: active_object = null; return
	
	active_object = new_object
	active_object.object_picked.connect(_on_object_picked)
	active_object.object_picked.connect(_remove_object)

func _set_reg(new_reg : ElementRegister) -> void:
	if element_register: element_register.element_quantity_changed.disconnect(_on_quantity_changed)
	element_register = new_reg
	register_changed.emit()
	if element_register == null: return
	element_register.element_quantity_changed.connect(_on_quantity_changed)

func _on_quantity_changed(_new_quantity : int): if !active_object: _restock()

func _on_object_picked() -> void: slot_object_picked.emit(element_register) #? Signal relay and carry register

func _restock() -> void: active_object = ElementManager._restock_output(self, element_register)

func request_insert(object : DraggableObject) -> bool:
	var object_type : int = object.element.element_type
	var object_reg : ElementRegister = ElementManager.query_element(object.element.element_id)
	var homogeneous_insert : bool
	
	## INITIAL CHECKS
	if object_reg: if object_reg == element_register: homogeneous_insert = true
	if slot_locked: push_warning('Insert requested by slot is locked: ', self.get_path()); return false
	if slot_type != 0 and object_type != slot_type: printerr('Slot not compatible'); return false
	
	## OUTPUT
	if is_output and homogeneous_insert: #? Inserting/returning to output slot
		if element_register:
			object.volatile = true
			element_register.quantity += 1
			slot_changed.emit()
			return true #? Successful as output
		else: #? Not homogeneous
			if debug: push_warning('Not homogeneous mix between ', self.name, ' + ', object.name)
			slot_changed.emit()
			return false
	elif is_output and !homogeneous_insert: return false #? Cannot insert element into output of a different element
	
	## SEPARATOR
	if is_separator:
		if !homogeneous_insert and element_register:
			printerr(
				'Insert failed because the stored object_reg is not equal to the requested element register | Current reg: ',
				element_register.element.element_id,
				' | Requested reg: ',
				object_reg.element.element_id
			)
			return false
		else:
			active_object = object
			element_register = object_reg
			slot_changed.emit()
			return true #? Successful as input
	
	## INPUT
	if !is_instance_valid(active_object): 
		active_object = object
		element_register = object_reg
		slot_changed.emit()
		return true #? Successful as input
	else: #? Already filled
		slot_changed.emit()
		return false

func _remove_object(destroy : bool = false) -> void:
	active_object = null
	if is_output: element_register.quantity -= 1 #? Object is removed, thus -1 on quantity
	if destroy: active_object._destroy()
	slot_changed.emit()

func _destroy_active_object() -> void: if is_instance_valid(active_object): active_object._destroy()

func _on_visibility_changed() -> void: if is_instance_valid(active_object) and !is_visible_in_tree() and !is_output: active_object._return_to_slot()
#endregion

#region Cosmetic Features
## Set modulate color when hovered
func _set_hover(is_hovering : bool) -> void:
	if is_output: return
	if is_hovering: modulate = HOVERED_COLOR
	else: modulate = Color.WHITE

## Set modulate color if locked, output, or overall blocked based on global drag
func _drag_toggled(drag_status) -> void:
	if drag_status:
		if is_output: set_self_modulate(LOCKED_COLOR) #? Drag active
		else: set_self_modulate(Color.WHITE)  #? Drag inactive
#endregion
