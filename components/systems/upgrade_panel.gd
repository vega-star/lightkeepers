class_name UpgradePanel extends Control

var upgrade_tree : TowerUpgradeTree

@onready var previous_texture : TextureRect = $PanelContainer/Panel2/PreviousTexture
@onready var upgrade_button : TextureButton = $PanelContainer/UpgradeButton
@onready var cost_label : Label = $PanelContainer/UpgradeButton/CostLabel
@onready var progress_meter : TextureProgressBar = $PanelContainer/ProgressMeter

func check_if_available(current_coins : int) -> void:
	if upgrade_tree.tier > upgrade_tree.upgrades.size() - 1: return
	upgrade_button.disabled = current_coins < upgrade_tree.upgrades[upgrade_tree.tier].upgrade_cost
