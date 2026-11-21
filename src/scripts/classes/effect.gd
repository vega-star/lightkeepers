## Effect
# A resource that contains information and activity of an effect that can be beneficial or not
# Mostly containing damaging effects such as burn or shock, that HealthComponent will receive as proc_effect call
class_name Effect extends Resource

signal effect_started(self_ref : Effect)
signal effect_expired(self_ref : Effect)

## Activation variables and references
var eid : int
var edata : Dictionary
var stacks : int = 1 #? Used when an effect is stackable
var duration_timer : Timer
var tick_timer : Timer
var health_ref : HealthComponent
var source : Node
var times_applied : int

func proc() -> void:
	times_applied += 1
	health_ref.effect_component.compute_effect(self)

func activate(
		_eid : int, ## Identifiable number
		_edata : Dictionary, ## Effect values
		_duration_timer : Timer, ## Duration timer node
		_tick_timer : Timer, ## Tick timer node
		_health_ref : HealthComponent, ## HealthComponent node connection on which effect will call
		_source : Node, ## Source that caused the effect
	) -> void:
	eid = _eid
	edata = _edata
	health_ref = _health_ref
	duration_timer = _duration_timer
	tick_timer = _tick_timer
	if is_instance_valid(_source): source = _source
	duration_timer.timeout.connect(deactivate)
	tick_timer.timeout.connect(proc)
	effect_started.emit(self)
	proc()

func reset_duration() -> void: duration_timer.start(edata["duration"])

func deactivate() -> void:
	if stacks > 1 and edata["stackable"]:
		stacks -= 1
		reset_duration()
		return
	effect_expired.emit(self)
	tick_timer.queue_free()
	duration_timer.queue_free()
	health_ref.effect_component.remove_effect(self)
