class_name Projectile extends Node2D

enum PROJECTILE_MODES {
	STRAIGHT,
	SEEKING
}

const PITCH_VARIATION : Vector2 = Vector2(0.7,1.3)

@export_group('Projectile Properties')
@export var projectile_mode : PROJECTILE_MODES = 0 ## Affects processes and movement
@export var base_lifetime : float = 3
@export var base_speed : int = 600
@export var base_piercing : int = 1
@export var base_damage : int = 5
@export var base_seeking_weight : float = 0.5

@export_group('Cosmetic Properties')
@export var sfx_when_launched : Array[String]
@export var sfx_when_hit : Array[String]
@export var sfx_when_broken : Array[String]

@onready var projectile_sound = $ProjectileSound
@onready var cpu_particles : CPUParticles2D = $CPUParticles2D

var source : Tower
var target : Object
var speed : int
var damage : int
var lifetime : float
var piercing_count : int = 1
var seeking_weight : float = 1
var stored_direction : Vector2
var init_pos : Vector2
var element_metadata : Dictionary: set = _set_element_metadata #? Stores a series of values useful to effects, changing colors, etc. while not being attatched to the element itself

func _ready():
	seeking_weight = base_seeking_weight
	speed = base_speed
	damage = base_damage
	lifetime = base_lifetime
	_activate()

func _activate():
	# init_pos = global_position
	cpu_particles.emitting = true
	AudioManager.emit_random_sound_effect(global_position, sfx_when_launched, "Effects", PITCH_VARIATION)
	await get_tree().create_timer(lifetime).timeout # TODO: Personalized timer / distance delta
	_break()

func _physics_process(delta):
	# var distance_delta = global_position.distance_squared_to(init_pos)
	# print(distance_delta)
	
	match projectile_mode:
		0: #| 'STRAIGHT'
			global_position += Vector2(speed * delta, 0).rotated(rotation)
		1: #| 'SEEKING'
			if is_instance_valid(target): 
				stored_direction = global_position.direction_to(target.global_position)
				# look_at(target.global_position)
				rotate_toward(rotation, get_angle_to(target.global_position), seeking_weight)
			else: projectile_mode = 0; return
			global_position += (stored_direction * speed * delta)
		_: push_error('INVALID PROJECTILE_TYPE')

func _on_body_entered(body):
	if body is Enemy:
		body.health_component.change(damage, true, source)
		piercing_count -= 1
		AudioManager.emit_random_sound_effect(global_position, sfx_when_hit)
	if piercing_count == 0: _break()

func _set_element_metadata(new_metadata : Dictionary) -> void:
	element_metadata = new_metadata
	# element_metadata[]

func _break(): AudioManager.emit_random_sound_effect(global_position, sfx_when_broken); queue_free()
