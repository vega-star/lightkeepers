class_name UIComponent
extends Node

const TIME_SCALE_MULTIPLY : int = 3

signal speed_changed(toggled : bool)
signal wave_activity_changed(active : bool)
signal drag_changed(drag : bool)
signal game_paused(mode)

@onready var interface : Interface = $Interface
@onready var event_layer : Control = $Interface/EventLayer
@onready var screen_effect_layer : CanvasLayer = $ScreenEffectLayer
@onready var pause_layer : PauseLayer = $PauseLayer
@onready var transition_layer : CanvasLayer = $TransitionLayer
@onready var world_env : WorldEnvironment = $WorldEnvironment

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

func _on_focus_changed(control : Control) -> void: print('UI DEBUG | Focus changed to ' + str(control.get_path()))

func set_pause(state : bool) -> void:
	pause_state = state
	get_tree().paused = state
	game_paused.emit(state)

func toggle_speed(toggle : bool) -> void:
	speed_toggled = toggle
	if toggle: Engine.time_scale = TIME_SCALE_MULTIPLY
	else: Engine.time_scale = 1
	speed_changed.emit(toggle)

func fade(mode) -> void:
	var visibility : bool
	match mode:
		0, 'IN': visibility = false
		1, 'OUT': visibility = true
	transition_layer.set_visible(true)
	transition_layer.fade(mode)
	await get_tree().create_timer(transition_layer.fade_time).timeout
	transition_layer.set_visible(visibility)

func _on_wave_activity_changed(active: bool) -> void:
	if active:
		if speed_cached: toggle_speed(true)
	else:
		if !autoplay_turn: toggle_speed(false)

func _on_turn_pass_requested() -> void:
	if UI.wave_is_active: #? Makes the game go faster with the same action that passes the turn
		UI.toggle_speed(!UI.speed_toggled)
		speed_cached = !speed_cached
