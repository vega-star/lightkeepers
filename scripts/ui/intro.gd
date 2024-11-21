extends Control

const MAIN_MENU_PATH = preload('res://scenes/ui/main_menu.tscn')
const INTRO_TIMER : float = 3

var is_ending : bool = false

@export var skip_intro : bool = false
@export var skip_intro_on_debug : bool = true

@onready var intro_animation : AnimationPlayer = $IntroAnimation
@onready var bg_rect : ColorRect = $BGRect

func _ready():
	if skip_intro: get_tree().change_scene_to_packed(MAIN_MENU_PATH); return
	if OS.is_debug_build() and skip_intro_on_debug: get_tree().change_scene_to_packed(MAIN_MENU_PATH); return
	
	var boot_splash_style_box : StyleBoxFlat = StyleBoxFlat.new()
	boot_splash_style_box.set_bg_color(ProjectSettings.get_setting("application/boot_splash/bg_color"))
	bg_rect.add_theme_stylebox_override("panel", boot_splash_style_box)
	_start()

func _start() -> void:
	UI.fade('IN')
	intro_animation.speed_scale = 1
	intro_animation.play('LOGO_FADE_IN')
	await get_tree().create_timer(INTRO_TIMER).timeout
	_end()

func _end() -> void:
	is_ending = true
	intro_animation.speed_scale = 2
	intro_animation.play_backwards('LOGO_FADE_IN')
	await UI.fade('OUT')
	get_tree().change_scene_to_packed(MAIN_MENU_PATH)
