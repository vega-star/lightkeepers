class_name UpgradeSlot extends ControlSlot

signal input_quantity_updated
signal register_updated
signal transition_finished

const MAX_QUANTITY : int = 5

@onready var current_element_sprite: Sprite2D = $CurrentElementSprite
@onready var quantity_bar : TextureProgressBar = $OffsetControl/InputQuantity

var active : bool
var quantity : int: set = _on_quantity_bar_changed

func _ready() -> void:
	slot.slot_changed.connect(_on_slot_changed)
	set_custom_minimum_size(MINIMUM_SIZE)

func _config_slot(new_slot : Slot) -> void:
	slot = new_slot
	slot.slot_changed.connect(_on_slot_changed)

func _config_register(reg : ElementRegister) -> void:
	if !reg: slot_register = null; return
	slot_register = reg
	active = true
	register_updated.emit()
	var new_tint = ElementManager.query_metadata(slot_register.element.element_id, "root_color")
	var element_id : String = slot_register.element.element_id
	
	if new_tint: quantity_bar.set_tint_progress(new_tint)
	if ElementManager.element_textures.has(element_id): current_element_sprite.texture = ElementManager.element_textures[element_id]

func _on_slot_changed() -> void: ## New insertion
	control_slot_changed.emit()
	if slot.active_object:
		if !slot_register: slot_register = ElementManager.query_element(slot.active_object.element.element_id)
		slot._destroy_active_object()
		quantity += 1

func _on_quantity_bar_changed(new_quantity : int) -> void:
	var delta : int = new_quantity - quantity
	# print('Previous quantity: {0}\rNew quantity: {1}\rDelta: {2}'.format({0: quantity, 1: new_quantity, 2: delta}))
	if new_quantity < quantity and active: #? Result delta is negative, which means removal. Will add quantity to register
		if !slot_register: push_error('Resource quantity update called with no register active on ', self.get_path())
		else: slot_register.quantity += abs(delta)
	
	quantity = new_quantity
	quantity_bar.value = int(quantity)
	
	input_quantity_updated.emit()
	if new_quantity == MAX_QUANTITY: pass # lock
	elif new_quantity == 0: _remove_input_configuration()

func _on_gui_input(_event : InputEvent) -> void:
	if Input.is_action_just_pressed("alt"): ## Remove 1 from quantity pool
		if active: quantity -= 1

func _remove_input_configuration() -> void:
	# print('Removing data from input upgrade slot')
	current_element_sprite.set_texture(null)
	slot_register = null
	active = false
	slot.element_register = null
	register_updated.emit()
