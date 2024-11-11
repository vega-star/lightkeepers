class_name PupilPanel extends Panel

signal pupil_panel_exited
signal pupil_panel_loaded
signal pupil_sold
signal pupil_moved(to_visible : bool)

const LIMIT_RULES : Array[int] = [5, 2]
const LIMIT_MAP : Array[bool] = [
	false, #? First tree above threshold
	false, #? Second tree above threshold
	false #? Primary tree locked as above second threshold + 1
]
var stored_limit : Array[bool] = LIMIT_MAP.duplicate() #? Duplicated to be writable. Constants cannot be edited!

const MOVEMENT_PERIOD : float = 0.15

@export var focus_button_group : ButtonGroup

@onready var name_label : Label = $NameLabel
@onready var value : Label = $PupilValuePanel/ValueContainer/Value
@onready var focus_container : HBoxContainer = $FocusContainer
@onready var focus_label : Label = $FocusContainer/FocusPanel/FocusLabel
@onready var kill_counter : Label = $PupilLabel/KillCounter
@onready var upgrades_container : VBoxContainer = $Upgrades
@onready var sell_button : Button = $PupilValuePanel/ValueContainer/SellButton

var current_stage : Stage #? Needed reference to consume/update coins
var slots : Array[UpgradePanel]
var pupil : Pupil
var upgrade_system : PupilUpgrades

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
	move_tween.tween_property(self, "position", target_position, MOVEMENT_PERIOD).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_IN_OUT)
	await move_tween.finished
	pupil_moved.emit(to_visible)
	return

func _load_stage() -> Stage:
	var stage = get_tree().get_first_node_in_group('stage')
	assert(stage)
	stage.stage_agent.coins_updated.connect(_on_coin_updated)
	return stage
#endregion

#region Pupil Upgrades
func load_pupil(selected_pupil : Pupil) -> void:
	if !is_instance_valid(current_stage): current_stage = _load_stage()
	
	if selected_pupil != pupil: #? Executes only if the new pupil is different from the one actively stored
		if is_instance_valid(pupil):
			stored_limit = LIMIT_MAP.duplicate()
			pupil.disconnect('pupil_updated', _on_pupil_updated)
			pupil.disconnect('pupil_defeated_enemy', _on_pupil_kill_count_updated)
		await _move(false) #? Animate outisde screen for smooth replacement
		pupil = selected_pupil
		upgrade_system = pupil.pupil_upgrades
		pupil.pupil_updated.connect(_on_pupil_updated)
		pupil.pupil_defeated_enemy.connect(_on_pupil_kill_count_updated)
	
	for s in slots.size():
		var slot : UpgradePanel = slots[s]
		slot.locked = !_set_upgrade_info(slot, s)
	
	focus_container.set_visible(pupil.show_targeting_priorities)
	_on_pupil_kill_count_updated(pupil.pupil_kill_count)
	name_label.set_text(TranslationServer.tr(pupil.pupil_name.to_upper()))
	focus_label.set_text(pupil.TARGET_PRIORITIES.keys()[pupil.target_priority])
	value.set_text(str(roundi(pupil.pupil_value * current_stage.CASHBACK_FACTOR)))
	pupil_panel_loaded.emit()
	_move(true) #? Show loaded and updated pupil data

func _set_upgrade_info( upgrade_panel : UpgradePanel, tree_index : int ) -> bool:
	var is_valid : bool = !(upgrade_system.upgrade_trees_array.is_empty() or tree_index + 1 > upgrade_system.upgrade_trees_array.size())
	upgrade_panel.locked = !is_valid
	if !is_valid: return false
	
	var tree : PupilUpgradeTree = upgrade_system.upgrade_trees_array[tree_index]
	if !tree: return false
	
	upgrade_panel.upgrade_tree = tree
	upgrade_panel.progress_meter.set_value(tree.tier)
	if tree.tier + 1 > tree.upgrades.size(): #? Upgrade tree finished
		upgrade_panel.finished = true; return false
	
	var upgrade : Upgrade = tree.upgrades[tree.tier]
	if upgrade.upgrade_icon: upgrade_panel.upgrade_button.set_texture_normal(upgrade.upgrade_icon)
	# else: panel.upgrade_button.set_texture_normal(DEFAULT_UPGRADE_ICON)
	upgrade_panel.cost_label.set_text(str(upgrade.upgrade_cost))
	upgrade_panel.upgrade_button.set_tooltip_text(upgrade.upgrade_description)
	return true

# func _check_limits(source_tree : PupilUpgradeTree, target_panel : UpgradePanel) -> bool: pass
#endregion

#region Signals
func _on_coin_updated(_previous_coins : int, current_coins : int): for s in slots: if !s.locked: s.check_if_available(current_coins)

func _on_pupil_updated() -> void: load_pupil(pupil)

func _on_pupil_kill_count_updated(pupil_kill_count : int) -> void: kill_counter.set_text(str(pupil_kill_count))

func _on_sell_button_pressed() -> void:
	if !is_instance_valid(current_stage): current_stage = _load_stage()
	assert(pupil)
	var request = await current_stage.request_removal(pupil.tile_position)
	if !request: pass
	else:
		await _move(false)
		pupil_sold.emit()
		pupil_panel_exited.emit()
	sell_button.release_focus()

func _on_exit_button_pressed() -> void:
	await _move(false)
	pupil_panel_exited.emit()

func _on_focus_button_pressed(button_index : int) -> void:
	var NEW_TARGET_PRIORITY : int
	match button_index:
		0: #! Previous
			if pupil.target_priority - 1 < 0: NEW_TARGET_PRIORITY = pupil.TARGET_PRIORITIES.size() - 1
			else: NEW_TARGET_PRIORITY = pupil.target_priority - 1
		2: #! Next
			if pupil.target_priority + 1 > pupil.TARGET_PRIORITIES.size() - 1: NEW_TARGET_PRIORITY = 0
			else: NEW_TARGET_PRIORITY = pupil.target_priority + 1
		_: return
	pupil.target_priority = NEW_TARGET_PRIORITY
	pupil.pupil_updated.emit()

func _on_upgrade_button_pressed(u_index : int) -> void:
	if u_index > 3 or u_index < 0: push_error('INVALID UPGRADE INDEX ', u_index)
	var request = upgrade_system._request_upgrade(slots[u_index].upgrade_tree)
	if request: pupil.pupil_updated.emit()
	else: pass
#endregion