class_name UIComponent
extends Node

signal game_paused(mode)

@onready var hud = $GameUI

var pause_state : bool: set = set_pause

func set_pause(state : bool):
	pause_state = state
	get_tree().paused = state
	game_paused.emit(state)
