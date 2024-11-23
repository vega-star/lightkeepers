class_name Projectile extends Node2D

signal charge_completed

enum PROJECTILE_MODES {
	STRAIGHT,
	SEEKING
}

const MAX_TRAIL_LENGTH : int = 10
const PITCH_VARIATION : Vector2 = Vector2(0.7,1.3)

@export_group('Projectile Properties')
@export var speed : int = 300
@export var charge_time : float = 1.5
@export var charge_before_firing : bool = false
@export var projectile_mode : PROJECTILE_MODES = 0 ## Affects processes and movement

@export_group('Cosmetic Properties')
@export var rotate_sprite : bool = false
@export var rotation_speed : float = 25
@export var sfx_when_launched : Array[String]
@export var sfx_when_hit : Array[String]
@export var sfx_when_broken : Array[String]

# @onready var projectile_sound = $ProjectileSound
@onready var cpu_particles : CPUParticles2D = $CPUParticles2D
@onready var projectile_trace : Line2D = $Separator/ProjectileTrace
@onready var projectile_sprite: Sprite2D = $ProjectileSprite

var max_distance : float: #? Max distance in pixels squared. Gets set by tower range
	set(new_distance):
		max_distance = pow(new_distance, 2) 

var projectile_strength : int = 1 #? Not related to damage, but to effects and cosmetics
var active : bool = true
var source : Object
var target : Object
var damage : int = 1
var piercing_count : int = 1
var seeking_weight : float = 0.5
var stored_scale : Vector2
var stored_direction : Vector2
var init_pos : Vector2
var charged : bool = false
var charge_time_multiplier : float = 1
var additional_distance_multiplier : float = 1

var trail_points : Array
var projectile_element_metadata : Dictionary: set = _set_projectile_element_metadata #? Stores a series of values useful to effects, changing colors, etc. while not being attatched to the element itself

func _ready() -> void: _activate()

func _activate() -> void:
	AudioManager.emit_random_sound_effect(global_position, sfx_when_launched, "Effects", PITCH_VARIATION)
	cpu_particles.emitting = true
	init_pos = global_position
	stored_scale = scale
	if charge_before_firing:
		set_physics_process(false)
		_charge()
		await charge_completed
		set_physics_process(true)

func _charge() -> void:
	scale = Vector2.ZERO
	var charge_tween : Tween = get_tree().create_tween().set_ease(Tween.EASE_IN)
	charge_tween.tween_property(self, "scale", stored_scale, charge_time * charge_time_multiplier)
	await charge_tween.finished
	charge_completed.emit()

func _deactivate() -> void:
	active = false
	set_visible(false)

func _physics_process(delta) -> void:
	var distance_delta = global_position.distance_squared_to(init_pos)
	
	trail_points.push_front(global_position)
	if trail_points.size() >= MAX_TRAIL_LENGTH: trail_points.pop_back()
	projectile_trace.clear_points()
	for point in trail_points:
		projectile_trace.add_point(point)
	
	if projectile_mode == 1 and is_instance_valid(target): 
		stored_direction = global_position.direction_to(target.global_position)
		var angle = transform.x.angle_to(stored_direction)
		rotate(sign(angle) * min(delta * TAU * 2, abs(angle)))
	
	if rotate_sprite:
		projectile_sprite.rotation += rotation_speed * (PI * delta)
	
	if active: ## Projectile movement
		match projectile_mode:
			0: #| 'STRAIGHT'
				global_position += Vector2(speed * delta, 0).rotated(rotation)
			1: #| 'SEEKING'
				if !is_instance_valid(target) and source:
					if !is_instance_valid(source.target): projectile_mode = 0; return
					target = source.target
				global_position += (stored_direction * speed * delta)
			_: push_error('INVALID PROJECTILE_TYPE')
	
	if distance_delta > max_distance * additional_distance_multiplier: _break()

func _on_body_entered(body) -> void:
	if !active: return
	
	if body is Enemy:
		var loaded_source : Object
		if is_instance_valid(source):
			loaded_source = source
			body.health_component.change(damage, true, source)
		else: body.health_component.change(damage, true)
		if !projectile_element_metadata.is_empty():
			body.health_component.effect_component.apply_effect(
				projectile_element_metadata["eid"],
				projectile_element_metadata,
				loaded_source
			)
		piercing_count -= 1
		if projectile_mode == 1: projectile_mode = 0
		AudioManager.emit_random_sound_effect(global_position, sfx_when_hit)
	if piercing_count <= 0: _break()

func _clear_projectile_element_metadata() -> void: projectile_element_metadata = {}

func _set_projectile_element_metadata(new_metadata : Dictionary) -> void: projectile_element_metadata = new_metadata

func _break() -> void:
	AudioManager.emit_random_sound_effect(global_position, sfx_when_broken)
	var break_tween : Tween = get_tree().create_tween().set_ease(Tween.EASE_OUT)
	break_tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.7)
	await break_tween.finished
	_deactivate()
	set_physics_process(false)
	queue_free()
