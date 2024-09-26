extends Node

const music_fade_timer : float = 2.5
const pitch_bend_delay = 0.5
const effects_dir_path = "res://assets/audio/effects/"
const music_dir_path = "res://assets/audio/music/"

@onready var global_effect_player = $GlobalEffectPlayer
@onready var music_player = $MusicPlayer
@onready var effects = $Effects

@export var loop_music : bool = true
@export var debug : bool = false

var randomized_songs : bool = false
var randomized_songs_array : Array = []
var pause_tween : Tween
var effects_list : Dictionary = {}
var music_list : Dictionary = {}

func _ready() -> void:
	load_from_dir(music_list, music_dir_path)
	load_from_dir(effects_list, effects_dir_path)

## Loads all files from a directory into an dictionary, with the name of the file as key and a loaded resource object as value.
## Use this function to load sounds and not bother manually adding new sounds to a constant dict.
func load_from_dir(target_dict : Dictionary, dir_path) -> void:
	var source_dir = DirAccess.open(dir_path)
	if source_dir:
		source_dir.list_dir_begin()
		var file_name = source_dir.get_next()
		while file_name != "":
			if source_dir.current_is_dir(): pass # Found directory, skip.
			elif file_name.ends_with(".import"): # Found an import file
				var file = file_name.split(".import")
				if target_dict.has(file[0]): pass # File was already loaded, skipping.
				else: # File not detected, thus loaded normally
					var file_path = str(dir_path + file[0] + file[1])
					target_dict[file[0].left(-4)] = load(file_path)
			else: # Found normal file
				pass
			
			file_name = source_dir.get_next() # Pass to next
	else:
		printerr("An error occurred when trying to access the constant path. Have you moved the folder? Check if path %s exists." % dir_path)
# Additional info if you've tried something similar but it failed: 
# If you invert the sequence loading only normal files instead of the .import (as it seems logical), this will only work in Editor.
# Exporting the project you'll see everything's muted and I went almost mad because of it. I've spent a few hours trying to understand it, and I found out why
# It's because normal files disappear after export, while .import files maintain their original path!
# You can also set the export configuration to maintain the files of a certain extension (.mp3, .ogg, etc.) and supposedly it also works, so... there you go!

func set_pause(value) -> void:
	if pause_tween: pause_tween.kill()
	
	pause_tween = get_tree().create_tween().set_ease(Tween.EASE_OUT).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var target_value : float
	
	if value: # Pause
		music_player.pitch_scale = 1
		target_value = 0.1
	else: # Unpause
		music_player.stream_paused = false
		music_player.pitch_scale = 0.1
		target_value = 1.0
	
	pause_tween.tween_property(
		music_player,
		"pitch_scale",
		target_value,
		pitch_bend_delay
	)
	
	await pause_tween.finished
	music_player.stream_paused = value

func set_music(music_id, fade_if_active : bool = true, random : bool = false, stage_songs : Array = []) -> void:
	randomized_songs_array = stage_songs
	
	if random:
		randomize()
		randomized_songs = true
		randomized_songs_array = stage_songs
		music_id = randomized_songs_array[randi_range(0, randomized_songs_array.size() - 1)]
	else: randomized_songs = false
	
	if music_player.playing and fade_if_active:
		var volume_tween : Tween = get_tree().create_tween()
		volume_tween.tween_property(music_player, "volume_db", -20, music_fade_timer)
		await volume_tween.finished
	
	music_player.stream = music_list[music_id]
	music_player.volume_db = 0
	music_player.play()

func play_music(
	music_array : Array,
	music_id : int = 0,
	fade : bool = true,
	random : bool = false
	) -> void:
		if random: music_id = randi_range(0, music_array.size() - 1)
		var selected_music = music_array[music_id]
		AudioManager.set_music(selected_music, fade, random, music_array)

func emit_random_sound_effect(position : Vector2, r_sfx_array : Array, interrupt : bool = false) -> void:
	var effect_id = r_sfx_array[randi_range(0, r_sfx_array.size() - 1)]
	emit_sound_effect(position, effect_id, interrupt)

func emit_sound_effect(position : Vector2, effect_id : String, interrupt : bool = false) -> void:
	if !effect_id: push_warning('EMPTY SOUND REQUEST | No effect_id was given, returning without emission'); return
	
	var ephemeral : bool = false
	var player # Audio player node
	if position is Vector2:
		ephemeral = true
		player = AudioStreamPlayer2D.new()
		effects.add_child(player)
		player.position = position
	else: player = global_effect_player
	
	if player.playing and interrupt: player.stop()
	
	player.stream = effects_list[effect_id]
	player.play()
	
	if ephemeral: 
		await player.finished
		player.queue_free()

func _on_music_finished() -> void:
	if randomized_songs and loop_music: set_music(0, true, true, randomized_songs_array)
	elif loop_music: music_player.play()
