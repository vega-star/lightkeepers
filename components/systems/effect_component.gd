class_name EffectComponent extends Node

@onready var entity : Node = $"../.."
@onready var health_component: HealthComponent = $".."

var cached_effect : Effect
var active_eids : Array[int] #w Quicker to query than individual nodes
var active_effects : Array[Effect]

func _ready() -> void: assert(health_component)

func apply_effect(eid : int, metadata : Dictionary, source : Tower) -> bool: ## Create, start, and manage effect
	var e_metadata : Dictionary = metadata
	var magic_level : int = source.magic_level
	
	if metadata.has("effect_metadata"):
		if metadata["effect_metadata"] is Dictionary: e_metadata = metadata["effect_metadata"] #? Single effect
		elif metadata["effect_metadata"] is Array: for e in metadata["effect_metadata"]: apply_effect(eid, e, source); return true #? Multiple effects nested
	
	if health_component.debug: print(owner.root_node.name, ' | Effect applied: ', e_metadata)
	if active_eids.has(eid):
		var a_effect : Effect
		for e in active_effects: if e.eid == eid: a_effect = e
		a_effect.reset_duration()
		if e_metadata.has("stackable"):
			if e_metadata["stackable"]: #? Add stacks to the same effect, increasing its strength
				var multiplier : int = 1
				if e_metadata.has("stack_multiplier"): multiplier = e_metadata["stack_multiplier"] * magic_level
				a_effect.stacks += 1 * multiplier
				return true
		else: return true #? The effect cannot stack, but is duration will be reset
	
	var effect : Effect = Effect.new()
	var duration_timer : Timer = Timer.new()
	var tick_timer : Timer = Timer.new()
	
	if e_metadata.has("duration"):
		duration_timer.set_process_mode(Node.PROCESS_MODE_PAUSABLE)
		duration_timer.set_wait_time(e_metadata["duration"])
		add_child(duration_timer); duration_timer.set_name(e_metadata["ename"].to_lower() + "_duration")
	
	if e_metadata.has("tick"):
		tick_timer.set_process_mode(Node.PROCESS_MODE_PAUSABLE)
		tick_timer.set_wait_time(e_metadata["tick"])
		duration_timer.add_child(tick_timer); tick_timer.set_name(e_metadata["ename"].to_lower() + "_tick")
	
	effect.level = magic_level
	effect.activate(eid, e_metadata, 1, 1, duration_timer, tick_timer, health_component, source)
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
	match int(e_dict["etype"]):
		000: # DEBUG
			print(e_dict["message"])
		001: # DAMAGE_PER_TICK
			if !apply: return
			var d_value : int = roundi(e_dict["value"] * e_ref.level)
			if e_dict["stackable"] and e_ref.stacks > 1: d_value *= e_ref.stacks
			if health_component.debug: print(e_dict["ename"], '| Damaging ', owner.root_node.name, ' with ', d_value, ' multiplied by ', e_ref.stacks, ' stacks')
			
			if is_instance_valid(e_source): health_component.change(d_value, apply, e_ref.source)
			else: health_component.change(d_value, apply)
		002: pass # ADD_VULNERABILITY
		003: # SPEED MODIFY
			var d_multiplier : float = e_dict["value_multiplier"]
			if apply: entity.speed * float(d_multiplier)
			else: entity.speed / float(d_multiplier)
			if health_component.debug: print(e_dict["ename"], ' | Modifying enemy movement speed by ', str(d_multiplier))
		004: pass # PROJECTILE_CHANGE
		005: pass # TOWER_CHANGE
		005: pass # CONDITIONAL_PROC
		_: push_error(owner.root_node.name, " EffectComponent | INVALID E_TYPE")
