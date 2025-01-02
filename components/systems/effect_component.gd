class_name EffectComponent extends Node

@onready var entity : Node = $"../.."
@onready var health_component : HealthComponent = $".."

var active_eids : Array[int] #? Quicker to query than individual nodes
var active_effects : Array[Effect]

func _ready() -> void: assert(health_component)

## Create, start, and manage effect
func apply_effect(
		eid : int, ## Effect ID
		element_data : Dictionary, ## All requested data
		source : Tower ## From where the effect comes from
	) -> bool: #? Returns true if applied
	
	var edata : Dictionary = element_data
	
	if element_data.has("effect_metadata"):
		if element_data["effect_metadata"] is Dictionary: #? Single effect
			edata = element_data["effect_metadata"]
		elif element_data["effect_metadata"] is Array:
			#? Recursion due to multiple effects
			var effect_result : bool
			for e in element_data["effect_metadata"]:
				print(entity.get_instance_id(), ' | Recursion called for this instruction: ', e)
				effect_result = apply_effect(eid, e, source)
				if !effect_result: break
			return effect_result
	else: #! No effect element_data given
		return false
	
	if active_eids.has(eid): ## Effect of same id is currently active in this entity
		if health_component.debug: print(eid, ' | Effect tried on ', entity.get_instance_id(), ' but active eid was detected')
		var match_effect : Effect
		for e in active_effects: if e.eid == eid: match_effect = e #? Find match from effect resource recursively
		if health_component.debug: print(eid, ' | ', entity.get_instance_id(), ' found an active match: ', match_effect)
		
		if edata.has("stackable"): #? Effect can stack
			if bool(edata["stackable"]): #? Add stacks to the same effect, increasing its strength significantly
				var multiplier : int = 1
				if edata.has("stack_multiplier"): multiplier = edata["stack_multiplier"]
				
				var new_value = match_effect.stacks + 1 * multiplier
				match_effect.stacks = clampi(new_value, 0, int(edata["max_stacks"]))
				match_effect.reset_duration()
				return true
			else: #? The effect cannot stack, but is duration will still be reset
				match_effect.reset_duration()
				return true
		else: #? The effect cannot stack
			return false
	
	if health_component.debug: print(entity.get_instance_id(), ' | Effect applied: ', eid)
	return activate_effect(eid, edata, source)

func activate_effect(
		eid : int,
		edata : Dictionary,
		source : Node
	) -> bool:
	
	var duration_timer = Timer.new()
	var tick_timer = Timer.new()
	duration_timer.set_one_shot(true)
	duration_timer.set_wait_time(edata["duration"])
	duration_timer.set_name(edata["ename"].to_upper() + "_DURATION")
	tick_timer.set_name(edata["ename"].to_upper() + "_TICK")
	add_child(duration_timer)
	duration_timer.add_child(tick_timer)
	
	var effect : Effect = Effect.new()
	effect.activate(
		eid,
		edata,
		duration_timer,
		tick_timer,
		health_component,
		source
	)
	active_effects.append(effect)
	active_eids.append(eid)
	duration_timer.start()
	tick_timer.start()
	return true

## Process effects based on values inside dictionary and individual etypes.
func compute_effect(
		effect : Effect, ## Source effect with multiple properties defined
		apply : bool = true ## If false, will cancel out the effect. Used to remove multipliers and such
	) -> void:
	
	var stackable : bool = bool(effect.edata["stackable"])
	
	match int(effect.edata["etype"]):
		000: # DEBUG
			print(effect.edata["message"])
		001: # DAMAGE_PER_TICK
			if !apply: return
			var d_value : int = roundi(effect.edata["value"])
			if stackable:
				if effect.stacks > 1: d_value *= effect.stacks
			if health_component.debug: print(effect.edata["ename"], ' | Damaging ', entity.get_instance_id(), ' with ', d_value, ' multiplied by ', effect.stacks, ' stacks')
			
			if is_instance_valid(effect.source): health_component.change(d_value, apply, effect.source)
			else: health_component.change(d_value, apply)
		002: pass # ADD_VULNERABILITY
		003: # SPEED MODIFY
			var d_multiplier : float = effect.edata["value_multiplier"]
			
			if apply:
				if !stackable and effect.times_applied > 1: return
				entity.speed *= float(d_multiplier)
				if health_component.debug: print(effect.edata["ename"], ' | Reducing movement speed of ', entity.get_instance_id() ,' by ', str(d_multiplier), ' thus new speed is ', entity.speed)
			else:
				entity.speed /= float(d_multiplier)
				if health_component.debug: print(effect.edata["ename"], ' | Returning movement speed ', entity.get_instance_id() ,' by ', str(d_multiplier), ' thus new speed is ', entity.speed)
		004: pass # PROJECTILE_CHANGE
		005: pass # TOWER_CHANGE
		005: pass # CONDITIONAL_PROC
		_: push_error(entity.get_instance_id(), " EffectComponent | INVALID E_TYPE")

## Remove effect from list as well as clearing previous effects via 'apply' boolean
func remove_effect(self_ref : Effect) -> void:
	compute_effect(self_ref, false) #? De-apply effect before expiring
	active_effects.erase(self_ref)
	active_eids.erase(self_ref.eid)
