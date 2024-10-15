class_name EffectComponent extends Node

@onready var health_component: HealthComponent = $".."

var active_eids : Array[int] #w Quicker to query than individual nodes
var active_effects : Array[Effect]

func _ready() -> void: assert(health_component)

func apply_effect(metadata : Dictionary, source : Tower) -> bool: ## Create, start, and manage effect
	var eid : int = metadata["eid"]
	print(owner.name, '| Effect applied\r', metadata)
	if active_eids.has(eid):
		print('Effect is already active! Merging it')
		var a_effect : Effect
		for e in active_effects: if e.eid == eid: a_effect = e
		a_effect.reset_duration()
		if metadata["stackable"]: a_effect.stacks += 1; return true #? Add stacks to the same effect, increasing its strength
		else: return true #? The effect cannot stack, but is duration will be reset
	
	var effect : Effect = Effect.new()
	var duration_timer : Timer = Timer.new()
	var tick_timer : Timer = Timer.new()
	
	duration_timer.set_process_mode(Node.PROCESS_MODE_PAUSABLE)
	tick_timer.set_process_mode(Node.PROCESS_MODE_PAUSABLE)
	duration_timer.set_wait_time(metadata["duration"])
	tick_timer.set_wait_time(metadata["tick"])
	
	add_child(duration_timer); duration_timer.set_name(str(eid) + "_duration")
	duration_timer.add_child(tick_timer); tick_timer.set_name(str(eid) + "_tick")
	
	effect.activate(metadata, 1, 1, duration_timer, tick_timer, health_component, source)
	active_effects.append(effect)
	active_eids.append(eid)
	return true

func proc_effect(e_ref : Effect) -> void: compute_effect(e_ref) ## Receive and apply effect

func remove_effect(self_ref : Effect) -> void:
	compute_effect(self_ref, false)
	active_effects.erase(self_ref)
	active_eids.erase(self_ref.eid)

## Process effects based on values inside dictionary and individual etypes.
func compute_effect(
		e_ref : Effect,
		apply : bool = true ## If false, will cancel out the effect. Used to remove multipliers and such
	) -> void:
	var e_dict : Dictionary = e_ref.effect
	var e_source : Tower = e_ref.source
	match e_dict["etype"]:
		000: print("{0} EffectComponent | Apply mode: {1} | EFFECT:\r{2}".format({0:owner, 1: apply, 2: e_dict})) # DEBUG
		001: # DAMAGE | Canceling would cause a healing effect
			if !apply: return
			var d_value : int = roundi(e_dict["value"] * (e_dict["value_multiplier"] * e_dict["level"]))
			if e_dict["stackable"] and e_ref.stacks > 1: d_value *= e_ref.stacks
			print('Damaing ', owner.name, ' with ', d_value)
			if is_instance_valid(e_source): health_component.change(d_value, apply, e_ref.source)
			else: health_component.change(d_value, apply)
		002: pass # ADD_VULNERABILITY
		003: pass # MOVEMENT_CHANGE
		004: pass # PASSIVE_HEAL
