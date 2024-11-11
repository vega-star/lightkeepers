extends Control

const MAIN_MENU_PATH = preload('res://scenes/ui/main_menu.tscn')
const INTRO_TIMER : float = 3

@export var skip_intro_on_debug : bool = true
@onready var intro_animation : AnimationPlayer = $IntroAnimation

func _ready():
	if OS.is_debug_build() and skip_intro_on_debug: get_tree().change_scene_to_packed(MAIN_MENU_PATH); return
	
	UI.fade('IN')
	intro_animation.speed_scale = 1
	intro_animation.play('LOGO_FADE_IN')
	await get_tree().create_timer(INTRO_TIMER).timeout
	intro_animation.speed_scale = 2
	intro_animation.play_backwards('LOGO_FADE_IN')
	await UI.fade('OUT')
	get_tree().change_scene_to_packed(MAIN_MENU_PATH)
