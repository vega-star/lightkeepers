class_name UIComponent
extends Node

signal drag_changed(drag : bool)
signal game_paused(mode)

@onready var EFFECT = $ScreenEffectLayer
@onready var HUD = $HUD
@onready var PAUSE_LAYER = $PauseLayer
@onready var EVENT = $EventLayer
@onready var TRANSITION = $TransitionLayer

@export var debug : bool

var is_dragging : bool: 
	set(drag):
		is_dragging = drag
		drag_changed.emit(drag)

var pause_state : bool: set = set_pause

func _ready():
	if debug: get_viewport().gui_focus_changed.connect(_on_focus_changed)

func _on_focus_changed(control : Control) -> void:
	if control != null:
		print(control.name)

func set_pause(state : bool):
	pause_state = state
	get_tree().paused = state
	game_paused.emit(state)

func start_stage():
	UI.HUD.set_visible(true)

func fade(mode):
	var visibility : bool
	match mode:
		0, 'IN': visibility = false
		1, 'OUT': visibility = true
	TRANSITION.set_visible(true)
	TRANSITION.fade(mode)
	await get_tree().create_timer(TRANSITION.fade_time).timeout
	TRANSITION.set_visible(visibility)
