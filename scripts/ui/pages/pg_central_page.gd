extends MenuPage

@export var stage_selection_page : MenuPage

func _ready():
	if OS.has_feature("web"): # Web patches
		$ButtonsContainer/QuitButton.visible = false #! Cannot quit on web. Will simply crash
	_page_ready()

func _on_start_button_pressed():
	owner.set_page(stage_selection_page) # Stage Selection

func _on_settings_button_pressed():
	if !Options.visible: Options.show()
	else: Options._on_exit_menu_pressed()

func _on_quit_button_pressed(): # QuitButton
	get_tree().quit()

func _on_github_button_pressed() -> void: OS.shell_open("https://github.com/vega-star/lightkeepers")
