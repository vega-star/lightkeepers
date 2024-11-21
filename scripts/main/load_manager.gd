extends Node

signal progress_changed(progress)
signal load_completed

@warning_ignore("unused_private_class_variable")
@export var use_sub_threads : bool = true

const LOADING_SCENE : PackedScene = preload("res://scenes/ui/loading_scene.tscn")
const MAIN_MENU_PATH : String = "res://scenes/ui/main_menu.tscn"

#? Set this as false in case a scene should be switched only after an animation or an intro, but could be loaded during it.
#? Remember to connect the load_completed signal to call _switch_to_scene(), or else it will do nothing
var _immediately_switch : bool = true

var _is_loaded : bool = false
var _loaded_resource : PackedScene
var _scene_path : String
var _progress : Array = []

func _ready() -> void: set_process(false)

func return_to_menu() -> void:
	ElementManager._purge()
	load_scene(MAIN_MENU_PATH)

func reload_scene() -> void: 
	assert(_scene_path)
	ElementManager._purge()
	load_scene(_scene_path) #? Reload active scene

func load_scene(next_scene_path : String, with_loading_screen : bool = true) -> void:
	AudioManager.set_pause(true)
	_scene_path = next_scene_path
	assert(_scene_path)
	if UI.speed_toggled: UI.toggle_speed(false)
	if with_loading_screen: await _call_loading_screen()
	else: _immediately_switch = false #? Will not show progress of this specific loaded scene. 
	start_load()

func start_load() -> void:
	_is_loaded = false
	var state = ResourceLoader.load_threaded_request(_scene_path, "", use_sub_threads)
	if state == OK: set_process(true)

func _process(_delta) -> void:
	var load_status = ResourceLoader.load_threaded_get_status(_scene_path, _progress)
	match load_status:
		0, 2: #? THREAD_LOAD_INVALID_RESOURCE, THREAD_LOAD_FAILED
			set_process(false)
			push_error("ERROR LOADING SCENE | Scene path ", _scene_path, " may be wrong or invalid")
			return
		1: #? THREAD_LOAD_IN_PROGRESS
			emit_signal("progress_changed", _progress[0])
		3: #? THREAD_LOAD_LOADED
			_loaded_resource = ResourceLoader.load_threaded_get(_scene_path)
			emit_signal("progress_changed", 1.0)
			emit_signal("load_completed")
			_is_loaded = true
			if _immediately_switch:
				_switch_to_scene() #? By default, will promptly discard the current scene and switch to the other.
			set_process(false)

func _call_loading_screen() -> void:
	var loading_screen = LOADING_SCENE.instantiate()
	get_tree().get_root().call_deferred("add_child", loading_screen)
	self.progress_changed.connect(loading_screen._update_progress_bar)
	self.load_completed.connect(loading_screen._start_outro_animation)
	await Signal(loading_screen, "has_full_coverage")
	return

func _switch_to_scene(scene : PackedScene = _loaded_resource) -> void:
	get_tree().change_scene_to_packed(scene)
