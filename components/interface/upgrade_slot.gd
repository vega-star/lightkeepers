extends ControlSlot

const MAX_QUANTITY : int = 5

@onready var current_element_sprite: Sprite2D = $CurrentElementSprite
@onready var input_quantity : TextureProgressBar = $OffsetControl/InputQuantity

var active : bool
var quantity : int: set = _on_input_quantity_changed

func _ready() -> void:
	slot.slot_changed.connect(_on_slot_changed)
	set_custom_minimum_size(MINIMUM_SIZE)

func _config_slot(new_slot : Slot) -> void:
	slot = new_slot
	slot.slot_changed.connect(_on_slot_changed)

func _config_register(reg : ElementRegister) -> void:
	if !reg: return
	slot_register = reg
	active = true
	var new_tint = ElementManager.query_metadata(slot_register.element.element_id, "root_color")
	if new_tint: input_quantity.set_tint_progress(new_tint)
	current_element_sprite.texture = ElementManager.element_textures[slot_register.element.element_id]

func _on_slot_changed() -> void:
	control_slot_changed.emit()
	if slot.active_object:
		slot_register = ElementManager.query_element(slot.active_object.element.element_id)
		slot._destroy_active_object()
		quantity += 1

func _on_input_quantity_changed(new_quantity : int) -> void:
	if new_quantity == MAX_QUANTITY: pass # lock
	elif new_quantity == 0: _remove_input_configuration()
	quantity = new_quantity
	input_quantity.value = int(quantity)

func _on_gui_input(_event : InputEvent) -> void:
	if Input.is_action_just_pressed("alt"):
		if active:
			quantity -= 1
			slot_register.quantity += 1

func _remove_input_configuration() -> void:
	current_element_sprite.set_texture(null)
	slot_register = null
	active = false
	slot.element_register = null
