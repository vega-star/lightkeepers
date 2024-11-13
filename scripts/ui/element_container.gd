extends HBoxContainer

func _purge_elements() -> void: for c in get_children(): c.queue_free()
