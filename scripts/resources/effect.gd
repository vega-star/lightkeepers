## Effect
# A resource that contains information and activity of an effect that can be beneficial or not
# Mostly containing damaging effects such as burn or shock, that HealthComponent will receive as proc_effect call
class_name Effect extends Resource

signal effect_started
signal effect_expired(self_ref : Effect)

## Activation variables and references
var eid : int
var level : int = 0
var stacks : int = 1 #? Used when an effect is stackable
var total_duration : float
var duration_timer : Timer
var tick_timer : Timer
var health_ref : HealthComponent
var source : Tower

## Instantiated variables
var effect : Dictionary

func activate(
		new_eid : int, ## Identifiable number
		new_effect : Dictionary, ## Effect values
		duration : int, ## How many seconds the effect will apply
		tick : float, ## Period on which the effect will process
		_new_duration_timer : Timer, ## Duration timer node connection
		_new_tick_timer : Timer, ## Tick timer node connection
		_new_health_ref : HealthComponent, ## HealthComponent node connection on which effect will call
		new_source : Tower ## tower that caused the effect
	) -> void:
	eid = new_eid
	effect = new_effect
	source = new_source
	total_duration = duration
	health_ref = _new_health_ref
	duration_timer = _new_duration_timer
	tick_timer = _new_tick_timer
	duration_timer.timeout.connect(deactivate)
	tick_timer.timeout.connect(proc)
	duration_timer.start()
	tick_timer.start()
	effect_started.emit()
	proc()

func proc() -> void: health_ref.effect_component.proc_effect(self)

func reset_duration(duration : int = total_duration) -> void:
	if duration_timer: duration_timer.start(duration)

func deactivate() -> void:
	if stacks > 1 and effect["stackable"]: stacks -= 1; reset_duration(); return
	effect_expired.emit(self)
	tick_timer.queue_free()
	duration_timer.queue_free()
	health_ref.effect_component.remove_effect(self)
