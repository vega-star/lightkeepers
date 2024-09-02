extends CanvasLayer

func _ready():
	if visible: hide()

func pause():
	UI.set_pause(true)
	show()

func unpause():
	UI.set_pause(false)
	hide()

func _unhandled_input(_event):
	if UI.pause_locked: return
	if Input.is_action_just_pressed("space") and !UI.pause_state: pause()
	elif Input.is_action_just_pressed("space") and UI.pause_state: unpause()

func _on_options_button_pressed():
	Options.show()
