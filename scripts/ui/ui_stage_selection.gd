extends MenuPage

func set_focus(): 
	$GridContainer/TextureButton.grab_focus()

func _ready():
	_page_ready()

func _on_return_button_pressed():
	owner.set_page_position(0) # Main Screen

func _on_quit_button_pressed(): # QuitButton
	get_tree().quit()
