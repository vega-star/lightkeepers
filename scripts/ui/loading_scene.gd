extends CanvasLayer

signal loading_screen_has_full_coverage

@onready var loading_panel = $LoadingPanel
@onready var animation_player = $LoadingPanel/AnimationPlayer
@onready var progress_bar = $LoadingPanel/ProgressBarFrame/ProgressBar
@onready var progress_shimmer: CPUParticles2D = $ProgressShimmer

func _ready():
	_start_intro_animation()

func _update_progress_bar(new_value : float) -> void:
	progress_bar.set_value_no_signal(new_value * 100)
	progress_shimmer.position.x = progress_bar.position.x + remap(new_value * 100, 0, 100, progress_bar.position.x, progress_bar.size.x)

func _start_intro_animation():
	animation_player.play("START_LOAD")

func _start_outro_animation():
	animation_player.play("END_LOAD")
	UI.fade('IN')
	await animation_player.animation_finished
	queue_free()
