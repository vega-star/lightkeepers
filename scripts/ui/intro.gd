extends Control

const MAIN_MENU_PATH = preload('res://scenes/ui/main_menu.tscn')
const INTRO_TIMER : float = 2.1

@export var skip_intro_on_debug : bool = true

func _ready():
	# Skip intro when debug
	if OS.is_debug_build() and skip_intro_on_debug: get_tree().change_scene_to_packed(MAIN_MENU_PATH); return
	UI.fade('IN')
	$IntroAnimation.play('LOGO_FADE_IN')
	await get_tree().create_timer(INTRO_TIMER).timeout
	$IntroAnimation.play_backwards('LOGO_FADE_IN')
	await UI.fade('OUT')
	get_tree().change_scene_to_packed(MAIN_MENU_PATH)
