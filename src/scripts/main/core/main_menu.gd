## Menu class is a general class to deal with different MenuPages instances
## Useful for creative purposes, independent/interactive menus and such
class_name Menu extends Control

@export var menu_songs : Array[String] = []
@export var TRANS : Tween.TransitionType = Tween.TRANS_EXPO

@onready var version_label : Label = $CentralPage/VersionLabel
@onready var project_version : String = ProjectSettings.get_setting("application/config/version")

var in_movement : bool = false

func _ready():
	version_label.set_text("v%s" % project_version)
	AudioManager.play_music(menu_songs, 0, false, true)
