## Menu class is a general class to deal with different MenuPages instances
## Useful for creative purposes, independent/interactive menus and such
class_name Menu extends Control

@export var menu_songs : Array[String] = []
@export var TRANS : Tween.TransitionType = Tween.TRANS_EXPO

@onready var menu_pages : Control = $MenuPages
@onready var menu_camera : Camera2D = $MenuCamera
@onready var version_label : Label = $MenuPages/CentralPage/VersionLabel
@onready var project_version : String = ProjectSettings.get_setting("application/config/version")

var in_movement : bool = false
var current_page : MenuPage
var initial_page : MenuPage

func _ready():
	Options.focus_freed.connect(set_focus)
	version_label.text = "v%s" % project_version
	UI.fade('IN')
	UI.interface.set_visible(false)
	StageManager.on_stage = false
	AudioManager.play_music(menu_songs, 0, false, true)
	
	initial_page = menu_pages.get_child(0)
	current_page = initial_page
	current_page.set_focus()

func set_focus(page : MenuPage = current_page):
	if !page.visible: page.visible = true
	page.set_focus()

func set_page(new_page : MenuPage):
	if in_movement: return
	in_movement = true
	new_page.set_visible(true)
	release_focus()
	
	var position_tween = get_tree().create_tween()
	position_tween.tween_property(menu_camera, "position", new_page.global_position, 0.95).set_trans(TRANS)
	
	await position_tween.finished
	set_focus(new_page)
	current_page.set_visible(false)
	current_page = new_page
	in_movement = false
