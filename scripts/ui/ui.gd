class_name GameUI
extends CanvasLayer

signal turn_pass_requested

@onready var debug_label = $Screen/InfoBox/DebugLabel
@onready var tile_description_label = $Screen/InfoBox/TileDescriptionLabel
@onready var rune_slots = $Screen/Controls/RuneSlots
@onready var play_button = $Screen/Controls/CornerPanel/PlayButton
@onready var coin_label = $Screen/CoinBox/CoinLabel
@onready var life_label = $Screen/LifePanel/LifeContainer/LifeLabel
@onready var wave_counter = $Screen/LifePanel/WaveCounter

@onready var essence_manager = $"Screen/Controls/Essences Patch/ScrollContainer/EssenceManager"

func _on_play_button_pressed():
	turn_pass_requested.emit()
	# play_button.disabled = true

func update_coins(coins : int): coin_label.set_text('[center][img]res://assets/prototypes/pyrite.png[/img]{0}'.format({0: coins}))

func update_life(life : int): life_label.set_text(str(life))

func turn_update(turn : int, max_turn : int): wave_counter.set_text(TranslationServer.tr('TURN {0}/{1}'.format({0: turn, 1: max_turn})))

func _input(event):
	if Input.is_action_just_pressed('enter'):
		turn_pass_requested.emit()

func _on_screen_mouse_exited():
	pass
