class_name Wave extends Resource
## Wave Resource
##
## Serve as a foundation for enemy spawning
## Defines a quantifiable series of a certain enemy and the timeout period for each spawning

## Direct path to enemy scene. Is loaded by WaveManager directly with subthreads.
@export var enemy_scene_path : String

## Precise quantity of enemy spawns
@export_range(0, 1000) var quantity : int = 1

## Defines cooldown to each enemy spawn
@export var spawn_cooldown : float = 0.8

## Optional parameter. Defaults to complete wave duration. When period ends, WaveManager will start another wave
@export var override_wave_period : float

var wave_period : float

func _init() -> void: call_deferred("ready")

func _get_wave_period() -> float: return (spawn_cooldown * quantity)

func ready():
	if !override_wave_period: wave_period = _get_wave_period()
	else: wave_period = override_wave_period
