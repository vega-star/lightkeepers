class_name LaserProjectile extends Projectile

signal laser_started
signal laser_stopped

const LASER_SPEED_MULTIPLY : int = 5

@onready var laser : RayCast2D = $LaserProjectile
@onready var laser_line : Line2D = $LaserProjectile/LaserLine
@export var laser_size : int = 4

func _physics_process(delta) -> void:
	rotation = 0
	laser.force_raycast_update()
	laser_line.points[1] = laser.target_position
	
	var collider = laser.get_collider()
	if laser.is_colliding() and is_instance_valid(collider): _on_body_entered(collider)
	
	cpu_particles.position = laser.target_position / 2
	cpu_particles.emission_rect_extents = Vector2(laser.target_position.x, 0)
	
	if is_instance_valid(target): laser.target_position = target.global_position

func _activate() -> void:
	cpu_particles.emitting = true
	AudioManager.emit_random_sound_effect(global_position, sfx_when_launched, "Effects", PITCH_VARIATION)
	
	var laser_tween : Tween = get_tree().create_tween()
	laser_tween.tween_property(laser_line, "width", laser_size, 0.2)
	
	laser_started.emit()
	var lifetime_timer : Timer = Timer.new()
	lifetime_timer.set_process_mode(ProcessMode.PROCESS_MODE_PAUSABLE)
	add_child(lifetime_timer)
	lifetime_timer.start(lifetime)
	await lifetime_timer.timeout # TODO: Personalized timer / distance delta
	_break()

func _deactivate() -> void:
	var laser_tween : Tween = get_tree().create_tween()
	laser_tween.tween_property(laser_line, "width", 0, 0.2)
	await laser_tween.finished
	active = false
	set_visible(false)

func _break() -> void:
	set_physics_process(false)
	await _deactivate()
	AudioManager.emit_random_sound_effect(global_position, sfx_when_broken)
	queue_free()

func _on_body_collided(body) -> void:
	if !active: return
	
	if body is Enemy:
		if is_instance_valid(source): body.health_component.change(damage, true, source)
		else: body.health_component.change(damage, true)
		if !projectile_effect_metadata.is_empty():
			body.health_component.effect_component.apply_effect(
				projectile_effect_metadata["eid"],
				projectile_effect_metadata,
				source
			)
		if projectile_mode == 1: projectile_mode = 0
		AudioManager.emit_random_sound_effect(global_position, sfx_when_hit)
	# if piercing_count <= 0: _break()
