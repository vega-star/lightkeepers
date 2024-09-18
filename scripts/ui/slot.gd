## Slot
# Acts as a placeable input
# Physical slot with 2D properties extending from StaticBody2D
# Has to be that way to detect CollisionShapes and element movement
class_name Slot extends StaticBody2D

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
@export var slot_locked : bool = false

var hovered : bool = false: set = _set_hover

func _ready() -> void: UI.drag_changed.connect(_drag_toggled)

#region Object Controls
func _set_object(new_object : DraggableObject) -> void:
	if is_instance_valid(active_object): active_object.object_picked.disconnect(_remove_object)
	
	if !new_object: active_object = null; return
	
	active_object = new_object
	active_object.object_picked.connect(_remove_object)

func _set_reg(new_reg : ElementRegister) -> void:
	# if element_register: pass
	element_register = new_reg
	if !element_register: return

func _restock() -> void: active_object = ElementManager._restock_output(self, element_register)

func request_insert(object : DraggableObject) -> bool:
	var object_type : int = object.element.element_type
	var object_reg : ElementRegister = ElementManager.query_element(object.element.element_id)
	var homogeneous_insert : bool
	
	## INITIAL CHECKS
	if object_reg: if object_reg == element_register: homogeneous_insert = true
	if slot_locked: return false
	if slot_type != 0 and object_type != slot_type:
		printerr('Slot not compatible')
		return false
	
	## OUTPUT
	if is_output and homogeneous_insert: #? Inserting/returning to output slot
		if element_register:
			object.volatile = true
			element_register.quantity += 1
			slot_changed.emit()
			return true #? Successful as output
		else:
			slot_changed.emit()
			return false
	elif is_output and !homogeneous_insert: return false #? Cannot insert element into output of a different element
	
	## INPUT
	if !is_instance_valid(active_object): 
		active_object = object
		slot_changed.emit()
		return true #? Successful as input
	else: #? Already filled
		slot_changed.emit()
		return false
		
		#if is_instance_valid(active_object) and homogeneous_insert: #? Tried filling object with the same object
		#	object.volatile = true
		#	object_reg.quantity += 1
		#	slot_changed.emit()
		#	return true #? Sucessful as input
		#else: #? Failed because slot is filled with a different kind of element, and for some reason cannot replace it
		#	push_warning('Slot refusing {0} insertion due to being already full with {1}'.format({0:object.name,1:active_object.name}))
		#return false

func _remove_object(destroy : bool = false) -> void:
	slot_changed.emit()
	if is_instance_valid(active_object):
		active_object.object_picked.disconnect(_remove_object)
		active_object = null
	if destroy: active_object._destroy()
	if is_output: _restock()

func _destroy_active_object() -> void: if active_object: active_object._destroy()

func _on_visibility_changed() -> void: if active_object and !is_visible_in_tree() and !is_output: active_object._return_to_slot()
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
		if is_output: set_modulate(LOCKED_COLOR) #? Drag active
		else: set_modulate(Color.WHITE)  #? Drag inactive
#endregion
