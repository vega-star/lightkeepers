extends CanvasLayer

func _ready():
	if visible: visible = false

func pause():
	# unpause_button.grab_focus()
	UI.set_pause(true)
	show()

func unpause():
	UI.set_pause(false)
	hide()

func _input(_event):
	if Input.is_action_just_pressed("pause") and !UI.pause_state: pause()
	elif Input.is_action_just_pressed("pause") and UI.pause_state: unpause()
