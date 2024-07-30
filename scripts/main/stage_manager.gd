## StageManager
# MAIN FUNCTION: Manages game events, conditions and such
# ADDITIONAL: Stores and updates pyrite (coins)
class_name StageManager extends Node

signal stage_won
signal stage_lost
signal wave_initiated
signal wave_completed
signal health_updated()
signal coins_updated(previous_coins, coins)

const base_nexus_health : int = 100

# @export_group('Stage Properties')
@export var initial_coins : int = 150
@export var max_turns : int = 30

var nexus : Node
var nexus_health : int = base_nexus_health
var coins : int

func _ready():
	randomize()
	coins = initial_coins
	nexus = get_tree().get_first_node_in_group('nexus')
	UI.HUD.update_coins(coins)
	set_process(false)

func change_coins(quantity : int, addition : bool = false):
	var previous_coins : int = coins
	if addition: coins += quantity
	else: coins -= quantity
	coins_updated.emit(previous_coins, coins)
	UI.HUD.update_coins(coins)

func change_health(quantity : int, addition : bool = false):
	var previous_health : int = nexus_health
	if addition: nexus_health += quantity
	else: nexus_health -= quantity
	nexus_health = clamp(nexus_health, 0, 9999)
	health_updated.emit(previous_health, nexus_health)
	UI.HUD.update_life(nexus_health)

func _on_threat_manager_wave_completed():
	wave_completed.emit()

func _on_health_updated(_previous_health, _nexus_health):
	if nexus_health == 0: stage_lost.emit()
	$"../StageCamera".start_shake()
