## Upgrade | Upgrades can contain more than one modifications to a tower, thus, contains an array of said modifications.
class_name Upgrade extends Resource

@export var upgrade_icon : Texture2D
@export var upgrade_title : String = 'UPGRADE_TITLE'
@export var upgrade_description : String = 'UPGRADE_TITLE_DESCRIPTION'
@export var upgrade_cost : int = 0
@export var upgrade_commands : Array[UpgradeCommand]
