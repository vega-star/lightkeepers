extends MenuPage

const BUTTON_SHOW_TIMEOUT : float = 0.12
const NEXT_BUTTON_TIMEOUT : float = 0.2

@export var stage_selection_page : MenuPage
@onready var page_player : AnimationPlayer = $PagePlayer
@onready var buttons_container : VBoxContainer = $ButtonsContainer
@onready var quit_button : Button = $ButtonsContainer/QuitButton

func _ready() -> void:
	if OS.has_feature("web"): # Web patches
		quit_button.visible = false #! Cannot quit on web. Will simply crash
	for b in buttons_container.get_children(): b.self_modulate = Color.TRANSPARENT
	_page_ready()
	# page_player.play("page_loaded")

func _smooth_button_load() -> void:
	for b in buttons_container.get_children():
		if !b.visible: continue
		var b_tween : Tween = get_tree().create_tween()
		b_tween.tween_property(b, "self_modulate", Color.WHITE, BUTTON_SHOW_TIMEOUT)
		await get_tree().create_timer(NEXT_BUTTON_TIMEOUT).timeout

func _on_start_button_pressed() -> void:
	# owner.set_page(stage_selection_page) # Stage Selection
	LoadManager.load_scene("res://scenes/stages/stage_files/stage_001.tscn") #MAKESHIFT!

func _on_settings_button_pressed() -> void:
	if !Options.visible: Options.show()
	else: Options._on_exit_menu_pressed()

func _on_quit_button_pressed() -> void: # QuitButton
	get_tree().quit()

func _on_github_button_pressed() -> void: OS.shell_open("https://github.com/vega-star/lightkeepers")

func _on_credits_pressed() -> void:
	pass # Replace with function body.
