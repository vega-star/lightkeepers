class_name Enemy
extends CharacterBody2D

signal died

@onready var health_component = $HealthComponent

@export_group('Enemy Properties')
@export_enum('creep') var enemy_class = 'creep'
@export var base_health : int = 10
@export var base_speed : int = 100
@export var base_acceleration : float = 0.2
@export var debug_path : bool = false

@export_group('Node Connections')
@export var enemy_sprite : Sprite2D
@export var enemy_area : Area2D
@export var enemy_path : Path2D

var on_sight : bool: set = _set_on_sight
var navigation_agent : NavigationAgent2D
var target : Node2D : set = _set_target
var target_position : Vector2
var next_position
var direction

func _set_enemy_properties():
	navigation_agent = NavigationAgent2D.new()
	add_child(navigation_agent)
	navigation_agent.path_postprocessing = NavigationPathQueryParameters2D.PATH_POSTPROCESSING_EDGECENTERED
	navigation_agent.navigation_finished.connect(_on_navigation_finished)
	if debug_path: navigation_agent.debug_enabled = true
	target = get_tree().get_first_node_in_group('nexus')
	_create_path()
	# enemy_area.area_entered.connect(light_entered)
	# enemy_area.area_exited.connect(light_exited)

func _ready():
	await _set_enemy_properties()
	set_physics_process(true)

func _physics_process(delta):
	if !is_instance_valid(navigation_agent): return
	
	next_position = navigation_agent.get_next_path_position()
	direction = to_local(next_position).normalized()
	$EnemySprite.rotation = next_position.angle_to_point(position)
	
	if direction != Vector2.ZERO: velocity.move_toward(direction * base_speed, base_acceleration * delta)
	else: velocity.move_toward(Vector2.ZERO, base_acceleration * delta)
	
	velocity = velocity.lerp(direction * base_speed, base_acceleration)
	move_and_slide()

func _create_path(): if target: navigation_agent.target_position = target_position

func _set_target(node : Node2D): target = node; target_position = node.global_position
func _set_on_sight(toggle : bool):
	on_sight = toggle
	print('%s is toggle on sight'.format({0: self.name, 1: toggle}))

# func light_entered(area): if area is LightArea: on_sight = true
# func light_exited(area): if area is LightArea: on_sight = false

func _on_navigation_finished():
	print('%s reached' % self.name)
	die()

func die():
	died.emit()
	queue_free()
