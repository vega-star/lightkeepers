class_name Tower extends TileObject

signal tower_updated
# signal tower_disabled
# signal tower_destroyed

enum TARGET_PRIORITIES {
	FIRST, ## First in place to reach nexus
	LAST, ## Last in place to reach nexus
	CLOSE, ## Closest to tower
	WEAK, ## Weakest enemy from array
	STRONG ## Strongest enemy from array
}

const DRAW_WIDTH : float = 2.5
const BASE_RANGE : float = 160
const LIGHT_SHAPE_SCENE : PackedScene = preload("res://components/systems/light_shape.tscn")
const DEFAULT_TOWER_ICON : Texture2D = preload("res://assets/prototypes/turret_sprite_placeholder.png")

#region Turret Configuration
## Main variables
@export_group('Tower Properties')
@export var base_target_priority : TARGET_PRIORITIES = 0
@export var base_projectile : PackedScene
@export var base_tower_cost : int = 50
@export var base_burst : int = 1
@export var base_damage : int = 5
@export var base_piercing : int = 1
@export var base_firing_cooldown : float = 1.5
@export var base_seeking_timeout : float = 0.3
@export_range(0, 50) var base_light_range : float = 1
@export_range(0, 50) var base_tower_range : float = 1

@export_group('Cosmetic Properties')
@export var show_targeting_priorities : bool = true
@export var tower_name : String = 'Tower'
@export var tower_icon : Texture2D = DEFAULT_TOWER_ICON
@export var base_range_draw_color : Color = Color(0, 0.845, 0.776, 0.5)
@export var base_light_draw_color : Color = Color(0.863, 0.342, 0, 0.5)

## Turret nodes
@onready var tower_gun_muzzle = $TowerGunSprite/TowerGunMuzzle
@onready var tower_aim = $TowerGunSprite/TowerGunMuzzle/TowerAim
@onready var tower_sprite = $TowerSprite
@onready var tower_gun_sprite = $TowerGunSprite
@onready var tower_range_area = $TowerRangeArea
@onready var tower_range_shape = $TowerRangeArea/TowerRangeShape

## State nodes
@onready var firing_cooldown_timer = $StateMachine/Firing/FiringCooldown
@onready var seeking_reset_timer = $StateMachine/Seeking/TargetResetTimer
var prop : bool = false #? Used when the turret is being dragged on screen and not truly in game
#endregion

#region Variable
var tower_value : int
var target_priority : int = base_target_priority
var stage_camera : StageCamera
var light_area : LightArea
var light_shape : LightShape
var bullet_container : Node2D
var nexus_position : Vector2
var range_draw_color : Color = base_range_draw_color
var light_draw_color : Color = base_light_draw_color
var visible_range : bool = false

var target_on_sight : bool = false
var target : Object
var eligible_targets : Array[Object]

var piercing : int
var damage : int:
	set(new_damage):
		damage = new_damage
var firing_cooldown : float:
	set(new_timeout):
		firing_cooldown = new_timeout
		firing_cooldown_timer.wait_time = new_timeout
var seeking_timeout : float:
	set(new_timeout):
		seeking_timeout = new_timeout
		seeking_reset_timer.wait_time = new_timeout
var light_range : float:
	set(new_range):
		light_range = new_range
		_load_properties()
var tower_range : float: 
	set(new_range):
		tower_range = new_range
		_load_properties()
#endregion

func _ready() -> void:
	tower_value = base_tower_cost
	target_priority = base_target_priority
	
	light_shape = LIGHT_SHAPE_SCENE.instantiate()
	nexus_position = get_tree().get_first_node_in_group('nexus').global_position
	light_area = get_tree().get_first_node_in_group('light_area')
	stage_camera = get_tree().get_first_node_in_group('stage_camera')
	
	light_range = base_light_range
	tower_range = base_tower_range
	light_shape.position = position
	light_area.add_child(light_shape)
	
	tower_range_area.body_entered.connect(_enemy_detected)
	tower_range_area.body_exited.connect(_enemy_exited)
	
	firing_cooldown = base_firing_cooldown; firing_cooldown_timer.wait_time = firing_cooldown
	seeking_timeout = base_seeking_timeout; seeking_reset_timer.wait_time = seeking_timeout
	piercing = base_piercing
	
	if tower_gun_sprite.visible: tower_sprite.visible = false

func _load_properties() -> void:
	light_shape.size = light_range
	tower_range_shape.shape.radius = BASE_RANGE * tower_range

func _adapt_in_tile() -> void: light_shape.position = position
func _enemy_detected(body) -> void: if body is Enemy: eligible_targets.append(body) # ; print('ENEMY DETECTED BY TURRET %s' % self.name)
func _enemy_exited(body) -> void: eligible_targets.erase(body)

func _draw() -> void:
	if visible_range: #? Draw visible cues to tower range based on the shape of the range itself and camera zoom. No adjustment is necessary!
		var set_zoom : float
		if !top_level: set_zoom = 1
		else: set_zoom = stage_camera.zoom.x
		
		draw_arc(to_local(global_position), light_shape.shape.radius * set_zoom, 0, TAU, 50, light_draw_color, DRAW_WIDTH)
		draw_arc(to_local(global_position), tower_range_shape.shape.radius * set_zoom, 0, TAU, 50, range_draw_color, DRAW_WIDTH)
		draw_circle(to_local(global_position), light_shape.shape.radius * set_zoom, Color(light_draw_color, 0.2), true)
		draw_circle(to_local(global_position), tower_range_shape.shape.radius * set_zoom, Color(range_draw_color, 0.2), true)

func _physics_process(_delta) -> void:
	queue_redraw() #? Updates draw functions
