class_name Tower extends TileObject

const DIRECTION_SMOOTHING : float = 0.15
const DEFAULT_RANGE : float = 1
const DEFAULT_RANGE_DISTANCE : float = 128
const DEFAULT_LIGHT_RANGE : float = 1
const DEFAULT_LIGHT_DISTANCE : float = 128
const SEEKING_ROTATION_SPEED : float = TAU * 2
const DRAW_WIDTH : float = 2.5
const CIRCLE_TRANSPARENCY : float = 0.2
const LIGHT_SHAPE_SCENE : PackedScene = preload("res://components/systems/light_shape.tscn")

enum SEEKING_ANIMATIONS {}

enum FIRING_ANIMATIONS {}

enum TARGET_PRIORITIES {
	FIRST, ## First in place to reach nexus
	LAST, ## Last in place to reach nexus
	CLOSE, ## Closest to tower
	WEAK, ## Weakest enemy from array
	STRONG ## Strongest enemy from array
}

signal tower_placed
signal tower_updated
signal tower_neutralized
signal tower_detected_enemy
signal tower_defeated_enemy(current_count : int)

#region Turret Configuration
@export_group('Cosmetic Properties')
@export var projectile_scene : PackedScene = preload("res://components/projectiles/projectile.tscn")
@export var destroy_sound_effect_id : String = 'rock 1 low'
@export var show_targeting_priorities : bool = true
@export var tower_name : String = 'Tower'
@export var range_draw_color : Color = Color(0, 0.845, 0.776, 0.5)
@export var light_draw_color : Color = Color(0.863, 0.342, 0, 0.5)
@export var debug : bool = false
#endregion

#region Variables
## Internal node references
@onready var tower_animation_tree : AnimationTree = $TowerAnimationTree
@onready var tower_sprite : AnimatedSprite2D = $TowerSprite
@onready var tower_range_area : Area2D = $TowerRangeArea
@onready var tower_range_shape : CollisionShape2D = $TowerRangeArea/TowerRangeShape
@onready var tower_upgrades : TowerUpgrades = $TowerUpgrades
@onready var tower_aim : RayCast2D = $TowerAim
@onready var tower_projectile_point : Marker2D = $TowerAim/TowerProjectilePoint

## External node references
var eligible_targets : Array[Enemy]
var target : Enemy
var stage_camera : StageCamera
var light_area : LightArea #? Global light area in Stage
var light_shape : LightShape #? Individual light present in light area

## Controls
var visible_range : bool = false #? Defines if the tower area is visible
var target_on_sight : bool = false #? Simple condition that can help controlling other behaviors
var prop : bool = false #? Used when the turret is being dragged on screen and not truly in game

## Tower queried data
var quantity : int = 1
var target_priority : TARGET_PRIORITIES = 0
var tower_value : int = 0
var element : Element
var element_register : ElementRegister: set = adapt_register
var element_metadata : Dictionary = {}

## Weapon values
var damage : int = 5
var piercing : int = 1
var burst : int = 1
var magic_level : int = 1
var additional_distance_multiplier : float = 1
var projectile_quantity : int
var firing_cooldown : float = 1.5:
	set(new_cooldown):
		firing_cooldown = new_cooldown
		$StateMachine/Firing.firing_cooldown.wait_time = firing_cooldown

## Custom setters
var global_direction : Vector2: set = _update_direction

var light_range : float:
	set(new_range): 
		light_range = new_range
		light_shape.shape.radius = DEFAULT_LIGHT_DISTANCE * light_range
		tower_updated.emit()

var tower_range : float: 
	set(new_range):
		tower_range = new_range
		tower_range_shape.shape.radius = DEFAULT_RANGE_DISTANCE * tower_range
		tower_aim.target_position.x = tower_range_shape.shape.radius * 2 #? Update direct raycast range
		tower_updated.emit()

