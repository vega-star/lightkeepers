class_name UpgradeSlot extends ControlSlot

signal input_quantity_updated
signal register_updated
signal transition_finished

const MAX_QUANTITY : int = 5

@export var debug : bool = false

@onready var current_element_sprite : Sprite2D = $CurrentElementSprite
@onready var quantity_bar : TextureProgressBar = $OffsetControl/InputQuantity

var tower : Tower: set = _config_tower
var upgrade_system : TowerUpgrades
var active : bool
var quantity : int: set = _on_quantity_bar_changed
var new_tower_lock : bool #? Prevents updating registers and values of previous towers

#region Main functions
func _ready() -> void:
	slot.slot_changed.connect(_on_slot_changed)
	set_custom_minimum_size(MINIMUM_SIZE)

func _config_tower(new_tower : Tower) -> void:
	if is_instance_valid(tower): if tower != new_tower: new_tower_lock = true
	if debug: print('Tower updated to ', new_tower.tower_name)
	tower = new_tower
	upgrade_system = new_tower.tower_upgrades
	slot_register = new_tower.tower_upgrades.tower_element_reg
	quantity = new_tower.tower_upgrades.tower_element_lvl

func _config_slot(new_slot : Slot) -> void:
	slot = new_slot
	slot.slot_changed.connect(_on_slot_changed)

func _config_register(reg : ElementRegister) -> void:
	if !reg: slot_register = null; return
	slot_register = reg
	slot.element_register = reg
	active = true
	register_updated.emit()
	if debug: print('New register attached to tower upgrade slot: ', slot_register.element.element_id)
	
	var new_tint = ElementManager.query_metadata(slot_register.element.element_id, "root_color")
	var element_id : String = slot_register.element.element_id
	
	if new_tint: quantity_bar.set_tint_progress(new_tint)
	if ElementManager.element_textures.has(element_id): current_element_sprite.texture = ElementManager.element_textures[element_id]

func _remove_input_configuration() -> void:
	if debug: print('Removing data from input upgrade slot')
	current_element_sprite.set_texture(null)
	slot_register = null
	active = false
	slot.element_register = null
	register_updated.emit()
	return
#endregion

#region Signals
func _on_gui_input(_event : InputEvent) -> void:
	if Input.is_action_just_pressed("alt"):
		if active:
			new_tower_lock = false
			quantity -= 1 #? Remove 1 from quantity pool, returning it

func _on_register_updated() -> void:
	if is_instance_valid(tower): tower.tower_upgrades.tower_element_reg = slot_register

func _on_input_quantity_updated() -> void:
	if is_instance_valid(tower): tower.tower_upgrades.tower_element_lvl = quantity

func _on_slot_changed() -> void: ## New insertion
	control_slot_changed.emit()
	if slot.active_object:
		if !slot_register: slot_register = ElementManager.query_element(slot.active_object.element.element_id)
		slot._destroy_active_object()
		quantity += 1

func _on_quantity_bar_changed(new_quantity : int) -> void:
	var delta : int = new_quantity - quantity
	if debug: print('QUANTITY BAR CHANGED\r| Previous quantity: {0}\r| New quantity: {1}\r| Delta: {2}'.format({0: quantity, 1: new_quantity, 2: delta}))
	if new_quantity < quantity and active: #? Result delta is negative, which means removal. Will add quantity to register
		if !slot_register: push_error('Resource quantity update called with no register active on ', self.get_path())
		elif new_tower_lock: new_tower_lock = false
		else:
			if debug: print('Returning ', abs(delta), ' to ', slot_register.element.element_id)
			slot_register.quantity += abs(delta)
	
	quantity = new_quantity
	quantity_bar.value = int(quantity)
	
	input_quantity_updated.emit()
	if new_quantity == MAX_QUANTITY: pass # lock
	elif new_quantity == 0: _remove_input_configuration()
#endregion
