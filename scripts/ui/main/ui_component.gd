class_name UIComponent
extends Node

const TIME_SCALE_MULTIPLY : int = 3

signal autoplay_changed(autoplay : bool)
signal speed_changed(toggled : bool)
signal wave_activity_changed(active : bool)
signal drag_changed(drag : bool)
signal game_paused(mode)
signal mouse_on_ui_changed(present : bool)

@onready var interface : Interface = $Interface
@onready var event_layer : Control = $Interface/EventLayer
@onready var screen_effect_layer : CanvasLayer = $EffectLayer
@onready var pause_layer : PauseLayer = $PauseLayer
@onready var transition_layer : CanvasLayer = $TransitionLayer
@onready var world_env : WorldEnvironment = $WorldEnvironment

@export var debug : bool = false

var autoplay_turn : bool = false: set = set_autoplay
var speed_toggled : bool = false: set = toggle_speed #? Queryable boolean that says if the engine acceleration was toggled on/off
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

func _on_focus_changed(control : Control) -> void:
	if debug: print('UI DEBUG | Focus changed to ' + str(control.get_path()))

func set_pause(state : bool) -> void:
	pause_state = state
	get_tree().paused = state
	if !state and speed_cached: toggle_speed(true)
	else: toggle_speed(false)
	game_paused.emit(state)

func toggle_speed(toggle : bool) -> void:
	speed_toggled = toggle
	var speed_tween : Tween = get_tree().create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_ease(Tween.EASE_IN)
	var new_speed : int = 1
	if toggle: new_speed = TIME_SCALE_MULTIPLY
	speed_tween.tween_property(Engine, "time_scale", new_speed, 1)
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

func set_autoplay(autoplay : bool) -> void:
	autoplay_turn = autoplay
	autoplay_changed.emit()

func _on_wave_activity_changed(active: bool) -> void:
	if active: if speed_cached: toggle_speed(true)
	else: if !autoplay_turn: toggle_speed(false)

func _on_turn_pass_requested() -> void:
	if UI.wave_is_active: #? Makes the game go faster with the same action that passes the turn
		UI.toggle_speed(!UI.speed_toggled)
		speed_cached = !speed_cached

func _on_mouse_on_ui_changed(present: bool) -> void:
	if debug: print('Mouse on ui: ', present)
