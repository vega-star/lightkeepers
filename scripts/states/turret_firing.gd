extends State

@export var seeking_state : State
@export var burst_cooldown_damping : float = 2.5
@export var needs_line_of_sight : bool = true
@export var projectile_prop : bool = false
@export var projectile_prop_sprite : Sprite2D

@onready var firing_cooldown : Timer = $FiringCooldown

var active : bool = false
var firing_buffered : bool = false
var bullet_container : Node2D
var cast_point : Vector2

func _ready() -> void:
	firing_cooldown.start()
	bullet_container = get_tree().get_first_node_in_group('projectile_container')

func enter() -> void: 
	active = true
	if firing_buffered: _fire(); firing_buffered = false
	firing_cooldown.start()

func exit() -> void:
	active = false

func state_physics_update(delta : float) -> void:
	entity.tower_aim.force_raycast_update()
	
	if is_instance_valid(entity.target): #? Control firing angle
		cast_point = entity.target.global_position
		entity.tower_gun_sprite.look_at(cast_point)
		entity.tower_sprite.look_at(cast_point)
	else:
		transition.emit(self, seeking_state)
	
	if entity.tower_aim.is_colliding(): #? Control collision point and firing cooldown
		if needs_line_of_sight: firing_cooldown.paused = false
		cast_point = entity.to_local(entity.tower_aim.get_collision_point())
	else:
		if needs_line_of_sight: firing_cooldown.paused = true

func _fire() -> void:
	if projectile_prop_sprite: projectile_prop_sprite.visible = false
	
	var projectile = entity.base_projectile.instantiate()
	projectile.position = entity.tower_gun_muzzle.global_position
	projectile.rotation_degrees = entity.tower_gun_sprite.rotation_degrees
	projectile.piercing_count = entity.piercing
	if is_instance_valid(entity.target): projectile.target = entity.target
	projectile.damage = entity.damage
	projectile.source = entity
	entity.tower_gun_sprite.play()
	bullet_container.add_child(projectile)
	
	if projectile_prop_sprite: 
		await get_tree().create_timer(entity.firing_cooldown / burst_cooldown_damping).timeout
		projectile_prop_sprite.visible = true

func _on_firing_cooldown_available() -> void:
	if !active: firing_buffered = true; return
	
	if entity.base_burst > 1:
		firing_cooldown.set_wait_time(entity.firing_cooldown / burst_cooldown_damping)
		for i in entity.base_burst:
			firing_cooldown.start()
			_fire()
			await firing_cooldown.timeout
		firing_cooldown.set_wait_time(entity.firing_cooldown)
	else: _fire()
	
	firing_cooldown.start()
	transition.emit(self, seeking_state)
