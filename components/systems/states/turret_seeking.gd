extends State

@export var firing_state : State

const BASE_SEEKING_TIMEOUT : float = 0.5

@onready var target_reset_timer: Timer = $TargetResetTimer

func enter(): 
	target_reset_timer.start()
	target_reset_timer.set_paused(false)
func exit(): target_reset_timer.set_paused(true)

func _ready() -> void:
	target_reset_timer.wait_time = BASE_SEEKING_TIMEOUT

func _seek_target() -> Node:
	var new_target : Object
	var available_targets : Array = []
	match entity.seeking_type:
		0: #? Nearest
			for t in entity.eligible_targets.size():
				available_targets.append([entity.eligible_targets[t], entity.nexus_position.distance_squared_to(entity.eligible_targets[t].position)])
			available_targets.sort_custom(func(a, b): return a[1] < b[1]) #? Sorts the array from the closest to the farthest in relation to nexus
		1: #? Closest
			for t in entity.eligible_targets.size():
				if entity.eligible_targets[t].line_agent: available_targets.append([entity.eligible_targets[t], entity.eligible_targets[t].line_agent.progress]) #? Is following a Line2D
				else: available_targets.append([entity.eligible_targets[t], entity.position.distance_squared_to(entity.eligible_targets[t].position)]) #? Is guiding itself with NavigationAgent
			available_targets.sort_custom(func(a, b): return a[1] < b[1]) #? Sorts the array from the closest to the farthest in relation to tower
		2: #? Farthest
			for t in entity.eligible_targets.size():
				if entity.eligible_targets[t].line_agent: available_targets.append([entity.eligible_targets[t], entity.eligible_targets[t].line_agent.progress])
				else: available_targets.append([entity.eligible_targets[t], entity.nexus_position.distance_squared_to(entity.eligible_targets[t].position)])
			available_targets.sort_custom(func(a, b): return a[1] > b[1]) #? Sorts the array from the farthest to the closest in relation to nexus
		3: #? Strongest #TODO
			pass
		4: #? Target #TODO
			pass
		_: push_error('INVALID SEEKING TYPE ON TURRET %s' % self.name)
	new_target = available_targets[0][0]
	return new_target #? Returns the first target in array

func _on_target_reset() -> void: 
	target_reset_timer.wait_time = entity.seeking_timeout
	
	if entity.eligible_targets.size() > 0: entity.target = _seek_target()
	else: entity.target = null
	
	if is_instance_valid(entity.target):
		target_reset_timer.set_paused(true)
		transition.emit(self, firing_state)
