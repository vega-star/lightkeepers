class_name Tower extends TileObject

signal tower_updated
signal tower_defeated_enemy(current_count : int)
signal tower_detected_enemy

enum TARGET_PRIORITIES {
	FIRST, ## First in place to reach nexus
	LAST, ## Last in place to reach nexus
	CLOSE, ## Closest to tower
	WEAK, ## Weakest enemy from array
	STRONG ## Strongest enemy from array
}

const DRAW_WIDTH : float = 2.5
const DEFAULT_RANGE : float = 160
const CIRCLE_TRANSPARENCY : float = 0.2
const LIGHT_SHAPE_SCENE : PackedScene = preload("res://components/systems/light_shape.tscn")
const DEFAULT_TOWER_ICON : Texture2D = preload("res://assets/prototypes/turret_sprite_placeholder.png")

#region Turret Configuration
@export_group('Default Values')
@export var default_tower_cost : int = 50
@export var default_projectile : PackedScene
@export_range(0, 10) var default_light_range : float = 1
@export_range(0, 10) var default_tower_range : float = 1
@export var default_target_priority : TARGET_PRIORITIES = 0
@export var default_projectile_quantity : int = 1
@export var default_damage : int = 5
@export var default_piercing : int = 1
@export var default_burst : int = 1
@export var default_firing_cooldown : float = 1.5
@export var default_seeking_timeout : float = 0.3

@export_group('Cosmetic Properties')
@export var destroy_sound_effect_id : String = 'rock 1 low'
@export var show_targeting_priorities : bool = true
@export var tower_name : String = 'Tower'
@export var tower_icon : Texture2D = DEFAULT_TOWER_ICON
@export var range_draw_color : Color = Color(0, 0.845, 0.776, 0.5)
@export var light_draw_color : Color = Color(0.863, 0.342, 0, 0.5)
#endregion

#region Variables
@onready var tower_upgrades : TowerUpgrades = $TowerUpgrades
@onready var tower_gun_muzzle : Marker2D = $TowerGunSprite/TowerGunMuzzle
@onready var tower_aim : RayCast2D = $TowerGunSprite/TowerGunMuzzle/TowerAim
@onready var tower_sprite : Sprite2D = $TowerSprite
@onready var tower_gun_sprite : AnimatedSprite2D = $TowerGunSprite
@onready var tower_range_area : Area2D = $TowerRangeArea
@onready var tower_range_shape : CollisionShape2D = $TowerRangeArea/TowerRangeShape
@onready var firing_cooldown_timer : Timer = $StateMachine/Firing/FiringCooldown

## Turret metadata
var target_priority : int
var tower_value : int

## Weapon values
var damage : int
var piercing : int
var burst : int
var projectile_quantity : int
var firing_cooldown : float: set = _set_firing_cooldown

## Node references
var stage_camera : StageCamera
var light_area : LightArea #? Global light area in Stage
var light_shape : LightShape #? Individual light present in light area
var bullet_container : Node2D
var nexus_position : Vector2
var target : Object
var eligible_targets : Array[Object]

## Custom setters
var tower_kill_count : int:
	set(new_count): tower_kill_count = new_count; tower_defeated_enemy.emit(tower_kill_count)
	
var light_range : float:
	set(new_range): light_range = new_range; _load_properties()

var tower_range : float: 
	set(new_range): tower_range = new_range; _load_properties()

## Booleans
var visible_range : bool = false #? Defines if the tower area is visible
var target_on_sight : bool = false #? Simple condition that can help controlling other behaviors
var prop : bool = false #? Used when the turret is being dragged on screen and not truly in game
#endregion

#region Internal processes
func _ready() -> void:
	nexus_position = get_tree().get_first_node_in_group('nexus').global_position
	light_area = get_tree().get_first_node_in_group('light_area')
	stage_camera = get_tree().get_first_node_in_group('stage_camera')
	_load_default_values()
	light_shape = LIGHT_SHAPE_SCENE.instantiate()
	tower_range_shape.shape = tower_range_shape.shape.duplicate()
	light_range = default_light_range
	tower_range = default_tower_range
	light_shape.position = position
	light_area.add_child(light_shape)
	tower_range_area.body_entered.connect(_enemy_detected)
	tower_range_area.body_exited.connect(_enemy_exited)

func _adapt_in_tile() -> void: light_shape.position = position

func _enemy_detected(body) -> void: if body is Enemy: eligible_targets.append(body); tower_detected_enemy.emit()

func _enemy_exited(body) -> void: eligible_targets.erase(body)

func _set_firing_cooldown(new_cooldown : float): firing_cooldown = new_cooldown; firing_cooldown_timer.wait_time = new_cooldown

func _load_properties() -> void:
	light_shape.size = light_range
	tower_range_shape.shape.radius = DEFAULT_RANGE * tower_range
	tower_aim.target_position.x = DEFAULT_RANGE * tower_range
	tower_updated.emit()

func _load_default_values() -> void:
	tower_value = default_tower_cost
	target_priority = default_target_priority
	piercing = default_piercing
	burst = default_burst
	projectile_quantity = default_projectile_quantity
	firing_cooldown = default_firing_cooldown; firing_cooldown_timer.wait_time = firing_cooldown
	if tower_gun_sprite.visible: tower_sprite.visible = false
	tower_updated.emit()

func _physics_process(_delta) -> void: queue_redraw()

func _draw() -> void:
	if visible_range: #? Draw visible cues to tower range based on the shape of the range itself and camera zoom. No adjustment is necessary!
		var set_zoom : float
		if !top_level: set_zoom = 1
		else: set_zoom = stage_camera.zoom.x
		
		draw_arc(to_local(global_position), light_shape.shape.radius * set_zoom, 0, TAU, 50, light_draw_color, DRAW_WIDTH)
		draw_arc(to_local(global_position), tower_range_shape.shape.radius * set_zoom, 0, TAU, 50, range_draw_color, DRAW_WIDTH)
		draw_circle(to_local(global_position), light_shape.shape.radius * set_zoom, Color(light_draw_color, CIRCLE_TRANSPARENCY), true)
		draw_circle(to_local(global_position), tower_range_shape.shape.radius * set_zoom, Color(range_draw_color, CIRCLE_TRANSPARENCY), true)
#endregion

#region Called functions
func remove_object() -> void:
	# AudioManager.emit_sound_effect(self.global_position, destroy_sound_effect_id)
	light_shape.queue_free()
	queue_free()
#endregion
