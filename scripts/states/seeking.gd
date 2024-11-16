## Seeking state
# Seeks and sorts enemies based on priorities, then return the target and starts firing.
# Continues to call functions and interpret signals even when inactive, due to being a crucial state.
extends State

signal enemy_detected(enemy : Enemy)

const ROTATING_TIMEOUT : float = 2
const RANDOM_SEEKING_DAMPENING : int = 5
const BASE_SEEKING_TIMEOUT : float = 0.15

@export var firing_state : State
@export var debug : bool = false

var sight_detection : bool
var has_sight : bool
var direction : Vector2
var seeking_dampening : int = 1
var randomly_rotating : bool = true
var active : bool = false ## Current active stage

#region State functions
func _ready() -> void:
	assert(firing_state)
	debug = state_machine.debug
	if entity is Tower: entity.tower_detected_enemy.connect(_on_target_entered)

func enter() -> void: active = true; seek()

func exit() -> void: active = false

func state_physics_update(delta : float) -> void:
	if is_instance_valid(entity.target): #? Control firing angle and fire when aiming directly at an enemy
		direction = entity.tower_sprite.global_position.direction_to(entity.target.global_position)
		seeking_dampening = 1
		if active and entity.tower_aim.is_colliding():
			active = false
			transition.emit(self, firing_state)
	else:
		if randomly_rotating:
			randomly_rotating = false
			seeking_dampening = RANDOM_SEEKING_DAMPENING
			direction = Vector2(randf_range(-1,1),randf_range(-1,1))
			await get_tree().create_timer(ROTATING_TIMEOUT).timeout
			seek()
			randomly_rotating  = true
	
	entity._rotate_tower(
		direction,
		delta,
		entity.SEEKING_ROTATION_SPEED / seeking_dampening
	)
#endregion

#region Seek
func _on_target_entered() -> void: if active and !is_instance_valid(entity.target): seek()

func seek() -> void: ## Sets entity target
	if debug: print(entity.name, ' seek called')
	entity.target = _seek_target()
	if !is_instance_valid(entity.target) or !entity.eligible_targets.has(entity.target):
		if debug: print(entity.name, ' is seeking, but current or previous target is not eligible')
		entity.target = null
	else:
		enemy_detected.emit(entity.target)

func _seek_target() -> Node: ## Returns an enemy node that can be targeted by the tower
	if !entity.eligible_targets.size() > 0: return null #? No targets in the pool, cancelling seek
	
	var new_target : Node #? Target that will be returned
	var available_targets : Array = [] #? Array of custom sorted targets
	
	match entity.target_priority:
		0: #? FIRST | Selects the the firstmost target that entered turret range
			new_target = entity.eligible_targets.front()
		1: #? LAST | Selects the last target that entered turret range
			new_target = entity.eligible_targets.back()
		2: #? CLOSE | Sorts from the closest to the farthest in relation to tower
			for t in entity.eligible_targets.size():
				available_targets.append([
					entity.eligible_targets[t],
					entity.global_position.distance_squared_to(entity.eligible_targets[t].global_position)]
				)
			available_targets.sort_custom(func(a, b): return a[1] < b[1])
			new_target = available_targets[0][0]
		3: #? WEAK | #TODO
			for t in entity.eligible_targets.size():
				available_targets.append([entity.eligible_targets[t], entity.nexus_position.distance_squared_to(entity.eligible_targets[t].position)])
			available_targets.sort_custom(func(a, b): return a[1] < b[1])
			new_target = available_targets[0][0]
		4: #? STRONG | #TODO
			for t in entity.eligible_targets.size():
				available_targets.append([entity.eligible_targets[t], entity.nexus_position.distance_squared_to(entity.eligible_targets[t].position)])
			available_targets.sort_custom(func(a, b): return a[1] < b[1])
			new_target = available_targets[0][0]
		_: push_error('INVALID SEEKING TYPE ON TURRET %s' % self.name)
	
	if debug: print(entity.name, ' is targeting ', new_target.get_path())
	return new_target
#endregion
