class_name Coin extends Sprite2D

const MAX_TRAIL_LENGTH : int = 15
const LERP_SPEED : float = 5.0
const Z_OVERRIDE : int = 25
const MAX_SIZE : int = 5
const SHINE_MODULATION_MULTIPLY : float = 5.0
const VALUE_THRESHOLD : int = 5
const COLLECTION_TIMEOUT : float = 3

@onready var pyrite_trace: Line2D = $Separator/PyriteTrace

var automatic_collect : bool = true
var go_to_collect : bool
var value : int = 1: set = infer_value

func _ready() -> void:
	if automatic_collect:
		await get_tree().create_timer(COLLECTION_TIMEOUT)
		collect()

func infer_value(new_value : int) -> void:
	value = new_value
	var size_factor = pow(value, 1/3) #? The size of the fragment is the cube root of the value!
	size_factor = clamp(size_factor, 2, MAX_SIZE)
	var size : Vector2 = Vector2(size_factor, size_factor)
	set_scale(size)

func _physics_process(delta: float) -> void:
	if go_to_collect:
		global_position = global_position.lerp(
			StageManager.active_stage.stage_camera.global_position - Vector2(0, get_viewport().get_visible_rect().size.y / 2),
			delta * LERP_SPEED)
		
		# pyrite_trace.add_point(global_position)
		# if pyrite_trace.get_point_count() >= MAX_TRAIL_LENGTH: pyrite_trace.remove_point(0) # Clear last point

func collect() -> void:
	var shine_tween : Tween = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT)
	var collector_tween : Tween = get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	shine_tween.tween_property(self, "self_modulate", self_modulate * SHINE_MODULATION_MULTIPLY, 0.2)
	z_index = Z_OVERRIDE
	go_to_collect = true
	await get_tree().create_timer(2).timeout
	StageManager.active_stage_agent.change_coins(value, true)
	queue_free()
