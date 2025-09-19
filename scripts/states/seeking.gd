## Seeking state
# Seeks and sorts enemies based on priorities, then return the target and starts firing.
# Continues to call functions and interpret signals even when inactive, due to being a crucial state.
extends State

signal enemy_detected(enemy : Enemy)

const ROTATING_TIMEOUT : float = 2
const RANDOM_SEEKING_DAMPENING : int = 5
const BASE_SEEKING_TIMEOUT : float = 0.15

@export var firing_state : State

var sight_detection : bool
var has_sight : bool
var direction : Vector2
var seeking_dampening : int = 1
var randomly_rotating : bool = true
var active : bool = false ## Current active stage
var debug : bool = false

#region State functions
func _ready() -> void:
	assert(firing_state)
	debug = state_machine.debug
	if entity is Tower: entity.tower_detected_enemy.connect(_on_target_entered)
	if entity.prop: await entity.tower_validated

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
			await get_tree().create_timer(ROTATING_TIMEOUT).timeout
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

## Returns nested arrays similar to this: [[enemy, distance]] that can be reordered based on what is required
func sort_targets_by_distance(
		source_array : Array,
		reference_point : Vector2
	) -> Array: 
	
	var available_targets : Array = [] #? Array of custom sorted targets
	for t in source_array.size():
		available_targets.append([
			source_array[t],
			reference_point.distance_squared_to(source_array[t].global_position)]
		)
	available_targets.sort_custom(func(a, b): return a[1] < b[1])
	return available_targets

func _seek_target() -> Node: ## Returns an enemy node that can be targeted by the tower
	if !entity.eligible_targets.size() > 0: return null #? No targets in the pool, cancelling seek
	
	var new_target : Node #? Target that will be returned
	
	match entity.target_priority: ## Fetch target
		0: #? FIRST | Selects the the firstmost target that entered turret range
			new_target = sort_targets_by_distance(entity.eligible_targets, StageManager.active_stage.nexus.global_position)[0][0]
		1: #? LAST | Selects the last target that entered turret range
			new_target = sort_targets_by_distance(entity.eligible_targets, StageManager.active_stage.nexus.global_position)[-1][0]
		2: #? CLOSE | Sorts from the closest to the farthest in relation to tower
			new_target = sort_targets_by_distance(entity.eligible_targets, entity.global_position)[0][0]
		3: #? WEAK | TODO
			new_target = entity.eligible_targets.front()
		4: #? STRONG | TODO
			new_target = entity.eligible_targets.front()
		5: #? FLYING | TODO
			new_target = entity.eligible_targets.front()
		_: push_error('INVALID SEEKING TYPE ON TURRET %s' % self.name)
	
	## Filter target
	if new_target is Enemy:
		var source_effect_eid : int = entity.element_metadata["eid"]
		if new_target.health_component.effect_component.active_eids.has(source_effect_eid) and entity.eligible_targets.size() > 1:
			for t in entity.eligible_targets: ## Deprioritize enemies that already are affected by the tower active debuff
				if t.health_component.effect_component.active_eids.has(source_effect_eid):
					continue
				else: ## Found better target! 
					new_target = t
					break
	
	if debug: print(entity.name, ' is targeting ', new_target.get_path())
	return new_target

func _on_tower_detected_enemy() -> void:
	if debug: print(entity.name, ' seek called due to new enemy entering tower range')
	entity.target = _seek_target()
#endregion
