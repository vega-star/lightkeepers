extends Control

const stage_zero : String = "res://scenes/stages/stagezero.tscn"

func _ready():
	UI.fade('IN')

func _on_button_pressed():
	LoadManager.load_scene(stage_zero)
