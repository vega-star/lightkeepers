class_name UIComponent
extends Node

signal drag_changed(drag : bool)
signal game_paused(mode)

@onready var HUD : Interface = $Interface
@onready var EVENT : Control = $Interface/EventLayer
@onready var EFFECT : CanvasLayer = $ScreenEffectLayer
@onready var PAUSE_LAYER : PauseLayer = $PauseLayer
@onready var TRANSITION : CanvasLayer = $TransitionLayer

@export var debug : bool

var pause_locked : bool = false
var pause_state : bool: set = set_pause
var is_dragging : bool: 
	set(drag):
		is_dragging = drag
		drag_changed.emit(drag)

func _ready() -> void:
	if debug: get_viewport().gui_focus_changed.connect(_on_focus_changed)

func _on_focus_changed(control : Control) -> void:
	print('UI DEBUG | Focus changed to ' + control.name)

func set_pause(state : bool) -> void:
	pause_state = state
	get_tree().paused = state
	game_paused.emit(state)

func start_stage() -> void:
	UI.HUD.set_visible(true)
	pause_locked = false

func fade(mode) -> void:
	var visibility : bool
	match mode:
		0, 'IN': visibility = false
		1, 'OUT': visibility = true
	TRANSITION.set_visible(true)
	TRANSITION.fade(mode)
	await get_tree().create_timer(TRANSITION.fade_time).timeout
	TRANSITION.set_visible(visibility)
