class_name UIComponent
extends Node

const TIME_SCALE_MULTIPLY : int = 3

signal stage_ended
signal speed_changed(toggled : bool)
signal wave_activity_changed(active : bool)
signal drag_changed(drag : bool)
signal game_paused(mode)

@onready var HUD : Interface = $Interface
@onready var EVENT : Control = $Interface/EventLayer
@onready var EFFECT : CanvasLayer = $ScreenEffectLayer
@onready var PAUSE_LAYER : PauseLayer = $PauseLayer
@onready var TRANSITION : CanvasLayer = $TransitionLayer

var autoplay_turn : bool = false
var speed_toggled : bool = false #? Queryable boolean that says if the engine acceleration was toggled on/off
var pause_locked : bool = false
var pause_state : bool: set = set_pause

var speed_cached : bool = false: #? If speed was activated before, immediately speed up after a turn starts
	set(cache):
		speed_cached = cache

var is_dragging : bool: 
	set(drag):
		is_dragging = drag
		drag_changed.emit(drag)

var wave_is_active : bool = false:
	set(wave_active):
		wave_is_active = wave_active
		wave_activity_changed.emit(wave_is_active)

func _ready() -> void:
	get_viewport().gui_focus_changed.connect(_on_focus_changed)
	UI.EVENT.finish_panel.decison_made.connect(_on_stage_closing_decision_made)

func _on_stage_closing_decision_made(): stage_ended.emit()

func _on_focus_changed(control : Control) -> void: print('UI DEBUG | Focus changed to ' + str(control.get_path()))

func set_pause(state : bool) -> void:
	pause_state = state
	get_tree().paused = state
	game_paused.emit(state)

func toggle_speed(toggle : bool) -> void:
	speed_toggled = toggle
	
	if toggle: Engine.time_scale = TIME_SCALE_MULTIPLY
	else: Engine.time_scale = 1
	
	speed_cached = toggle
	speed_changed.emit(toggle)

func start_stage() -> void:
	UI.HUD.set_visible(true)
	pause_locked = false

func end_stage(win : bool) -> void:
	if speed_toggled: toggle_speed(false)
	UI.EVENT.finish_panel.conclude(win)

func fade(mode) -> void:
	var visibility : bool
	match mode:
		0, 'IN': visibility = false
		1, 'OUT': visibility = true
	TRANSITION.set_visible(true)
	TRANSITION.fade(mode)
	await get_tree().create_timer(TRANSITION.fade_time).timeout
	TRANSITION.set_visible(visibility)

func _on_wave_activity_changed(active: bool) -> void:
	if !autoplay_turn: toggle_speed(false)
	if speed_cached: toggle_speed(true)
