## HealthComponent class
# Following composition structure, you can attatch this node, set these properties, and use this as a health manager for every single entity of the game.
# Remember that this node also needs a triggering agent to change health and it doesn't do it on it's own! That's why there's a HitboxComponent.
class_name HealthComponent extends Node

signal health_change(
	previous_value: int, ## Previous health before the change
	new_value: int, ## New health
	type : bool ## Returns true if positive change, false if negative
)
signal health_locked(lock : bool)
signal life_consumed

@export_category("Health Properties")
@export_range(0, 100) var lives : int = 1
@export var max_health : int = 5
# @export_enum('normal', 'shield') var health_type = 'normal'
# @export_enum('entity', 'tower') var entity_type = 'entity'

@export_group('Node Connections')
@export var root_node : Node # Not required to be defined. Attaches to owner by default.

# Health
var health : int:
	set(new_health):
		var previous_value : int = health
		var type : bool = (previous_value - new_health > 0)
		health = clampi(new_health, 0, max_health)
		health_change.emit(previous_value, health, type)

# Main
var lock_health : bool = false:
	set(lock):
		lock_health = lock
		health_locked.emit()
var set_max_health : int:
	set(override):
		max_health = override
		health = override

func _ready():
	if !root_node: root_node = owner
	set_max_health = max_health

func reset_health():
	var previous_value := health
	health_change.emit(previous_value, health, true)

func change(amount : int, negative : bool = true, source = null):
	if amount == 0 or lock_health: return
	var _previous_value : int = health
	
	if negative: health -= amount
	else: health += amount
	if health <= 0: invoke_death(source)

func invoke_death(source):
	if !is_instance_valid(source): return
	if source is Tower: source.tower_kill_count += 1
	
	if lives > 1:
		lives -= 1
		health = max_health
		life_consumed.emit() # Use this signal to create ressurection animations, phase changing and such.
	else:
		lock_health = true
		root_node.die(source) # Let the owner itself execute its death sequence, including queue_free()
