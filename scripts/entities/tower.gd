class_name Tower extends Node2D

signal tower_disabled
signal tower_destroyed

const base_range : float = 160
const light_shape_scene = preload("res://components/light_shape.tscn")

@export_group('Tower Properties')
@export var base_projectile : PackedScene
@export var tower_cost : int = 50
@export var base_damage : int = 5
@export var base_piercing : int = 1
@export var base_tower_cooldown : float = 2
@export var base_seeking_timeout : float = 0.3
@export_enum('nearest', 'closest', 'farthest', 'strongest', 'target') var seeking_type = 'nearest'
@export_range(0, 50) var base_light_range : float = 1
@export_range(0, 50) var base_tower_range : float = 1
@export var base_range_draw_color : Color = Color(0, 0.6, 0.702, 0.129)
@export var base_light_draw_color : Color = Color(0.714, 0.476, 0.249, 0.129)

@onready var tower_gun_muzzle = $TowerGunSprite/TowerGunMuzzle
@onready var tower_aim = $TowerGunSprite/TowerGunMuzzle/TowerAim
@onready var tower_sprite = $TowerSprite
@onready var tower_gun_sprite = $TowerGunSprite
@onready var tower_range_area = $TowerRangeArea
@onready var tower_range_shape = $TowerRangeArea/TowerRangeShape
@onready var cooldown_timer = $CooldownTimer
@onready var target_reset_timer = $TargetResetTimer

var cast_point : Vector2
var nexus_position : Vector2
var light_area : LightArea
var bullet_container : Node2D
var light_shape : LightShape

var mouse_light
var target : Object
var eligible_targets : Array[Object]
var tower_cooldown : float
var target_on_sight : bool = false
var visible_range : bool = false
var seeking_timeout : float:
	set(new_timeout):
		seeking_timeout = new_timeout
		target_reset_timer.wait_time = new_timeout

var damage : int
var piercing : int
var range_draw_color : Color = base_range_draw_color
var light_draw_color : Color = base_light_draw_color
var light_range : float:
	set(new_range):
		light_range = new_range
		_load_properties()
var tower_range : float: 
	set(new_range):
		tower_range = new_range
		_load_properties()

func _on_target_reset(): 
	if eligible_targets.size() > 0: target = _seek_target()
	else: target = null

func _load_properties():
	light_shape.size = light_range
	tower_range_shape.shape.radius = base_range * tower_range

func _adapt_in_tile():
	light_shape.position = position

func _ready():
	nexus_position = get_tree().get_first_node_in_group('nexus').global_position
	light_area = get_tree().get_first_node_in_group('light_area')
	bullet_container = get_tree().get_first_node_in_group('projectile_container')
	mouse_light = get_tree().get_first_node_in_group('mouse_light')
	
	piercing = base_piercing
	tower_sprite.visible = false
	
	light_shape = light_shape_scene.instantiate()
	light_shape.position = position
	light_area.add_child(light_shape)
	
	tower_range_area.body_entered.connect(_enemy_detected)
	tower_range_area.body_exited.connect(_enemy_exited)
	tower_cooldown = base_tower_cooldown; cooldown_timer.wait_time = tower_cooldown 
	seeking_timeout = base_seeking_timeout
	target_reset_timer.start()
	
	damage = base_damage
	light_range = base_light_range
	tower_range = base_tower_range

func _enemy_detected(body): if body is Enemy: eligible_targets.append(body) # ; print('ENEMY DETECTED BY TURRET %s' % self.name)
func _enemy_exited(body): eligible_targets.erase(body)

func _draw():
	if visible_range: 
		draw_arc(to_local(global_position), light_shape.shape.radius, 0, TAU, 50, light_draw_color, 5)
		draw_arc(to_local(global_position), tower_range_shape.shape.radius, 0, TAU, 50, range_draw_color, 5)

func _seek_target():
	var new_target : Object
	var available_targets : Array = []
	match seeking_type:
		'nearest':
			for t in eligible_targets.size():
				available_targets.append([
					eligible_targets[t], # Target node
					nexus_position.distance_squared_to(eligible_targets[t].position) # Target distance from nexus
				])
			available_targets.sort_custom(func(a, b): return a[1] < b[1]) # Sorts the array from the closest to the farthest
			new_target = available_targets[0][0] # Returns the closest target
		'closest':
			for t in eligible_targets.size():
				if eligible_targets[t].line_agent:
					available_targets.append([
					eligible_targets[t], # Target node
					eligible_targets[t].line_agent.progress # Target distance from turret
				])
				else: available_targets.append([
					eligible_targets[t], # Target node
					position.distance_squared_to(eligible_targets[t].position) # Target distance from turret
				])
			available_targets.sort_custom(func(a, b): return a[1] < b[1]) # Sorts the array from the closest to the farthest
			new_target = available_targets[0][0] # Returns the closest target
		_: push_error('INVALID SEEKING TYPE ON TURRET %s' % self.name)
	return new_target

func _physics_process(delta):
	if visible_range: queue_redraw()
	if is_instance_valid(target): 
		cast_point = target.global_position
		tower_gun_sprite.look_at(cast_point)
	tower_aim.force_raycast_update()
	if tower_aim.is_colliding():
		cooldown_timer.paused = false
		target_on_sight = true
		cast_point = to_local(tower_aim.get_collision_point())
	else:
		cooldown_timer.paused = true
		target_on_sight = false

func _on_cooldown_timer_timeout():
	$TowerGunSprite/PropProjectile.visible = false
	var projectile = base_projectile.instantiate()
	projectile.position = tower_gun_muzzle.global_position
	projectile.rotation_degrees = tower_gun_sprite.rotation_degrees
	projectile.piercing_count = piercing
	projectile.target = target
	projectile.damage = damage
	projectile.source = self
	tower_gun_sprite.play()
	bullet_container.add_child(projectile)
	await get_tree().create_timer(0.5).timeout
	$TowerGunSprite/PropProjectile.visible = true
