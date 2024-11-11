class_name PupilUpgrades
extends Node

signal pupil_upgraded

const COST_MITIGATION_FACTOR : float = 0.8

enum UPGRADE_ADDRESSES {
	DAMAGE_ADD,
	DAMAGE_MULTIPLY,
	PROJECTILE_COUNT_ADD,
	BURST_ADD,
	PIERCING_ADD,
	FIRING_COOLDOWN_LINEAR,
	FIRING_COOLDOWN_MULTIPLY,
	ATTACK_RANGE_MULTIPLY,
	LIGHT_RANGE_MULTIPLY,
	SWITCH_PROJECTILE
}

@export var upgrade_tree_1 : PupilUpgradeTree
@export var upgrade_tree_2 : PupilUpgradeTree
@export var upgrade_tree_3 : PupilUpgradeTree
var upgrade_trees_array : Array[PupilUpgradeTree]

@export var debug : bool = false

var stage_agent : StageAgent
var pupil : Pupil = owner
var pupil_element_reg : ElementRegister: set = _on_pupil_element_reg_updated

func _ready() -> void:
	var stage = get_tree().get_first_node_in_group('stage')
	if upgrade_tree_1: upgrade_tree_1 = upgrade_tree_1.duplicate(true); upgrade_trees_array.append(upgrade_tree_1)
	if upgrade_tree_2: upgrade_tree_2 = upgrade_tree_2.duplicate(true); upgrade_trees_array.append(upgrade_tree_2)
	if upgrade_tree_3: upgrade_tree_3 = upgrade_tree_3.duplicate(true); upgrade_trees_array.append(upgrade_tree_3)
	pupil = owner
	stage_agent = stage.stage_agent

func _request_upgrade(upgrade_tree : PupilUpgradeTree) -> bool:
	if (upgrade_tree.tier + 1 > upgrade_tree.upgrades.size()): print('Upgrade overflow'); return false
	
	var next_tier : int = upgrade_tree.tier + 1
	var upgrade : Upgrade = upgrade_tree.upgrades[upgrade_tree.tier]
	var cost : int = upgrade.upgrade_cost
	
	if (cost > stage_agent.coins): return false
	
	pupil.pupil_value += roundi(cost * COST_MITIGATION_FACTOR)
	upgrade_tree.tier = next_tier
	stage_agent.change_coins(cost)
	pupil_upgraded.emit()
	
	if debug: print('TIER: ', upgrade_tree.tier)
	_apply_upgrade(upgrade.upgrade_commands)
	return true

func _apply_upgrade(commands : Array[UpgradeCommand]) -> void:
	for c in commands:
		var upgrade_type : UPGRADE_ADDRESSES = c.upgrade_type
		var u_value = c.upgrade_value
		
		if debug: print('{1} | {2} - {3}'.format({1: c.upgrade_type, 2: UPGRADE_ADDRESSES.find_key(c.upgrade_type), 3: u_value}))
		match c.upgrade_type:
			0: pupil.damage += int(u_value)
			1: pupil.damage = roundi(pupil.damage * float(u_value))
			2: pupil.projectile_quantity += int(u_value)
			3: pupil.burst += int(u_value)
			4: pupil.piercing += int(u_value)
			5: pupil.firing_cooldown -= float(u_value)
			6: pupil.firing_cooldown /= float(u_value)
			7: pupil.attack_range *= float(u_value)
			8: pupil.light_range *= float(u_value)

func _on_pupil_upgraded() -> void: pupil.pupil_updated.emit()

func _on_pupil_element_reg_updated(new_reg : ElementRegister) -> void:
	pupil_element_reg = new_reg
	if !pupil_element_reg:
		pupil.element_metadata = {}
		if pupil.pupil_type == 0: pupil.pupil_gun_sprite.modulate = Color.WHITE
		return
	if !pupil_element_reg.element.element_metadata: #? Newly generated elements *should* have metadata, but here it is in case elements don't have it
		pupil_element_reg.element.element_metadata = ElementManager.query_metadata(new_reg.element.element_id)
	var metadata : Dictionary = pupil_element_reg.element.element_metadata.duplicate(true)
	pupil.element_metadata = metadata
	if pupil.pupil_type == 1: pupil.pupil_gun_sprite.modulate = metadata["root_color"]
	assert(!pupil.element_metadata.is_read_only())
