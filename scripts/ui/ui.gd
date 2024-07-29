class_name GameUI
extends CanvasLayer

signal turn_pass_requested

@onready var play_button = $Screen/HUD/PlayButton
@onready var debug_label = $Screen/InfoBox/DebugLabel
@onready var tile_description_label = $Screen/InfoBox/TileDescriptionLabel
@onready var runes = $Screen/Runes

func _on_play_button_pressed():
	turn_pass_requested.emit()
	play_button.disabled = true
