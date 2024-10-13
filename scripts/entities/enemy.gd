class_name Enemy
extends CharacterBody2D

signal path_ended
signal died(source : Node)

enum ENEMY_CLASS {
	CREEP,
	BRUTE,
	BULKWARK,
	GIANT,
	BEHEMOTH,
	TIAMAT
}

@onready var health_component = $HealthComponent

@export_group('Enemy Properties')
@export var enemy_class : ENEMY_CLASS = 0
@export var default_damage_on_nexus : int = 5
@export var base_enemy_value : int = 3
@export var base_health : int = 10
@export var base_speed : int = 60
@export var base_acceleration : float = 0.2
@export var smart_enemy : bool = true
@export var debug_path : bool = false

@export_group('Node Connections')
@export var enemy_sprite : Sprite2D
@export var enemy_area : Area2D
@export var enemy_path : Path2D

var navigation_agent : NavigationAgent2D #? Smart enemy nav agent
var line_agent : PathFollow2D #? Line2D node to follow
var stage : Stage #? Stage to call upon

var initial_rotation : float = 0
var damage_on_nexus : int
var enemy_value : int
var on_sight : bool = false : set = _set_on_sight
var nexus : Node2D : set = _set_target
var target_position : Vector2
var next_position
var direction

func _set_enemy_properties():
	stage = get_tree().get_first_node_in_group('stage')
	nexus = get_tree().get_first_node_in_group('nexus')
	damage_on_nexus = default_damage_on_nexus
	enemy_value = base_enemy_value
	
	if smart_enemy:
		assert(nexus)
		navigation_agent = NavigationAgent2D.new()
		navigation_agent.path_postprocessing = NavigationPathQueryParameters2D.PATH_POSTPROCESSING_EDGECENTERED
		navigation_agent.navigation_finished.connect(_on_navigation_finished)
		if debug_path: navigation_agent.debug_enabled = true
		add_child(navigation_agent)
		_create_path()
	else:
		_set_path2d(stage.stage_path)

func _ready():
	await _set_enemy_properties()
	health_component.health = base_health
	set_physics_process(true)

func _physics_process(delta):
	if !smart_enemy: #? Update Line2D
		line_agent.set_progress(line_agent.get_progress() + base_speed * delta)
		if position != Vector2.ZERO: position = Vector2.ZERO
		if (line_agent.get_progress_ratio() == 1): path_ended.emit()
	else: #? Call NavigationAgent
		next_position = navigation_agent.get_next_path_position()
		direction = to_local(next_position).normalized()
		$EnemySprite.rotation = initial_rotation + next_position.angle_to_point(position)
		if direction != Vector2.ZERO: velocity.move_toward(direction * base_speed, base_acceleration * delta)
		else: velocity.move_toward(Vector2.ZERO, base_acceleration * delta)
		velocity = velocity.lerp(direction * base_speed, base_acceleration)
		move_and_slide()

func _set_path2d(line_node : Path2D):
	if is_instance_valid(line_agent): return
	else: line_agent = PathFollow2D.new()
	line_agent.position = line_node.position
	line_agent.loop = false
	line_node.add_child(line_agent)
	enemy_sprite.rotation = get_angle_to(line_node.curve.get_point_position(1))
	reparent(line_agent)

func _create_path(): navigation_agent.target_position = target_position

func _set_target(node : Node2D): 
	nexus = node
	target_position = node.global_position

func _set_on_sight(toggle : bool):
	on_sight = toggle
	set_collision_layer_value(7, toggle)

func _on_navigation_finished(): path_ended.emit()

func _on_path_ended():
	stage.stage_manager.change_health(damage_on_nexus)
	die(nexus)

func die(source):
	if !source == nexus: stage.stage_manager.change_coins(enemy_value, true)
	died.emit(source)
	queue_free()
	if !smart_enemy: line_agent.queue_free()
