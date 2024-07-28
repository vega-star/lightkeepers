class_name Projectile extends Node2D

@export_enum('STRAIGHT_SHOT', 'SEEKING_SHOT') var projectile_type : String = 'SEEKING_SHOT' ## Affects processes and movement
@export var base_speed : int = 600
@export var base_piercing : int = 1
@export var base_damage : int = 5
@export var base_seeking_weight : float = 0.5

var target : Object
var speed : int
var damage : int
var piercing_count : int
var seeking_weight : float

func _ready():
	seeking_weight = base_seeking_weight
	speed = base_speed
	damage = base_damage
	piercing_count = base_piercing

func _physics_process(delta):
	match projectile_type:
		'STRAIGHT_SHOT': 
			global_position += Vector2(speed * delta,0).rotated(rotation)
		'SEEKING_SHOT':
			if is_instance_valid(target): look_at(target.global_position)
			else: projectile_type = 'STRAIGHT_SHOT'; return
			global_position += Vector2(speed * delta, 0).rotated(rotation)

func _on_body_entered(body):
	if body is Enemy:
		body.health_component.change(damage, true, self)
		piercing_count -= 1
	if piercing_count == 0: queue_free()
