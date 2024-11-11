class_name Enemy
extends CharacterBody2D

signal path_ended
signal died(source : Node)

const SCALE_CHANGE_WH : float = 1.15
const SPEED_MULTIPLIER : int = 100
const HEALTH_CHANGE_MPERIOD : float = 0.5
const DAMAGE_MODULATE : Color = Color(5, 5, 5)
const HEAL_MODULATE : Color = Color(1, 3, 1.5)
enum ENEMY_CLASS {
	CREEP,
	BRUTE,
	BULKWARK,
	GIANT,
	BEHEMOTH,
	TIAMAT
}

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent
@onready var health_component = $HealthComponent

@export_group('Enemy Properties')
@export var enemy_name : String = "Enemy"
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

# var navigation_agent : NavigationAgent2D #? Smart enemy nav agent
var stored_scale : Vector2
var line_agent : PathFollow2D #? Line2D node to follow
var stage : Stage #? Stage to call upon

var nexus : Node2D
var damage_on_nexus : int
var enemy_value : int
var on_sight : bool = false : set = _set_on_sight
var target_position : Vector2
var next_position
var direction

#region Main functions
func _ready(): await _set_enemy_properties()

func _set_enemy_properties():
	stage = get_tree().get_first_node_in_group('stage')
	nexus = get_tree().get_first_node_in_group('nexus')
	damage_on_nexus = default_damage_on_nexus
	enemy_value = base_enemy_value
	stored_scale = scale
	
	health_component.max_health = base_health
	health_component.reset_health()
	set_name(enemy_name)
	set_target(nexus)
	
	if smart_enemy:
		assert(nexus)
		navigation_agent.navigation_finished.connect(_on_navigation_finished)
		_create_path()
	else:
		set_collision_mask_value(3, false) #? Deactivate enemy collision
		_set_path2d(stage.stage_path)

func _physics_process(delta):
	if !smart_enemy: #? Update Line2D
		line_agent.set_progress(line_agent.get_progress() + base_speed * delta)
		if position != Vector2.ZERO: position = Vector2.ZERO
		if (line_agent.get_progress_ratio() == 1): path_ended.emit()
	else: #? Call NavigationAgent
		next_position = navigation_agent.get_next_path_position()
		direction = global_position.direction_to(next_position)
		_rotate_to_direction($EnemySprite, direction, delta)
		navigation_agent.velocity = direction * (base_speed * SPEED_MULTIPLIER) * delta

func _rotate_to_direction(r_node : Node, r_direction : Vector2, delta : float) -> void:
	var angle = r_node.transform.x.angle_to(r_direction)
	r_node.rotate(sign(angle) * min(delta * TAU * 2, abs(angle)))

func _on_navigation_agent_velocity_computed(safe_velocity : Vector2) -> void:
	velocity = safe_velocity
	move_and_slide()

func _set_path2d(line_node : Path2D):
	if is_instance_valid(line_agent): return
	else: line_agent = PathFollow2D.new()
	line_agent.position = line_node.position
	line_agent.loop = false
	line_node.add_child(line_agent)
	enemy_sprite.rotation = get_angle_to(line_node.curve.get_point_position(1))
	line_agent.set_name(enemy_name)
	reparent(line_agent)

func _create_path(): navigation_agent.target_position = target_position

func set_target(node : Node2D):
	if !node: return
	target_position = node.global_position

func _set_on_sight(toggle : bool):
	on_sight = toggle
	set_collision_layer_value(7, toggle)

func _on_navigation_finished(): path_ended.emit()

func _on_path_ended():
	stage.stage_agent.change_health(damage_on_nexus)
	die(nexus)

func die(source):
	if !source == nexus: stage.stage_agent.change_coins(enemy_value, true)
	died.emit(source)
	queue_free()
	if !smart_enemy: line_agent.queue_free()
#endregion

func _on_health_component_health_change(previous_value: int, new_value: int, negative : bool) -> void:
	var modulate_color : Color
	if negative: modulate_color = DAMAGE_MODULATE
	else: modulate_color = HEAL_MODULATE
	
	var modulate_tween : Tween = get_tree().create_tween()
	var size_tween : Tween = get_tree().create_tween()
	set_modulate(modulate_color)
	self.scale *= SCALE_CHANGE_WH
	
	modulate_tween.tween_property(self, "modulate", Color(1,1,1), HEALTH_CHANGE_MPERIOD)
	size_tween.tween_property(self, "scale", stored_scale, HEALTH_CHANGE_MPERIOD)
