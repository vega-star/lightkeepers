class_name MenuPage extends Control

@export var hide_when_initiated : bool = false

func _page_ready():
	if hide_when_initiated: set_visible(false)
