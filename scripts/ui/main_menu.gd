class_name Menu extends Control

@export var menu_songs : Array[String] = []
@export var start_button : UIButton

@onready var project_version = ProjectSettings.get_setting("application/config/version")
@onready var version_label = $MenuPages/CentralPage/VersionLabel
@onready var menu_pages = $MenuPages
# @onready var config_button = $ConfigButton

var page_in_movement : bool = false
var screen_size : Vector2
var page_direction : bool
var page_position : int = 0
var page_position_offset : int = 0

const page_position_offset_x : int = 0
const page_position_offset_y : int = 0

func _ready():
	version_label.text = "v%s" % project_version
	screen_size = get_viewport_rect().size
	UI.fade('IN')
	UI.HUD.set_visible(false)
	LoadManager._scene_is_stage = false
	AudioManager.play_music(menu_songs, 0, true, true)
	$MenuPages/CentralPage.set_focus()

func set_focus(focus_position, direction):
	var page = get_page_from_position(focus_position, direction)
	if !page.visible: page.visible = true
	page.set_focus()

func get_page_from_position(select_position, direction : bool) -> Node:
	var page : Node
	match direction:
		true: # Horizontal
			match select_position:
				-1: page = $MenuPages/StageSelection
				0: page = $MenuPages/CentralPage
				1: return
		false: # Vertical
			match select_position:
				-1: return
				0: page = $MenuPages/CentralPage
				1: return
	return page

func set_page_position(new_position, direction : bool = true):
	if page_in_movement: return
	
	page_in_movement = true
	var previous_page_position = page_position
	var previous_page_direction = page_direction
	var previous_page = get_page_from_position(previous_page_position, previous_page_direction) 
	
	page_position = new_position
	page_direction = direction
	var new_page = get_page_from_position(page_position, page_direction)
	
	var position_tween = get_tree().create_tween()
	match page_direction:
		true: # Horizontal
			position_tween.tween_property(menu_pages, "position", Vector2((screen_size.x + page_position_offset_x) * page_position, 0), 0.95).set_trans(Tween.TRANS_EXPO)
		false: # Vertical
			position_tween.tween_property(menu_pages, "position", Vector2(0, (screen_size.y + page_position_offset_y) * page_position), 0.95).set_trans(Tween.TRANS_EXPO)
	set_focus(page_position, page_direction)
	
	await get_tree().create_timer(1).timeout
	previous_page.visible = false
	page_in_movement = false

## Reactive Signals
# func _on_config_button_pressed(): Options.visible = true
# func _on_options_visibility_changed(): if !Options.visible: set_focus(page_position, page_direction)
