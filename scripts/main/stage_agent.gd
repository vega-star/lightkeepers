## StageAgent
# MAIN FUNCTION: Manages game events and conditions
# ADDITIONAL: Stores and updates health and coins
class_name StageAgent extends Node

signal stage_won
signal stage_lost
signal turn_passed(previous_turn, next_turn_metadata)

signal wave_initiated
signal wave_completed
signal health_updated()
signal coins_updated(previous_coins : int, coins : int)

const BASE_N_HEALTH : int = 100 #? Default nexus health

# @export_group('Stage Properties')
@export var initial_coins : int = 500

@onready var turn_manager : TurnManager = $TurnManager

var coins : int
var nexus : Node
var nexus_health : int = BASE_N_HEALTH

#region Main functions
func _ready() -> void:
	randomize()
	coins = initial_coins
	nexus = get_tree().get_first_node_in_group('nexus')
	turn_manager.schedule_finished.connect(close_stage.bind(true))
	UI.HUD.update_coins(coins)
	set_process(false)

## Invoke stage ended screen depending on the boolean given. If false, game over is shown.
func close_stage(success : bool = true):
	if success:
		print('STAGE ENDED | SUCCESS!')
	else:
		print('STAGE ENDED | FAILURE')
#endregion

#region Runtime stage functions
func change_coins(quantity : int, addition : bool = false) -> void:
	var previous_coins : int = coins
	if addition: coins += quantity
	else: coins -= quantity
	coins_updated.emit(previous_coins, coins)
	UI.HUD.update_coins(coins)

func change_health(quantity : int, addition : bool = false) -> void:
	var previous_health : int = nexus_health
	if addition: nexus_health += quantity
	else: nexus_health -= quantity
	nexus_health = clamp(nexus_health, 0, 9999)
	health_updated.emit(previous_health, nexus_health)
	UI.HUD.update_life(nexus_health)

func _on_threat_manager_wave_completed() -> void: wave_completed.emit()

func _on_health_updated(_previous_health, _nexus_health) -> void:
	if nexus_health == 0: stage_lost.emit()
	$"../StageCamera".start_shake()
#endregion
