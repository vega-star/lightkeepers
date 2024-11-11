class_name TurnManager extends Node

signal turn_passed(current_turn : int, max_turns : int)
signal wave_completed
signal entity_scene_loaded
signal entity_load_available
signal schedule_finished

const ENEMY_SCENE_FOLDER : String = "res://scenes/entities/enemies/"
const TURN_PASS_SFX : Array = [
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
	"bug people 15"]

@onready var stage_agent : StageAgent = $".."
@onready var entity_container : Node2D = $"../../Containers/EntityContainer"
@onready var spawn_positions : Node2D = $"../../Containers/SpawnPositions"
@onready var spawn_timer : Timer = $SpawnTimer

#? Properties that differentiate each stage
@export var turn_schedule : StageSchedule : set = _load_schedule
@export var infinite : bool = false
@export var debug : bool = false

## Stage controls
var current_turn : int = 0 : set = _set_turn
var cached_turns : int = 0 #? Used in the future with infinite mode
var stage_initiated : bool = false
var max_turns : int

## Load module
var loaded_entity : PackedScene
var use_sub_threads : bool = true
var entity_scene_path : String
var entity_loading : bool = false
var entity_load_progress : Array = []
var wave_enemy_count : int

#region Main functions
func _ready() -> void:
	set_process(false)
	_load_schedule(turn_schedule)
	UI.interface.turn_pass_requested.connect(_on_turn_pass)
	turn_passed.connect(UI.interface.turn_update)
	UI.interface.turn_update(0, max_turns)

func _process(_delta) -> void:
	var load_status = ResourceLoader.load_threaded_get_status(entity_scene_path, entity_load_progress)
	match load_status:
		0, 2: #? THREAD_LOAD_INVALID_RESOURCE, THREAD_LOAD_FAILED
			set_process(false)
			printerr("ERROR LOADING SCENE | Scene path may be wrong or invalid")
			return
		1: pass #? THREAD_LOAD_IN_PROGRESS
		3: #? THREAD_LOAD_LOADED
			loaded_entity = ResourceLoader.load_threaded_get(entity_scene_path)
			entity_scene_loaded.emit()
			entity_load_available.emit()
			set_process(false)
#endregion

#region Execution functions
func _load_schedule(schedule : StageSchedule) -> void:
	turn_schedule = schedule
	max_turns = schedule.turns.size()

func _set_turn(new_value : int) -> void:
	current_turn = new_value
	turn_passed.emit(current_turn, max_turns)

func _on_turn_pass() -> void:
	if !stage_initiated:
		stage_initiated = true
		run_schedule()

func run_schedule(schedule : StageSchedule = turn_schedule) -> void:
	for turn in schedule.turns: ## Turns
		current_turn += 1
		for wave in turn.turn_waves: ## Waves
			execute_wave(wave)
			await wave_completed
		stage_agent.change_coins(turn.coins_on_turn_completion, true)
		UI.wave_is_active = false
		
		if !UI.autoplay_turn:
			await UI.interface.turn_pass_requested #? Stops here and waits to player prompt to continue. If autoplay is on, ignores and move on
	schedule_finished.emit() ## Finish

func _on_schedule_finished() -> void:
	stage_agent.close_stage(true)
	await UI.stage_ended
	if infinite: run_schedule()

func execute_wave(wave : Wave) -> void:
	AudioManager.emit_random_sound_effect(spawn_positions.get_child(0).position, TURN_PASS_SFX)
	UI.wave_is_active = true
	wave_enemy_count = 0
	
	#region Entity loading
	if !wave.enemy_id: wave.enemy_id = "enemy"; push_warning("Enemy path was invalid on wave ", wave, ". Overriding to enemy template.")
	var selected_entity_scene = "{0}/{1}.tscn".format({0: ENEMY_SCENE_FOLDER, 1: wave.enemy_id})
	if entity_scene_path == selected_entity_scene: pass ## Avoid reloading the same thing repeateadly
	else:
		entity_scene_path = selected_entity_scene
		if entity_loading: await entity_scene_loaded # If there's already one entity loading, wait for it to finish
		entity_loading = true
		
		var state = ResourceLoader.load_threaded_request(entity_scene_path, "", use_sub_threads)
		if state == OK: set_process(true)
		else: printerr("ERROR REQUESTING SCENE LOAD | Scene path may be wrong or invalid"); return
		
		await entity_load_available
		entity_loading = false
	#endregion
	
	#region Entity spawning
	if debug: print('Running spawn of ', wave.quantity, ' enemies of type ', loaded_entity)
	for i in wave.quantity:
		var entity : Enemy = loaded_entity.instantiate()
		entity.position = spawn_positions.get_child(0).position
		entity_container.call_deferred("add_child", entity)
		spawn_timer.start(wave.spawn_cooldown) # .set_process_mode(Node.PROCESS_MODE_PAUSABLE)
		wave_enemy_count += 1
		entity.died.connect(_remove_from_current_wave)
		await spawn_timer.timeout
	#endregion
	return

func _remove_from_current_wave(_source) -> void:
	wave_enemy_count -= 1
	if wave_enemy_count == 0: wave_completed.emit()
#endregion
