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

var active : bool = true
var source : Object
var target : Object
var speed : int
var damage : int
var lifetime : float
var piercing_count : int = 1
var seeking_weight : float = 1
var stored_direction : Vector2
var init_pos : Vector2
var projectile_effect_metadata : Dictionary: set = _set_projectile_effect_metadata #? Stores a series of values useful to effects, changing colors, etc. while not being attatched to the element itself

func _ready() -> void:
	seeking_weight = base_seeking_weight
	speed = base_speed
	damage = base_damage
	lifetime = base_lifetime
	_activate()

func _activate() -> void:
	# init_pos = global_position
	cpu_particles.emitting = true
	AudioManager.emit_random_sound_effect(global_position, sfx_when_launched, "Effects", PITCH_VARIATION)
	
	var lifetime_timer : Timer = Timer.new()
	lifetime_timer.set_process_mode(ProcessMode.PROCESS_MODE_PAUSABLE)
	add_child(lifetime_timer)
	lifetime_timer.start(lifetime)
	await lifetime_timer.timeout # TODO: Personalized timer / distance delta
	_break()

func _deactivate() -> void:
	active = false
	set_visible(false)

func _physics_process(delta) -> void:
	# var distance_delta = global_position.distance_squared_to(init_pos)
	# print(distance_delta)
	match projectile_mode:
		0: #| 'STRAIGHT'
			global_position += Vector2(speed * delta, 0).rotated(rotation)
		1: #| 'SEEKING'
			if is_instance_valid(target): 
				stored_direction = global_position.direction_to(target.global_position)
				var angle = transform.x.angle_to(stored_direction)
				rotate(sign(angle) * min(delta * TAU * 2, abs(angle)))
			else: projectile_mode = 0; return
			global_position += (stored_direction * speed * delta)
		_: push_error('INVALID PROJECTILE_TYPE')

func _on_body_entered(body) -> void:
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
		piercing_count -= 1
		if projectile_mode == 1: projectile_mode = 0
		AudioManager.emit_random_sound_effect(global_position, sfx_when_hit)
	if piercing_count <= 0: _break()

func _clear_projectile_element_metadata() -> void: projectile_effect_metadata = {}

func _set_projectile_effect_metadata(new_metadata : Dictionary) -> void: projectile_effect_metadata = new_metadata

func _break() -> void:
	_deactivate()
	set_physics_process(false)
	AudioManager.emit_random_sound_effect(global_position, sfx_when_broken)
	queue_free()
