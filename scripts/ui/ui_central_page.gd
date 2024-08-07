extends MenuPage

const abrupt_closure_speed : float = 0.25

func set_focus(): 
	$ButtonsContainer/StartButton.grab_focus()

func _ready():
	if OS.has_feature("web"): # Web patches
		$ButtonsContainer/QuitButton.visible = false
	_page_ready()

func _on_start_button_pressed():
	owner.set_page_position(-1) # Stage Selection

func _on_settings_button_pressed():
	pass # Replace with function body

func _on_quit_button_pressed(): # QuitButton
	get_tree().quit()

# func _on_git_hub_link_pressed(): OS.shell_open("https://github.com/vega-star/godot-strata")
# func _on_itch_io_link_pressed(): OS.shell_open("https://nyeptun.itch.io/strata-zero")
# func _on_youtube_link_pressed(): 
