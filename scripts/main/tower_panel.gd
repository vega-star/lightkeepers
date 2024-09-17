class_name TowerPanel extends Panel

signal tower_panel_exited
signal tower_panel_loaded
signal tower_sold

const MOVEMENT_PERIOD : float = 0.2

@export var focus_button_group : ButtonGroup
@export var upgrade_button_group : ButtonGroup

@onready var tower_label: Label = $TowerLabel
@onready var slot_1_progress: TextureProgressBar = $Upgrades/Slot1Progress
@onready var slot_2_progress: TextureProgressBar = $Upgrades/Slot2Progress
@onready var slot_3_progress: TextureProgressBar = $Upgrades/Slot3Progress
@onready var slot_1_button: TextureButton = $Upgrades/Slot1Button
@onready var slot_2_button: TextureButton = $Upgrades/Slot2Button
@onready var slot_3_button: TextureButton = $Upgrades/Slot3Button
@onready var value: Label = $TowerValuePanel/Container/Value
@onready var focus_container : HBoxContainer = $FocusContainer
@onready var focus_label: Label = $FocusContainer/FocusPanel/FocusLabel

var stage : Stage
var tower : Tower
var upgrade_system : TowerUpgrades

func _ready() -> void:
	stage = get_tree().get_first_node_in_group('stage')
	for button in focus_button_group.get_buttons(): button.pressed.connect(func(): _on_focus_button_pressed(button.get_index()))
	for button in upgrade_button_group.get_buttons(): button.pressed.connect(func(): _on_upgrade_button_pressed(button.get_index()))

func load_tower(new_tower : Tower) -> void:
	if new_tower != tower: #? Executes only if the new tower is different from the one actively stored
		if is_instance_valid(tower): tower.disconnect('tower_updated', _on_tower_updated)
		_move(false)
		tower = new_tower
		upgrade_system = tower.tower_upgrades
		new_tower.tower_updated.connect(_on_tower_updated)
		await get_tree().create_timer(MOVEMENT_PERIOD).timeout
	
	slot_1_button.disabled = !_set_upgrade_info(slot_1_button, $Upgrades/Slot1Button/UpgradeCost, slot_1_progress, 0)
	slot_2_button.disabled = !_set_upgrade_info(slot_2_button, $Upgrades/Slot2Button/UpgradeCost, slot_2_progress, 1)
	slot_3_button.disabled = !_set_upgrade_info(slot_3_button, $Upgrades/Slot3Button/UpgradeCost, slot_3_progress, 2)
	
	focus_container.set_visible(tower.show_targeting_priorities)
	
	tower_label.set_text(tower.tower_name.to_upper())
	focus_label.set_text(tower.TARGET_PRIORITIES.keys()[tower.target_priority])
	value.set_text(str(roundi(tower.tower_value * stage.CASHBACK_FACTOR)))
	tower_panel_loaded.emit()
	_move(true)

func _set_upgrade_info(
		button : TextureButton,
		cost_label : Label,
		progress_bar : TextureProgressBar,
		tree_index : int,
		offset : int = 1
	) -> bool:
	if upgrade_system.upgrade_trees_array.is_empty() or tree_index + 1 > upgrade_system.upgrade_trees_array.size(): return false
	var tree : TowerUpgradeTree = upgrade_system.upgrade_trees_array[tree_index]
	progress_bar.set_value(tree.tier)
	
	if tree.tier + offset > tree.upgrades.size(): return false
	var upgrade : Upgrade = tree.upgrades[tree.tier]
	
	# button.set_texture_normal(upgrade.upgrade_icon)
	cost_label.set_text(str(upgrade.upgrade_cost))
	button.set_tooltip_text(upgrade.upgrade_description)
	return true

func _on_tower_updated(): load_tower(tower)

func _on_sell_button_pressed() -> void:
	assert(tower)
	var request = await stage.request_removal(tower.tile_position)
	if !request: pass
	else:
		_move(false)
		tower_sold.emit()
		tower_panel_exited.emit()

func _on_exit_button_pressed() -> void:
	_move(false)
	tower_panel_exited.emit()

func _move(to_visible : bool):
	var move_tween : Tween = get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var target_position : Vector2
	if to_visible: target_position = Vector2(0, position.y)
	else: target_position = Vector2(-size.x, position.y)
	move_tween.tween_property(self, "position", target_position, MOVEMENT_PERIOD).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

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

func _on_upgrade_button_pressed(button_index : int) -> void:
	var TREE_INDEX : int
	match button_index:
		2: TREE_INDEX = 0 #! Upgrade Tree 1
		5: TREE_INDEX = 1 #! Upgrade Tree 2
		8: TREE_INDEX = 2 #! Upgrade Tree 3
		_: return
	var request = upgrade_system._request_upgrade(upgrade_system.upgrade_trees_array[TREE_INDEX])
	if request: tower.tower_updated.emit()
	else: pass
