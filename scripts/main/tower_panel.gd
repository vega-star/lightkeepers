class_name TowerPanel extends Panel

signal tower_panel_exited
signal tower_panel_loaded
signal tower_sold

const MOVEMENT_PERIOD : float = 0.2

@export var focus_button_group : ButtonGroup

@onready var tower_label: Label = $TowerLabel
@onready var slot_1_progress: TextureProgressBar = $Upgrades/Slot1Progress
@onready var slot_2_progress: TextureProgressBar = $Upgrades/Slot2Progress
@onready var slot_3_progress: TextureProgressBar = $Upgrades/Slot3Progress
@onready var slot_1: Slot = $Upgrades/Slot1/Slot
@onready var slot_2: Slot = $Upgrades/Slot2/Slot
@onready var slot_3: Slot = $Upgrades/Slot3/Slot
@onready var value: Label = $TowerValuePanel/Container/Value
@onready var focus_container : HBoxContainer = $FocusContainer
@onready var focus_label: Label = $FocusContainer/FocusPanel/FocusLabel

var stage : Stage
var tower : Tower

func _ready() -> void:
	stage = get_tree().get_first_node_in_group('stage')
	for button in focus_button_group.get_buttons():
		button.pressed.connect(func(): _on_focus_button_pressed(button.get_index()))

func load_tower(new_tower : Tower) -> void:
	if new_tower != tower: #? Executes only if the new tower is different from the one actively stored
		if is_instance_valid(tower): tower.disconnect('tower_updated', _on_tower_updated)
		_move(false)
		tower = new_tower
		new_tower.tower_updated.connect(_on_tower_updated)
		await get_tree().create_timer(MOVEMENT_PERIOD).timeout
	
	focus_container.set_visible(tower.show_targeting_priorities)
	
	tower_label.set_text(tower.tower_name.to_upper())
	focus_label.set_text(tower.TARGET_PRIORITIES.keys()[tower.target_priority])
	value.set_text(str(roundi(tower.tower_value * stage.CASHBACK_FACTOR)))
	tower_panel_loaded.emit()
	_move(true)

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

func _on_focus_button_pressed(button_index : int):
	var INDEX = button_index - 1
	var NEW_TARGET_PRIORITY : int
	match INDEX:
		-1: #! Previous
			if tower.target_priority - 1 < 0: NEW_TARGET_PRIORITY = tower.TARGET_PRIORITIES.size() - 1
			else: NEW_TARGET_PRIORITY = tower.target_priority - 1
		1: #! Next
			if tower.target_priority + 1 > tower.TARGET_PRIORITIES.size() - 1: NEW_TARGET_PRIORITY = 0
			else: NEW_TARGET_PRIORITY = tower.target_priority + 1
		_: return
	tower.target_priority = NEW_TARGET_PRIORITY
	tower.tower_updated.emit()
