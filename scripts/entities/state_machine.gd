extends Node
class_name StateMachine

## StateMachine
# Serves as a container for multiple states used by an entity to inherit behavior.
# It provides updates to a selected state and manages smooth transitions between them.
# The foundations of it are explained wonderfully by Bitlytic, check its tutorial below:
# Source: https://www.youtube.com/watch?v=ow_Lum-Agbs
#
# HOW TO USE:
# This state machine is modified and different from its source material, so if you're intending to use this state machine in your project, please read:
# States have 4 main functions: enter, exit, state_update, and state_physics_update
# 
# 1 - Create a state node for each desired behavior (don't forget to make the script unique or extend it!)
# 2 - Plan your behavior and create functions as desired. 
#     	If you've already created these behaviors hardcoding it in your enemy code, it's easy to extract those lines and convert into states. Try it!
# 3 - Plan your conditionals. When transitioning from a state to other, you can declare conditionals for your active state to check, and decide what to do after.
#     	Ideally, these conditionals are string keys with boolean values stored in the state_conditions dictionary.
# 4 - Be creative! You can design complex and modular behaviors to use in a variety of enemies simultaneously. (I'll make sure to leave some examples for you to try on)

@export var entity : Node
@export var initial_state : State
@export var initial_state_conditions : Dictionary
@export var debug : bool = false

var current_state : State
var states : Array[State]
var state_conditions : Dictionary = initial_state_conditions

func _ready() -> void:
	if !entity: entity = owner
	
	for child in get_children():
		if child is State:
			states.append(child)
			child.transition.connect(_on_child_transition)
	
	if !entity.is_node_ready(): await entity.ready
	
	if initial_state:
		initial_state.enter()
		current_state = initial_state
	else:
		states[0].enter()
		current_state = initial_state

## Upgrades current state _process
func _process(delta : float) -> void: if current_state: current_state.state_update(delta)

## Upgrades current state _physics_process
func _physics_process(delta : float) -> void: if current_state: current_state.state_physics_update(delta)

func _on_child_transition(previous_state : State, next_state : State) -> void:
	assert(previous_state); assert(next_state)
	if debug: print('STATE MACHINE | {0} TRANSITIONING STATE FROM {1} TO {2}'.format({0: owner.name, 1:previous_state.name, 2:next_state.name}))
	current_state.exit()
	next_state.enter()
	current_state = next_state

func change_conditional(key : Variant, value : Variant) -> void:
	if debug: print('STATE MACHINE | {2} CONDITION CHANGED: {0} | {1}'.format({0: key, 1: value, 2: owner.name}))
	state_conditions[key] = value

func is_active_state(state : State) -> bool: return (state == current_state) 
