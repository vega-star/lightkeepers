class_name MenuPage extends Control

@export var hide_when_initiated : bool = false
@export var default_focus_node : Control

func _page_ready() -> void:
	if hide_when_initiated: set_visible(false)

func set_focus() -> void:
	assert(default_focus_node)
	default_focus_node.grab_focus()
