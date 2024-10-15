class_name TurnManager extends Node

signal turn_passed(current_turn : int, max_turns : int)
signal wave_completed
signal entity_scene_loaded
signal entity_load_available
signal schedule_finished

const ENEMY_SCENE_FOLDER : String = "res://scenes/entities/"
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
@onready var spawn_timer : Timer = $SpawnTimer
@onready var turn_timer : Timer = $TurnTimer

#? Properties that differentiate each stage
@export var turn_schedule : StageSchedule : set = _load_schedule
@export var enemy_spawn_point : Marker2D
@export var infinite : bool = false
@export var debug : bool = false

## Stage controls
var current_turn : int = 0 : set = _set_turn
var cached_turns : int = 0 #? Used in the future with infinite mode
var autoplay : bool = false
var stage_initiated : bool = false
var max_turns : int

## Load module
var loaded_entity : PackedScene
var use_sub_threads : bool = true
var entity_scene_path : String
var entity_loading : bool = false
var entity_load_progress : Array = []

#region Main functions
func _ready() -> void:
	# randomize()
	set_process(false)
	
	_load_schedule(turn_schedule)
	UI.HUD.autoplay_toggled.connect(_on_autoplay_toggled)
	UI.HUD.turn_pass_requested.connect(_on_turn_pass)
	turn_passed.connect(UI.HUD.turn_update)
	UI.HUD.turn_update(0, max_turns)

func _load_schedule(schedule : StageSchedule) -> void:
	turn_schedule = schedule
	max_turns = schedule.turns.size()

func run_schedule(schedule : StageSchedule = turn_schedule) -> void:
	#region Turns
	for turn in schedule.turns:
		current_turn += 1
		#region Waves
		for wave in turn.turn_waves:
			#var turn_thread : Thread = Thread.new()
			#turn_thread.start(execute_wave.bind(wave))
			execute_wave(wave)
			turn_timer.start(wave.wave_period)
			await turn_timer.timeout
		#endregion
		stage_agent.change_coins(turn.coins_on_turn_completion, true)
		if debug: print('Wave finished, added ', turn.coins_on_turn_completion, ' coins')
		if !autoplay: await UI.HUD.turn_pass_requested #? Stops here and waits to player prompt to continue. If autoplay is on, ignores and move on
	#endregion
	## Schedule finished
	schedule_finished.emit()

func _on_schedule_finished() -> void:
	if infinite: run_schedule()

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
func _on_autoplay_toggled(toggle : bool) -> void: autoplay = toggle

func _on_turn_pass() -> void:
	if !stage_initiated:
		stage_initiated = true
		run_schedule()

func _set_turn(new_value : int) -> void:
	current_turn = new_value
	turn_passed.emit(current_turn, max_turns)

func execute_wave(wave : Wave) -> void:
	AudioManager.emit_random_sound_effect(enemy_spawn_point.position, TURN_PASS_SFX)
	
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
		var entity = loaded_entity.instantiate()
		entity.position = enemy_spawn_point.position
		entity_container.add_child(entity)
		spawn_timer.start(wave.spawn_cooldown)
		spawn_timer.set_process_mode(Node.PROCESS_MODE_PAUSABLE)
		await spawn_timer.timeout
	#endregion
	wave_completed.emit()
	return
#endregion
