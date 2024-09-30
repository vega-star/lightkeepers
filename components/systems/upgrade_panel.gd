class_name UpgradePanel extends Control

@onready var previous_texture : TextureRect = $PanelContainer/Panel2/PreviousTexture
@onready var upgrade_button : TextureButton = $PanelContainer/UpgradeButton
@onready var cost_label : Label = $PanelContainer/UpgradeButton/CostLabel
@onready var progress_meter : TextureProgressBar = $PanelContainer/ProgressMeter
