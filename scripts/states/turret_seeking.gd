## Seeking state
# Seeks and sorts enemies based on priorities, then return the target and starts firing
extends State

const BASE_SEEKING_TIMEOUT : float = 0.15

@export var firing_state : State

var sight_detection : bool
var has_sight : bool
var active : bool = false ## Current active stage

#region State functions
func _ready() -> void:
	assert(firing_state)
	if entity is Tower: entity.tower_detected_enemy.connect(_on_target_entered)

func enter() -> void: active = true; seek()

func exit() -> void: active = false

func state_physics_update(delta : float) -> void:
	if is_instance_valid(entity.target): #? Control firing angle
		entity.tower_gun_sprite.look_at(entity.target.global_position)
		entity.tower_sprite.look_at(entity.target.global_position)
		
		sight_detection = (entity.tower_aim.get_collider() == entity.target)
		if active and sight_detection:
			active = false
			transition.emit(self, firing_state)
#endregion

#region Seek
func _on_target_entered() -> void: if active: seek()

func seek() -> void:
	entity.target = _seek_target()
	if !is_instance_valid(entity.target) or !entity.eligible_targets.has(entity.target): return #? Invalid. Still listening

## Returns an enemy node that can be targeted by the tower
func _seek_target() -> Node:
	var new_target : Node
	var available_targets : Array = []
	
	if entity.eligible_targets.size() > 0: pass
	else: return null #? No targets in the pool
	
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
	return new_target
#endregion
