class_name UpgradePanel extends Control

var upgrade_tree : TowerUpgradeTree
var finished : bool: set = _on_finished
var locked : bool: set = _on_locked

@onready var previous_texture : TextureRect = $Container/Panel2/PreviousTexture
@onready var upgrade_button : Button = $Container/UpgradeButton
@onready var cost_label : Label = $Container/UpgradeButton/CostLabel
@onready var progress_meter : TextureProgressBar = $Container/ProgressMeter
@onready var locked_panel : Panel = $LockedPanel
@onready var locked_label : Label = $LockedPanel/LockedLabel

func check_if_available(current_coins : int) -> void:
	if !upgrade_tree: push_error('No upgrade tree detected in ', self.name); return
	if upgrade_tree.tier > upgrade_tree.upgrades.size() - 1: return
	upgrade_button.disabled = current_coins < upgrade_tree.upgrades[upgrade_tree.tier].upgrade_cost

func _on_locked(lock : bool) -> void:
	upgrade_button.set_disabled(lock)
	locked_panel.set_visible(lock)

func _on_finished(finish : bool) -> void:
	locked = true
	locked_label.set_text('ROUTE_FINISHED')
	# locked_label.set_visible(false)
