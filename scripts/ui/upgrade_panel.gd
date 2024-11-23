class_name UpgradePanel extends Control

@onready var tower_dashboard : TowerDashboard = $"../.."
@onready var previous_upgrade : Control = $Container/InfoPanel/PreviousUpgrade
@onready var previous_texture : TextureRect = $Container/InfoPanel/PreviousUpgrade/PreviousTexture
@onready var upgrade_button : Button = $Container/UpgradeButton
@onready var upgrade_title : Label = $Container/UpgradeButton/UpgradeTitle
@onready var previous_upgrade_title: Label = $Container/InfoPanel/PreviousUpgrade/PreviousUpgradeTitle
@onready var progress_meter : TextureProgressBar = $ProgressMeter
@onready var locked_panel : Panel = $LockedPanel
@onready var locked_label : Label = $LockedPanel/LockedLabel
@onready var cost_label : Label = $Container/UpgradeButton/CostLabel
@onready var not_owned_label : Label = $Container/InfoPanel/NotOwnedLabel

var stage_agent : StageAgent
var upgrade_tree : TowerUpgradeTree: set = _load_tower_upgrade_tree
var finished : bool: set = _on_finished
var locked : bool: set = _on_locked
var upgrade_cost : int

func _ready() -> void: StageManager.stage_started.connect(_load_stage_agent)

func _load_tower_upgrade_tree(new_upgrade_tree : TowerUpgradeTree) -> void: ## Runs everytime a new UpgradeTree is defined to this panel
	upgrade_tree = new_upgrade_tree
	_update_cost()
	check_budget()
	upgrade_title.set_visible(!locked)
	not_owned_label.set_visible(true)
	previous_upgrade.set_visible(false)
	
	if upgrade_tree.tier > 0:
		previous_upgrade_title.set_text(TranslationServer.tr(upgrade_tree.upgrades[upgrade_tree.tier - 1].upgrade_title))
		previous_upgrade.set_visible(true)
		not_owned_label.set_visible(false)
	
	if upgrade_tree.tier <= upgrade_tree.upgrades.size() - 1:
		upgrade_title.set_text(TranslationServer.tr(upgrade_tree.upgrades[upgrade_tree.tier].upgrade_title))

func _load_stage_agent() -> void:
	stage_agent = StageManager.active_stage_agent
	stage_agent.coins_updated.connect(_on_coin_updated)

func check_budget() -> bool:
	if !upgrade_tree: return false
	var on_budget : bool = (stage_agent.coins > upgrade_cost)
	upgrade_button.set_disabled(!on_budget)
	return on_budget

func _update_cost() -> void:
	if upgrade_tree.tier > upgrade_tree.upgrades.size() - 1: locked = true; return
	upgrade_cost = upgrade_tree.upgrades[upgrade_tree.tier].upgrade_cost

func _on_coin_updated(_previous_coins : int, _current_coins : int) -> void: check_budget()

func _on_finished(finish : bool) -> void:
	locked = true
	locked_label.set_text('ROUTE_FINISHED')
	upgrade_title.set_visible(false)

func _on_locked(lock : bool) -> void: locked_panel.set_visible(lock)

func _on_upgrade_button_pressed() -> void:
	if !check_budget(): print("Not enough coins!"); return
	var request = tower_dashboard.target_tower_upgrades._request_upgrade(upgrade_tree)
	if request: tower_dashboard.target_tower.tower_updated.emit()
	else: printerr("Upgrade request failed")
	_update_cost()
