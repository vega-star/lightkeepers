class_name TowerDashboard extends Panel

signal tower_panel_exited
signal tower_panel_loaded
signal tower_sold
signal tower_moved(to_visible : bool)

@export var focus_button_group : ButtonGroup

const MOVEMENT_PERIOD : float = 0.25
const OFFSET_ADD : int = 80

@onready var name_label : Label = $NameLabel
@onready var value : Label = $TowerValuePanel/ValueContainer/Value
@onready var focus_container : HBoxContainer = $FocusContainer
@onready var focus_label : Label = $FocusContainer/FocusPanel/FocusLabel
@onready var kill_counter : Label = $NameLabel/KillCounter
@onready var upgrade_panel_manager : UpgradePanelManager = $UpgradePanelManager
@onready var sell_button : Button = $TowerValuePanel/SellButton

var current_stage : Stage #? Needed reference to consume/update coins
var slots : Array[UpgradePanel]
var target_tower : Tower
var stage_agent : StageAgent
var target_tower_upgrades : TowerUpgrades

#region Main functions
func _ready() -> void:
	for button in focus_button_group.get_buttons(): button.pressed.connect(func(): _on_focus_button_pressed(button.get_index()))
	for s in upgrade_panel_manager.get_children(): slots.append(s)

func _load_stage() -> Stage:
	var stage = StageManager.active_stage
	assert(StageManager.on_stage)
	assert(stage)
	stage_agent = stage.stage_agent
	return stage

## Move in or out of screen
func _move(to_visible : bool) -> void:
	var move_tween : Tween = get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var target_position : Vector2
	if to_visible: target_position = Vector2(0, position.y)
	else: target_position = Vector2(-size.x - OFFSET_ADD, position.y)
	move_tween.tween_property(self, "position", target_position, MOVEMENT_PERIOD).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_IN_OUT)
	await move_tween.finished
	tower_moved.emit(to_visible)
	return
#endregion

#region Tower Upgrades
func load_tower(selected_tower : Tower) -> void:
	if !is_instance_valid(current_stage): current_stage = _load_stage()
	if selected_tower != target_tower: #? Executes only if the new target_tower is different from the one actively stored
		if is_instance_valid(target_tower): #? Disconnect previous tower
			target_tower.disconnect('tower_updated', _on_tower_updated)
			target_tower.disconnect('tower_defeated_enemy', _on_tower_kill_count_updated)
		await _move(false) #? Animate outisde screen for smooth replacement
		target_tower = selected_tower
		target_tower_upgrades = target_tower.tower_upgrades
		target_tower.tower_updated.connect(_on_tower_updated)
		target_tower.tower_defeated_enemy.connect(_on_tower_kill_count_updated)
	
	for s in slots.size():
		var slot : UpgradePanel = slots[s]
		slot.locked = !_set_upgrade_info(slot, s)
	
	focus_container.set_visible(target_tower.show_targeting_priorities)
	_on_tower_kill_count_updated(target_tower.tower_kill_count)
	name_label.set_text(TranslationServer.tr(target_tower.tower_name.to_upper()))
	focus_label.set_text(TranslationServer.tr(target_tower.TARGET_PRIORITIES.keys()[target_tower.target_priority]).capitalize())
	value.set_text(str(roundi(target_tower.tower_value * current_stage.CASHBACK_FACTOR)))
	tower_panel_loaded.emit()
	_move(true) #? Show loaded and updated target_tower data

func _set_upgrade_info( upgrade_panel : UpgradePanel, tree_index : int ) -> bool:
	var is_valid : bool = !(target_tower_upgrades.upgrade_trees_array.is_empty() or tree_index + 1 > target_tower_upgrades.upgrade_trees_array.size())
	upgrade_panel.locked = !is_valid
	if !is_valid: return false
	
	var tree : TowerUpgradeTree = target_tower_upgrades.upgrade_trees_array[tree_index]
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

# func _check_limits(source_tree : TowerUpgradeTree, target_panel : UpgradePanel) -> bool: pass
#endregion

#region Signals
func _on_tower_updated() -> void: load_tower(target_tower)

func _on_tower_kill_count_updated(tower_kill_count : int) -> void: kill_counter.set_text(str(tower_kill_count))

func _on_focus_button_pressed(button_index : int) -> void:
	var NEW_TARGET_PRIORITY : int
	match button_index:
		0: #! Previous
			if target_tower.target_priority - 1 < 0: NEW_TARGET_PRIORITY = target_tower.TARGET_PRIORITIES.size() - 1
			else: NEW_TARGET_PRIORITY = target_tower.target_priority - 1
		2: #! Next
			if target_tower.target_priority + 1 > target_tower.TARGET_PRIORITIES.size() - 1: NEW_TARGET_PRIORITY = 0
			else: NEW_TARGET_PRIORITY = target_tower.target_priority + 1
		_: return
	target_tower.target_priority = NEW_TARGET_PRIORITY
	target_tower.tower_updated.emit()

func _on_sell_button_pressed() -> void:
	if !is_instance_valid(current_stage): current_stage = _load_stage()
	assert(target_tower)
	var request = await current_stage.request_removal(target_tower.tile_position)
	if !request: pass
	else:
		await _move(false)
		tower_sold.emit()
		tower_panel_exited.emit()
	sell_button.release_focus()

func _on_exit_button_pressed() -> void:
	await _move(false)
	tower_panel_exited.emit()

func _on_move_button_pressed() -> void: #TODO
	pass # Replace with function body.
#endregion
