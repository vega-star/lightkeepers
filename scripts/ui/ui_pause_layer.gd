class_name PauseLayer extends CanvasLayer

var listening_source : Node
var listening_signal : Signal

func _ready() -> void: if visible: hide()

func pause() -> void: UI.set_pause(true); show()

func unpause() -> void: UI.set_pause(false); hide()

func set_pause_by_signal(mode : bool) -> void:
	if mode: pause()
	else:
		UI.pause_locked = false
		unpause()
		if listening_signal: listening_signal.disconnect(set_pause_by_signal)

func _unhandled_input(_event) -> void:
	if UI.pause_locked: return
	if Input.is_action_just_pressed("space") and !UI.pause_state: pause()
	elif Input.is_action_just_pressed("space") and UI.pause_state: unpause()

func _on_options_button_pressed() -> void:
	Options.show()

func set_signaled_unpause(source : Node, source_signal : Signal) -> void:
	listening_source = source
	listening_signal = source_signal
	listening_signal.connect(set_pause_by_signal.bind(!listening_source.visible))
