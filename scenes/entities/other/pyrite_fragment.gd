class_name PyriteFragment extends Node2D

const VALUE_THRESHOLD : int = 5
const COLLECTION_TIMEOUT : float = 3

var automatic_collect : bool = true
var value : int = 1: set = infer_value

func _ready() -> void:
	if automatic_collect:
		await get_tree().create_timer(COLLECTION_TIMEOUT)
		collect()

func infer_value(new_value : int) -> void:
	value = new_value
	var size_factor = pow(value, 1/3) #? The size of the fragment is the cube root of the value!
	set_scale(Vector2.ONE * size_factor)

func collect() -> void:
	UI.interface.collect_coin(self)