var tower_kill_count : int: #? Updates kill count and emits signal for the value still update when its tab is open
	set(new_count):
		tower_kill_count = new_count
		tower_defeated_enemy.emit(tower_kill_count)
#endregion

#region Internal processes
func _ready() -> void:
	light_area = get_tree().get_first_node_in_group('light_area')
	light_shape = LIGHT_SHAPE_SCENE.instantiate()
	tower_range_shape.shape = tower_range_shape.shape.duplicate() #? Prevents changing the shape in other nodes
	stage_camera = StageManager.active_stage.stage_camera
	await _configure()

func adapt_register(new_reg : ElementRegister) -> void:
	if !self.is_node_ready(): await ready
	
	element_register = new_reg
	set_name(element_register.element.element_id.to_upper() + "_MAGE")
	element_metadata = ElementManager.query_metadata(element_register.element.element_id)
	tower_name = name
	if element_metadata.has("turret_default_values"):
		for p in element_metadata.turret_default_values:
			self.set_deferred(p, element_metadata.turret_default_values[p])
			if debug: print(str(p), ' changed from ', p, ' to ', element_metadata.turret_default_values[p])
	
	if element_metadata.has("upgrade_trees"):
		tower_upgrades.upgrade_tree_1 = ResourceLoader.load("res://components/upgrade_trees/{0}.tres".format({0: element_metadata.upgrade_trees[0]}))
		tower_upgrades.upgrade_tree_2 = ResourceLoader.load("res://components/upgrade_trees/{0}.tres".format({0: element_metadata.upgrade_trees[1]}))
		tower_upgrades.upgrade_tree_3 = ResourceLoader.load("res://components/upgrade_trees/{0}.tres".format({0: element_metadata.upgrade_trees[2]}))
		tower_upgrades.upgrade_trees_array = [tower_upgrades.upgrade_tree_1, tower_upgrades.upgrade_tree_2, tower_upgrades.upgrade_tree_3]
	
	if element_metadata.projectile_scene != null:
		projectile_scene = element_metadata.projectile_scene

func _configure() -> void:
	light_range = DEFAULT_LIGHT_RANGE
	tower_range = DEFAULT_RANGE
	light_shape.position = position
	light_area.add_child(light_shape)
	if prop: light_area.set_deferred("disabled", true)
	tower_range_area.body_entered.connect(_enemy_detected)
	tower_range_area.body_exited.connect(_enemy_exited)
	light_shape.set_name(tower_name + '_LightArea')

func _physics_process(_delta) -> void: queue_redraw()

func _adapt_in_tile() -> void: light_shape.position = position

## Enemy detection management
func _enemy_detected(body) -> void:
	if body is Enemy: eligible_targets.append(body)
	emit_signal("tower_detected_enemy")

func _enemy_exited(body) -> void: eligible_targets.erase(body)

## Smooth rotation movement
func _rotate_tower(direction : Vector2, delta : float, speed : float = SEEKING_ROTATION_SPEED) -> void:
	_rotate_to_direction(tower_aim, direction, delta, speed)
	global_direction = Vector2.RIGHT.rotated(-get_angle_to(tower_projectile_point.global_position))

func _rotate_to_direction(
		r_node : Node, ## Rotate node
		r_direction : Vector2, ## Rotation direction
		delta : float, ## Delta from process
		r_speed : float ## Optional parameter that defaults to constant seeking rotation speed
	) -> void:
	var angle = r_node.transform.x.angle_to(r_direction)
	r_node.rotate(sign(angle) * min(delta * r_speed, abs(angle)))

func _update_direction(new_direction : Vector2) -> void:
	global_direction = lerp(global_direction, new_direction, DIRECTION_SMOOTHING)
	tower_animation_tree.set("parameters/Seeking/blend_position", global_direction)
	tower_animation_tree.set("parameters/Firing/blend_position",global_direction)

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
	if !prop: AudioManager.emit_sound_effect(destroy_sound_effect_id, self.global_position)
	light_shape.queue_free()
	queue_free()
#endregion
