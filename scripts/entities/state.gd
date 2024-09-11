extends Node
class_name State

## State
# Serves as a template and basis for entity states, that are children to a StateMachine. 
# States are used to control enemy behavior without cluttering and hardcoding it, and can be used by multiple enemies!
# The foundations of it are explained wonderfully by Bitlytic, check its tutorial below:
# Source: https://www.youtube.com/watch?v=ow_Lum-Agbs
#
# REMEMBER TO EXTEND THIS SCRIPT INSTEAD OF USING IT DIRECTLY ON A NODE!!!

signal transition(current_state, new_state_name)

@onready var state_machine : StateMachine = get_parent()
@onready var entity : Node = state_machine.entity
@onready var conditions : Dictionary = state_machine.state_conditions

func enter() -> void:
	pass

func exit() -> void:
	pass

func state_update(_delta : float) -> void:
	pass

func state_physics_update(_delta : float) -> void:
	pass
