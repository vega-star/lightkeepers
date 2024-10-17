extends Panel

signal decison_made()

const MOVE_TWEEN_PERIOD : float = 0.5

@onready var stage_success_label : Label = $StageSuccessLabel
@onready var screen_center : Marker2D = $"../ScreenCenter"
@onready var continue_button : Button = $ButtonContainer/Continue
@onready var restart_button : Button = $ButtonContainer/Restart

func _ready() -> void: if visible: set_visible(false)

func _move(to_visibility : bool) -> void:
	var move_tween = get_tree().create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var target_position : Vector2
	if to_visibility:
		position = Vector2(screen_center.position.x, -size.y) - pivot_offset
		show()
		target_position = screen_center.position - pivot_offset
		move_tween.tween_property(self, "position", target_position, MOVE_TWEEN_PERIOD)
	else:
		target_position = Vector2(screen_center.position.x, -size.y) - pivot_offset
		move_tween.tween_property(self, "position", target_position, MOVE_TWEEN_PERIOD)
		await move_tween.finished
		hide()

func conclude(win : bool) -> void:
	_move(true)
	UI.pause_locked = true
	UI.PAUSE_LAYER.pause()
	UI.PAUSE_LAYER.set_signaled_unpause(self, decison_made)
	if win:
		stage_success_label.set_text(TranslationServer.tr('STAGE_SUCCESS').capitalize())
		restart_button.set_visible(false)
		continue_button.set_visible(true)
	else:
		stage_success_label.set_text(TranslationServer.tr('STAGE_FAILED').capitalize())
		restart_button.set_visible(true)
		continue_button.set_visible(false)

func _on_return_to_menu_pressed() -> void: decison_made.emit(); _move(false); LoadManager.return_to_menu()

func _on_restart_pressed() -> void: decison_made.emit(); _move(false); LoadManager.reload_scene()

func _on_continue_pressed() -> void: decison_made.emit(); _move(false)
