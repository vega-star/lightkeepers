class_name TowerUpgrades
extends Node

signal tower_upgraded

const COST_MITIGATION_FACTOR : float = 0.8

enum UPGRADE_ADDRESSES {
	DAMAGE_ADD,
	DAMAGE_MULTIPLY,
	PROJECTILE_COUNT_ADD,
	BURST_ADD,
	PIERCING_ADD,
	FIRING_COOLDOWN_LINEAR,
	FIRING_COOLDOWN_MULTIPLY,
	TOWER_RANGE_MULTIPLY,
	LIGHT_RANGE_MULTIPLY,
	SWITCH_PROJECTILE
}

@export var upgrade_tree_1 : TowerUpgradeTree
@export var upgrade_tree_2 : TowerUpgradeTree
@export var upgrade_tree_3 : TowerUpgradeTree
var upgrade_trees_array : Array[TowerUpgradeTree]

var stage_manager : StageManager
var tower : Tower

func _ready() -> void:
	var stage = get_tree().get_first_node_in_group('stage')
	if upgrade_tree_1: upgrade_tree_1.duplicate(true); upgrade_trees_array.append(upgrade_tree_1)
	if upgrade_tree_2: upgrade_tree_2.duplicate(true); upgrade_trees_array.append(upgrade_tree_2)
	if upgrade_tree_3: upgrade_tree_3.duplicate(true); upgrade_trees_array.append(upgrade_tree_3)
	tower = owner
	stage_manager = stage.stage_manager

func _request_upgrade(upgrade_tree : TowerUpgradeTree) -> bool:
	if (upgrade_tree.tier > upgrade_tree.upgrades.size()): return false
	
	var next_tier : int = upgrade_tree.tier + 1
	var upgrade : Upgrade = upgrade_tree.upgrades[upgrade_tree.tier]
	var cost : int = upgrade.upgrade_cost
	
	if (cost > stage_manager.coins): return false
	
	tower.tower_value += roundi(cost * COST_MITIGATION_FACTOR)
	upgrade_tree.tier = next_tier
	stage_manager.change_coins(cost)
	tower_upgraded.emit()
	
	print('TIER: ', upgrade_tree.tier)
	_apply_upgrade(upgrade.upgrade_commands)
	return true

func _apply_upgrade(commands : Array[UpgradeCommand]) -> void:
	for c in commands:
		var upgrade_type : UPGRADE_ADDRESSES = c.upgrade_type
		var u_value = c.upgrade_value
		
		print('{1} | {2} - {3}'.format({1: c.upgrade_type, 2: UPGRADE_ADDRESSES.find_key(c.upgrade_type), 3: u_value}))
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
