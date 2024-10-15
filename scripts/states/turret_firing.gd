extends State

const ROTATION_ADDER : float = 20

@export var seeking_state : State
@export var burst_cooldown_damping : float = 1.8
@export var projectile_mode : int = 1 #? Defaults to seeking
@export var projectile_prop : bool = false
@export var projectile_prop_sprite : Sprite2D

@onready var firing_cooldown : Timer = $FiringCooldown

var active : bool = false
var firing_buffered : bool = false
var bullet_container : Node2D
var cast_point : Vector2

#region State Functions
func _ready() -> void:
	bullet_container = get_tree().get_first_node_in_group('projectile_container')

func enter() -> void: 
	active = true
	firing_cooldown.set_paused(false)
	if firing_buffered: _start_firing(); firing_buffered = false

func exit() -> void: active = false

func state_physics_update(_delta : float) -> void:
	entity.tower_aim.force_raycast_update()
	if is_instance_valid(entity.target): #? Control firing angle
		entity.tower_gun_sprite.look_at(entity.target.global_position)
		entity.tower_sprite.look_at(entity.target.global_position)
#endregion

#region Firing
func check_target() -> bool:
	if !is_instance_valid(entity.target) or !entity.eligible_targets.has(entity.target): active = false; return false
	else: return true

func _start_firing() -> void:
	if !active: #? State is not active anymore, firing will be ready so it starts immediately when a new enemy arrives
		firing_buffered = true
		firing_cooldown.set_paused(true)
		transition.emit(self, seeking_state)
		return
	else: check_target()
	
	if entity.burst > 1:
		firing_cooldown.set_wait_time(entity.firing_cooldown / burst_cooldown_damping)
		for i in entity.burst:
			_fire(); firing_cooldown.start()
			await firing_cooldown.timeout
		firing_cooldown.set_wait_time(entity.firing_cooldown); firing_cooldown.start()
	else: _fire(); firing_cooldown.start()

func _fire() -> void:
	if projectile_prop_sprite: projectile_prop_sprite.visible = false
	var projectile : Projectile = entity.default_projectile.instantiate()
	
	if is_instance_valid(entity.target): projectile.target = entity.target
	if entity.element_metadata.has("effect_metadata"): projectile.projectile_effect_metadata = entity.element_metadata["effect_metadata"]
	if entity.element_metadata.has("root_color"): projectile.modulate = entity.element_metadata["root_color"]
	projectile.projectile_mode = projectile_mode
	projectile.damage = entity.damage
	projectile.source = entity
	projectile.global_position = entity.tower_gun_muzzle.global_position
	projectile.global_rotation = entity.tower_gun_muzzle.global_rotation
	projectile.piercing_count = entity.piercing
	
	bullet_container.call_deferred("add_child", projectile) # add_child(projectile)
	entity.tower_gun_sprite.play()
	
	if projectile_prop_sprite: 
		await get_tree().create_timer(entity.firing_cooldown / burst_cooldown_damping).timeout
		projectile_prop_sprite.visible = true
#endregion
