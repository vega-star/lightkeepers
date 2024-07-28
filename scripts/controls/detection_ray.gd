extends RayCast2D

var target

func _process(delta):
	var ray_point = get_local_mouse_position()
	var cast_point
	force_raycast_update()
	
	target_position = ray_point
	
	if is_colliding():
		cast_point = get_collision_point()
		target = get_collider()
		$Line2D.points[-1] = cast_point
	else:
		$Line2D.points[-1] = to_global(ray_point)
