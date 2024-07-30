class_name Projectile extends Node2D

const fade_timer : float = 2

@export_enum('STRAIGHT', 'SEEKING') var projectile_type : String = 'STRAIGHT' ## Affects processes and movement
@export var base_lifetime : float = 3
@export var base_speed : int = 600
@export var base_piercing : int = 1
@export var base_damage : int = 5
@export var base_seeking_weight : float = 0.5
@export var disappear_outside_screen : bool = false

var source : Tower
var target : Object
var speed : int
var damage : int
var lifetime : float
var piercing_count : int = 1
var seeking_weight : float
var stored_direction : Vector2

func _ready():
	seeking_weight = base_seeking_weight
	speed = base_speed
	damage = base_damage
	lifetime = base_lifetime
	_activate()

func _activate():
	$CPUParticles2D.emitting = true
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta):
	match projectile_type:
		'STRAIGHT': 
			global_position += Vector2(speed * delta, 0).rotated(rotation)
		'SEEKING':
			if is_instance_valid(target): 
				stored_direction = global_position.direction_to(target.global_position)
				look_at(target.global_position)
			else: projectile_type = 'STRAIGHT'; return
			global_position += (stored_direction * speed * delta)

func _on_body_entered(body):
	if body is Enemy:
		body.health_component.change(damage, true, source)
		piercing_count -= 1
	if piercing_count == 0: queue_free()

func _on_screen_exited():
	if disappear_outside_screen: 
		await get_tree().create_timer(fade_timer).timeout
		queue_free()
