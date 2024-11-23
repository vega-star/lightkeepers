class_name EffectComponent extends Node

signal effect_started
signal effect_expired(self_ref : Effect)

@onready var entity : Node = $"../.."
@onready var health_component: HealthComponent = $".."

var cached_effect : Effect
var active_eids : Array[int] #w Quicker to query than individual nodes
var active_effects : Array[Effect]

func _ready() -> void: assert(health_component)

## Create, start, and manage effect
func apply_effect(
		eid : int, ## Effect ID
		element_data : Dictionary, ## All requested data
		source : Tower ## From where the effect comes from
	) -> bool: #? Returns true if applied
	var effect_data : Dictionary = element_data
	var magic_level : int = 1
	if source: magic_level = source.magic_level
	
	if element_data.has("effect_metadata"):
		if element_data["effect_metadata"] is Dictionary: #? Single effect
			effect_data = element_data["effect_metadata"]
		elif element_data["effect_metadata"] is Array: for e in element_data["effect_metadata"]: #? Multiple effects nested
			apply_effect(eid, e, source); return true
	else: return false #? No effect element_data given
	
	if health_component.debug: print(owner.root_node.name, ' | Effect applied: ', effect_data)
	if active_eids.has(eid):
		var a_effect : Effect
		for e in active_effects: if e.eid == eid: a_effect = e
		a_effect.reset_duration()
		if effect_data.has("stackable"):
			if effect_data["stackable"]: #? Add stacks to the same effect, increasing its strength
				var multiplier : int = 1
				if effect_data.has("stack_multiplier"): multiplier = effect_data["stack_multiplier"] * magic_level
				a_effect.stacks += 1 * multiplier
				return true
		else: return true #? The effect cannot stack, but is duration will be reset
	
	var duration_timer = Timer.new()
	duration_timer.set_one_shot(true)
	duration_timer.set_wait_time(effect_data["duration"])
	duration_timer.set_name(str(eid)+"_DURATION")
	add_child(duration_timer)
	var tick_timer = Timer.new()
	tick_timer.set_name(str(eid)+"_TICK")
	duration_timer.add_child(tick_timer)
	
	var effect : Effect = Effect.new()
	effect.level = magic_level
	effect.activate(eid, effect_data, 1, 1, duration_timer, tick_timer, health_component, source)
	active_effects.append(effect)
	active_eids.append(eid)
	return true

func remove_effect(self_ref : Effect) -> void:
	compute_effect(self_ref, false)
	active_effects.erase(self_ref)
	active_eids.erase(self_ref.eid)

## Process effects based on values inside dictionary and individual etypes.
func proc_effect(e_ref : Effect) -> void: compute_effect(e_ref) ## Receive and apply effect

func compute_effect(
		e_ref : Effect, ## Source effect with multiple properties defined
		apply : bool = true ## If false, will cancel out the effect. Used to remove multipliers and such
	) -> void:
	var e_dict : Dictionary = e_ref.effect
	var e_source : Tower = e_ref.source
	if !apply and health_component.debug: print(e_dict["ename"], ' | EFFECT ENDED')
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
