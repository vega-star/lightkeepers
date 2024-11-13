## LoadingScene
## Plays in-between scenes when called by LoadManager.
## Its color is defined by the Boot Splash from ProjectSettings
extends CanvasLayer

signal loading_screen_has_full_coverage

@onready var loading_panel = $LoadingPanel
@onready var animation_player = $LoadingPanel/AnimationPlayer
@onready var progress_bar = $LoadingPanel/ProgressBarFrame/ProgressBar

func _ready():
	_start_intro_animation()
	var boot_splash_style_box : StyleBoxFlat = StyleBoxFlat.new()
	boot_splash_style_box.set_bg_color(ProjectSettings.get_setting("application/boot_splash/bg_color"))
	loading_panel.add_theme_stylebox_override("panel", boot_splash_style_box)

func _update_progress_bar(new_value : float) -> void:
	progress_bar.set_value_no_signal(new_value * 100)

func _start_intro_animation():
	animation_player.play("START_LOAD")

func _start_outro_animation():
	animation_player.play("END_LOAD")
	UI.fade('IN')
	await animation_player.animation_finished
	queue_free()
