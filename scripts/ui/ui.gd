class_name GameUI
extends CanvasLayer

signal turn_pass_requested

@onready var debug_label = $Screen/InfoBox/DebugLabel
@onready var tile_description_label = $Screen/InfoBox/TileDescriptionLabel
@onready var rune_slots = $Screen/Controls/RuneSlots
@onready var play_button = $Screen/Controls/CornerPanel/PlayButton
@onready var coin_label = $Screen/CoinBox/CoinLabel
@onready var life_label = $Screen/LifePanel/LifeContainer/LifeLabel

func _on_play_button_pressed():
	turn_pass_requested.emit()
	play_button.disabled = true

func update_coins(coins : int): coin_label.set_text('[center][img]res://assets/prototypes/pyrite.png[/img]{0}'.format({0: coins}))

func update_life(life : int): life_label.set_text(str(life))

func _on_screen_mouse_exited():
	print('mouse exited the ui')
