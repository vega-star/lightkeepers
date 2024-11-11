extends MenuPage

const abrupt_closure_speed : float = 0.25

func set_focus(): 
	$ButtonsContainer/StartButton.grab_focus()

func _ready():
	if OS.has_feature("web"): # Web patches
		$ButtonsContainer/QuitButton.visible = false
	Options.focus_freed.connect(set_focus)
	_page_ready()

func _on_start_button_pressed():
	owner.set_page_position(-1) # Stage Selection

func _on_settings_button_pressed():
	if !Options.visible: Options.show()
	else: Options._on_exit_menu_pressed()

func _on_quit_button_pressed(): # QuitButton
	get_tree().quit()

# func _on_itch_io_link_pressed(): OS.shell_open("https://nyeptun.itch.io/lightkeepers")

func _on_github_button_pressed() -> void: OS.shell_open("https://github.com/vega-star/lightkeepers")
