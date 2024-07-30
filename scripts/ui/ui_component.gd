class_name UIComponent
extends Node

signal game_paused(mode)

@onready var EFFECT = $ScreenEffectLayer
@onready var HUD = $HUD
@onready var PAUSE_LAYER = $PauseLayer
@onready var EVENT = $EventLayer

var pause_state : bool: set = set_pause

func set_pause(state : bool):
	pause_state = state
	get_tree().paused = state
	game_paused.emit(state)
