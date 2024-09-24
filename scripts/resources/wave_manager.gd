class_name WaveManager extends Node

signal turn_passed
signal wave_completed
signal entity_scene_loaded
signal entity_load_available

const enemy_scene = preload("res://scenes/entities/enemy.tscn")
const turn_passed_sfxs : Array = [
	"bug people 1",
	"bug people 2",
	"bug people 3",
	"bug people 4",
	"bug people 5",
	"bug people 6",
	"bug people 7",
	"bug people 8",
	"bug people 9",
	"bug people 10",
	"bug people 11",
	"bug people 12",
	"bug people 13",
	"bug people 14",
	"bug people 15",
]

@export var waves_resource : Waves
@export var enemy_spawn_point : Marker2D

@onready var stage_manager = $".."
@onready var entity_container = $"../../Containers/EntityContainer"

## Stage controls
var autoplay : bool = false
var stage_initiated : bool = false
var turn : int = 0 : set = _set_turn
var max_turns : int

## Load module
var use_sub_threads : bool = true
var loaded_entity : PackedScene
var entity_scene_path : String
var entity_loading : bool = false
var entity_load_progress : Array = []

func _ready():
	randomize()
	set_process(false)
	
	max_turns = waves_resource.waves.size()
	UI.HUD.turn_update(turn, max_turns)
	UI.HUD.autoplay_toggled.connect(_on_autoplay_toggled)
	UI.HUD.turn_pass_requested.connect(_on_turn_pass)

func _process(_delta):
	var load_status = ResourceLoader.load_threaded_get_status(entity_scene_path, entity_load_progress)
	match load_status:
		0, 2: #? THREAD_LOAD_INVALID_RESOURCE, THREAD_LOAD_FAILED
			set_process(false)
			printerr("ERROR LOADING SCENE | Scene path may be wrong or invalid")
			return
		1: #? THREAD_LOAD_IN_PROGRESS
			pass
			# emit_signal("progress_changed", entity_load_progress[0])
		3: #? THREAD_LOAD_LOADED
			loaded_entity = ResourceLoader.load_threaded_get(entity_scene_path)
			entity_scene_loaded.emit()
			entity_load_available.emit()
			set_process(false)

func _on_autoplay_toggled(toggle : bool):
	autoplay = toggle

func _on_turn_pass():
	if !stage_initiated:
		stage_initiated = true
		run_stage()

func _set_turn(new_value : int):
	turn = new_value
	UI.HUD.turn_update(turn, max_turns)
	
	AudioManager.emit_random_sound_effect(enemy_spawn_point.position, turn_passed_sfxs)
	turn_passed.emit()

func run_stage():
	for wave in waves_resource.waves:
		turn += 1
		await execute_wave(wave)
		if !autoplay: await UI.HUD.turn_pass_requested

func execute_wave(wave : Wave):
	var selected_entity_scene = wave.enemy_scene_path
	
	for i in wave.quantity:
		
		if entity_scene_path == selected_entity_scene: pass ## Avoid reloading the same thing repeatedly
		else:
			entity_scene_path = selected_entity_scene
			if entity_loading: await entity_scene_loaded # If there's already one entity loading, wait for it to finish
			entity_loading = true
			var state = ResourceLoader.load_threaded_request(entity_scene_path, "", use_sub_threads)
			if state == OK: set_process(true)
			else: printerr("ERROR REQUESTING SCENE LOAD | Scene path may be wrong or invalid"); return
			await entity_load_available
			entity_loading = false
		
		var entity = enemy_scene.instantiate()
		entity.position = enemy_spawn_point.position
		entity_container.add_child(entity)
		await get_tree().create_timer(wave.period).timeout
	
	stage_manager.change_coins(wave.coins_on_finish, true)
	wave_completed.emit()
	return
