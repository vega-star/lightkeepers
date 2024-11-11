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
@export var lives : int = 1
@export var max_health : int = 5
@export var print_change : bool = false

@export_group('Node Connections')
@export var root_node : Node # Optional. Attaches to scene owner by default.
@onready var effect_component : EffectComponent = $EffectComponent

var health : int: set = _set_health
var damage_multiplier : float = 1
var lock_health : bool = false:
	set(lock): lock_health = lock; health_locked.emit()
var set_max_health : int:
	set(override): max_health = override; health = override

#region Main functions
func _ready() -> void: if !root_node: root_node = owner; set_max_health = max_health

func _set_health(new_health : int) -> void:
	var previous_value : int = health
	var type : bool = (previous_value - new_health > 0)
	health = clampi(new_health, 0, max_health)
	health_change.emit(previous_value, health, type)
#endregion

#region Active callables
func reset_health() -> void: health = max_health

func change(amount : int, negative : bool = true, source : Pupil = null) -> void:
	var _previous_value : int = health
	var _change_source : Pupil = null
	if is_instance_valid(source): _change_source = source
	if amount == 0 or lock_health: return #? No change is made or is allowed
	if negative: health -= amount * damage_multiplier
	else: health += amount
	if health <= 0: invoke_death(_change_source)
	if print_change: print(owner.name, ' health changed from ', _previous_value, ' to ', health)
	health_change.emit(_previous_value, health, negative)

func invoke_death(source : Node) -> void:
	if !is_instance_valid(source): return
	if source is Pupil: source.pupil_kill_count += 1
	
	if lives > 1:
		lives -= 1
		reset_health()
		life_consumed.emit() # Use this signal to create ressurection animations, phase changing and such.
	else:
		lock_health = true
		root_node.die(source) # Let the owner itself execute its death sequence, including queue_free()
#endregion
