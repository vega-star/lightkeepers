class_name ThreatManager extends Node

signal wave_completed
signal entity_scene_loaded
signal entity_load_available

const enemy_scene = preload("res://scenes/entities/enemy.tscn")

@export var enemy_spawn_point : Marker2D
@onready var stage_manager = $"../StageManager"

var use_sub_threads : bool = true
var loaded_entity : PackedScene
var entity_scene_path : String
var entity_loading : bool = false
var entity_load_progress : Array = []
var wave_enemies : Array[Enemy]

func _ready():
	randomize()
	set_process(false)

func _process(delta):
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

func _on_spawn_cooldown_timeout():
	var enemy = enemy_scene.instantiate()
	$"../Containers/EntityContainer".add_child(enemy)
	enemy.position = enemy_spawn_point.position
