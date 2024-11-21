class_name TowerUpgrades
extends Node

signal tower_upgraded

const COST_MITIGATION_FACTOR : float = 0.8

@export var upgrade_tree_1 : TowerUpgradeTree
@export var upgrade_tree_2 : TowerUpgradeTree
@export var upgrade_tree_3 : TowerUpgradeTree
var upgrade_trees_array : Array[TowerUpgradeTree]

@export var debug : bool = false

var active_stage : Stage
var active_stage_agent : StageAgent
var tower : Tower = owner
var tower_element_reg : ElementRegister: set = _on_tower_element_reg_updated

func _ready() -> void:
	var active_stage = StageManager.active_stage
	active_stage_agent = StageManager.active_stage_agent
	if upgrade_tree_1: upgrade_tree_1 = upgrade_tree_1.duplicate(true); upgrade_trees_array.append(upgrade_tree_1)
	if upgrade_tree_2: upgrade_tree_2 = upgrade_tree_2.duplicate(true); upgrade_trees_array.append(upgrade_tree_2)
	if upgrade_tree_3: upgrade_tree_3 = upgrade_tree_3.duplicate(true); upgrade_trees_array.append(upgrade_tree_3)
	tower = owner
	if !tower.is_node_ready(): await tower.ready
	tower_element_reg = tower.element_register

func _request_upgrade(upgrade_tree : TowerUpgradeTree) -> bool:
	if (upgrade_tree.tier + 1 > upgrade_tree.upgrades.size()): print('Upgrade overflow'); return false
	
	var next_tier : int = upgrade_tree.tier + 1
	var upgrade : Upgrade = upgrade_tree.upgrades[upgrade_tree.tier]
	var cost : int = upgrade.upgrade_cost
	
	if (cost > active_stage_agent.coins): return false
	
	tower.tower_value += roundi(cost * COST_MITIGATION_FACTOR)
	upgrade_tree.tier = next_tier
	active_stage_agent.change_coins(cost)
	tower_upgraded.emit()
	
	if debug: print('TIER: ', upgrade_tree.tier)
	_apply_upgrade(upgrade.upgrade_commands)
	return true

func _apply_upgrade(commands : Array[UpgradeCommand]) -> void:
	for c in commands:
		var upgrade_type : UpgradeCommand.UPGRADE_TYPE = c.upgrade_type
		var u_value = c.upgrade_value
		
		if debug: print('{1} | {2} - {3}'.format({1: c.upgrade_type, 2: c.upgrade_type, 3: u_value}))
		match c.upgrade_type:
			0: tower.damage += int(u_value)
			1: tower.damage = roundi(tower.damage * float(u_value))
			2: tower.projectile_quantity += int(u_value)
			3: tower.burst += int(u_value)
			4: tower.piercing += int(u_value)
			5: tower.firing_cooldown -= float(u_value)
			6: tower.firing_cooldown /= float(u_value)
			7: tower.tower_range *= float(u_value)
			8: tower.light_range *= float(u_value)
			_: push_error('INVALID UPGRADE TYPE: ', c.upgrade_type)

func _on_tower_upgraded() -> void: tower.tower_updated.emit()

func _on_tower_element_reg_updated(new_reg : ElementRegister) -> void:
	tower_element_reg = new_reg
	if !tower_element_reg:
		tower.element_metadata = {}
		if tower.tower_type == 0: tower.tower_gun_sprite.modulate = Color.WHITE
		return
	if !tower_element_reg.element.element_metadata: #? Newly generated elements *should* have metadata, but here it is in case elements don't have it
		tower_element_reg.element.element_metadata = ElementManager.query_metadata(new_reg.element.element_id)
	var metadata : Dictionary = tower_element_reg.element.element_metadata.duplicate(true)
	
	tower.element_metadata = metadata
	tower.tower_sprite.set_modulate(metadata["root_color"])
	assert(!tower.element_metadata.is_read_only())
