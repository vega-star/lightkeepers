extends Control

const main_menu = preload('res://scenes/ui/main_menu.tscn')
const fade_time : float = 2.5

@export var intro_timer : float = 2
@export var skip_intro_on_debug : bool = false

func _ready():
	if OS.is_debug_build() and skip_intro_on_debug: # Skip intro when debug
		get_tree().change_scene_to_packed(main_menu)
		return
	
	UI.fade('IN')
	$IntroAnimation.play('LOGO_FADE_IN')
	await get_tree().create_timer(intro_timer).timeout
	$IntroAnimation.play_backwards('LOGO_FADE_IN')
	await UI.fade('OUT')
	get_tree().change_scene_to_packed(main_menu)
