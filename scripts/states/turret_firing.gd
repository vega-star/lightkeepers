## Firing state
# Instantiate projectiles and fire at enemies
# Continues to call functions and update firing status even when inactive, due to being a crucial state.
extends State

const SEEKING_ROTATION_SPEED : float = TAU * 2

@export var seeking_state : State
@export var burst_cooldown_damping : float = 2.5
@export var projectile_mode : int = 1 #? Defaults to seeking
@export var projectile_prop : bool = false
@export var projectile_prop_sprite : Sprite2D
@export var debug : bool = false

@onready var firing_cooldown : Timer = $FiringCooldown

var active : bool = false
var firing : bool = false
var direction : Vector2
var firing_buffered : bool = false
var bullet_container : Node2D

#region State Functions
func _ready() -> void:
	debug = state_machine.debug
	bullet_container = get_tree().get_first_node_in_group('projectile_container')

func enter() -> void:
	active = true
	if firing_buffered:
		firing_cooldown.set_paused(false)
		_start_firing()
		firing_buffered = false

func exit() -> void: active = false

func state_physics_update(delta : float) -> void:
	entity.tower_aim.force_raycast_update()
	if is_instance_valid(entity.target): #? Control firing angle
		direction = entity.tower_gun_sprite.global_position.direction_to(entity.target.global_position)
		entity._rotate_tower(direction, delta)
#endregion

#region Firing
func _check_target() -> bool:
	var valid : bool = (is_instance_valid(entity.target))
	if !valid:
		if debug: print(entity.name, ' stopped firing due to state change or target changed')
		transition.emit(self, seeking_state)
	return valid

func _start_firing() -> void:
	if !firing:
		if debug: print(entity.name, ' has started firing')
		if !active or !_check_target(): #? State is not active anymore, firing will be ready so it starts immediately when a new enemy arrives
			firing_buffered = true
			firing_cooldown.set_paused(true) #? Will unpause after state entered and unbuffered
			_check_target()
			return
		
		firing = true
		if entity.burst > 1:
			firing_cooldown.set_wait_time(entity.firing_cooldown / burst_cooldown_damping)
			for i in entity.burst:
				_fire()
				# firing_cooldown.start()
				await firing_cooldown.timeout
			firing_cooldown.set_wait_time(entity.firing_cooldown)
		else: _fire()
		
		# firing_cooldown.start()
		firing = false
	else: print(entity.name, ' firing called by already firing')

func _fire() -> void:
	var projectile : Projectile = entity.default_projectile.instantiate()
	
	if is_instance_valid(entity.target): 
		projectile.target = entity.target
		if debug: print(entity.name, ' firing at ', entity.target.get_path())
	
	if entity.element_metadata: projectile.projectile_effect_metadata = entity.element_metadata
	if entity.element_metadata.has("root_color"): projectile.modulate = entity.element_metadata["root_color"]
	projectile.projectile_mode = projectile_mode
	projectile.damage = entity.damage
	projectile.source = entity
	projectile.global_position = entity.tower_gun_muzzle.global_position
	projectile.global_rotation = entity.tower_gun_muzzle.global_rotation
	projectile.piercing_count = entity.piercing
	
	bullet_container.call_deferred("add_child", projectile) # add_child(projectile)
	entity.tower_gun_sprite.play()
#endregion
