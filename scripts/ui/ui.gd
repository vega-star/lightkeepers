class_name GameUI
extends CanvasLayer

signal turn_pass_requested

@onready var play_button = $Screen/HUD/PlayButton
@onready var debug_label = $Screen/InfoBox/DebugLabel
@onready var tile_description_label = $Screen/InfoBox/TileDescriptionLabel
@onready var rune_slots = $Screen/HUD/RuneSlots
@onready var coin_label = $Screen/CoinBox/CoinLabel
@onready var life_label = $Screen/LifePanel/LifeContainer/LifeLabel

func _on_play_button_pressed():
	turn_pass_requested.emit()
	play_button.disabled = true

func update_coins(coins : int): coin_label.set_text('[center][img]res://assets/prototypes/pyrite.png[/img]{0}'.format({0: coins}))

func update_life(life : int): life_label.set_text(str(life))
