class_name TowerPanel extends Panel

signal tower_panel_exited
signal tower_panel_loaded
signal tower_sold

const MOVEMENT_PERIOD : float = 0.2

@export var focus_button_group : ButtonGroup

@onready var tower_label : Label = $TowerLabel
@onready var value : Label = $TowerValuePanel/ValueContainer/Value
@onready var focus_container : HBoxContainer = $FocusContainer
@onready var focus_label : Label = $FocusContainer/FocusPanel/FocusLabel
@onready var kill_counter : Label = $TowerLabel/KillCounter
@onready var upgrades_container : VBoxContainer = $Upgrades
@onready var upgrade_slot : UpgradeSlot = $UpgradeSlot

var slots : Array[UpgradePanel]
var current_stage : Stage
var tower : Tower
var upgrade_system : TowerUpgrades

#region Main functions
func _ready() -> void:
	for button in focus_button_group.get_buttons(): button.pressed.connect(func(): _on_focus_button_pressed(button.get_index()))
	for s in upgrades_container.get_child_count():
		var slot = upgrades_container.get_child(s)
		slot.upgrade_button.pressed.connect(_on_upgrade_button_pressed.bind(s))
		slots.append(slot)

## Move in or out of screen
func _move(to_visible : bool) -> void:
	var move_tween : Tween = get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var target_position : Vector2
	if to_visible: target_position = Vector2(0, position.y)
	else: target_position = Vector2(-size.x, position.y)
	move_tween.tween_property(self, "position", target_position, MOVEMENT_PERIOD).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

func _load_stage() -> Stage:
	var stage = get_tree().get_first_node_in_group('stage')
	stage.stage_manager.coins_updated.connect(_on_coin_updated)
	return stage

func load_tower(new_tower : Tower) -> void:
	if !is_instance_valid(current_stage): current_stage = _load_stage()
	
	if new_tower != tower: #? Executes only if the new tower is different from the one actively stored
		if is_instance_valid(tower):
			tower.disconnect('tower_updated', _on_tower_updated)
			tower.disconnect('tower_defeated_enemy', _on_tower_kill_count_updated)
		_move(false)
		tower = new_tower
		upgrade_system = tower.tower_upgrades
		
		upgrade_slot.slot_register = tower.tower_upgrades.tower_element_reg
		upgrade_slot.quantity = tower.tower_upgrades.tower_element_lvl
		
		new_tower.tower_updated.connect(_on_tower_updated)
		new_tower.tower_defeated_enemy.connect(_on_tower_kill_count_updated)
		await get_tree().create_timer(MOVEMENT_PERIOD).timeout
	
	for s in slots.size():
		var slot : UpgradePanel = slots[s]
		slot.upgrade_button.disabled = !_set_upgrade_info(slot, s)
	
	focus_container.set_visible(tower.show_targeting_priorities)
	
	_on_tower_kill_count_updated(tower.tower_kill_count)
	tower_label.set_text(TranslationServer.tr(tower.tower_name.to_upper()))
	focus_label.set_text(tower.TARGET_PRIORITIES.keys()[tower.target_priority])
	value.set_text(str(roundi(tower.tower_value * current_stage.CASHBACK_FACTOR)))
	tower_panel_loaded.emit()
	_move(true)

func _set_upgrade_info( upgrade_panel : UpgradePanel, tree_index : int ) -> bool:
	var is_valid : bool = !(upgrade_system.upgrade_trees_array.is_empty() or tree_index + 1 > upgrade_system.upgrade_trees_array.size())
	upgrade_panel.visible = is_valid
	if !is_valid: return false
	
	var tree : TowerUpgradeTree = upgrade_system.upgrade_trees_array[tree_index]
	upgrade_panel.upgrade_tree = tree
	upgrade_panel.progress_meter.set_value(tree.tier)
	if tree.tier + 1 > tree.upgrades.size(): #? Upgrade tree finished
		upgrade_panel.cost_label.set_text(''); return false
	
	var upgrade : Upgrade = tree.upgrades[tree.tier]
	if upgrade.upgrade_icon: upgrade_panel.upgrade_button.set_texture_normal(upgrade.upgrade_icon)
	# else: panel.upgrade_button.set_texture_normal(DEFAULT_UPGRADE_ICON)
	upgrade_panel.cost_label.set_text(str(upgrade.upgrade_cost))
	upgrade_panel.upgrade_button.set_tooltip_text(upgrade.upgrade_description)
	return true
#endregion

#region Signals
func _on_coin_updated(_previous_coins : int, current_coins : int): for s in slots: if s.visible: s.check_if_available(current_coins)

func _on_tower_updated() -> void: load_tower(tower)

func _on_tower_kill_count_updated(tower_kill_count : int) -> void: kill_counter.set_text(str(tower_kill_count))

func _on_sell_button_pressed() -> void:
	if !is_instance_valid(current_stage): current_stage = _load_stage()
	assert(tower)
	var request = await current_stage.request_removal(tower.tile_position)
	if !request: pass
	else:
		_move(false)
		tower_sold.emit()
		tower_panel_exited.emit()

func _on_exit_button_pressed() -> void:
	_move(false)
	tower_panel_exited.emit()

func _on_focus_button_pressed(button_index : int) -> void:
	var NEW_TARGET_PRIORITY : int
	match button_index:
		0: #! Previous
			if tower.target_priority - 1 < 0: NEW_TARGET_PRIORITY = tower.TARGET_PRIORITIES.size() - 1
			else: NEW_TARGET_PRIORITY = tower.target_priority - 1
		2: #! Next
			if tower.target_priority + 1 > tower.TARGET_PRIORITIES.size() - 1: NEW_TARGET_PRIORITY = 0
			else: NEW_TARGET_PRIORITY = tower.target_priority + 1
		_: return
	tower.target_priority = NEW_TARGET_PRIORITY
	tower.tower_updated.emit()

func _on_upgrade_button_pressed(u_index : int) -> void:
	if u_index > 3 or u_index < 0: push_error('INVALID UPGRADE INDEX ', u_index)
	var request = upgrade_system._request_upgrade(slots[u_index].upgrade_tree)
	if request: tower.tower_updated.emit()
	else: pass

func _on_upgrade_slot_register_updated() -> void:
	if is_instance_valid(tower): tower.tower_upgrades.tower_element_reg = upgrade_slot.slot_register

func _on_upgrade_slot_input_quantity_updated() -> void:
	print('Input quantity updated | Value: ', upgrade_slot.quantity)
	if is_instance_valid(tower): tower.tower_upgrades.tower_element_lvl = upgrade_slot.quantity
#endregion
