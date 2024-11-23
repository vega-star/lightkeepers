## StageCamera class
## Navigation made easy with cursor-anchored controls
class_name StageCamera
extends Camera2D

const MINIMUM_SHAKE_STRENGTH : float = 0.05
const CLICK_THRESHOLD : float = 0.2
const SCREEN_SHAKE_DECAY : float = 3.0

@export_group('Zoom Configuration')
@export var min_zoom : float = 0.5
@export var max_zoom : float = 2.0
@export var zoom_factor : float = 0.1
@export var zoom_duration : float = 0.1
@export var mouse_zoom_factor : float = 0.2

@export_group('Camera Behavior')
@export var deadzone : float = 0.25 # Useful for controller compatibility
@export var drag_enabled : bool = true
@export var keybind_movement_multiplier : float = 7.5
@export var zoom_enabled : bool = true
@export var enable_camera_shake : bool = true
@export var base_shake_strength : float = 2.0

var start_drag_distance : float
var touch_points : Dictionary = {}
var clicked #? Boolean that determines if drag button is being pressed
var c_lock : bool #? Prevents drag movement from resetting before click is released
var current_pos : Vector2 # Current mouse position
var stored_pos : Vector2 # Stored mouse position
var _zoom_level : float = 1.0 : set = _set_zoom_level # 

var shake_random : RandomNumberGenerator = RandomNumberGenerator.new()
var shake_strength : float

#region Main functions
func _process(delta) -> void:
	current_pos = get_viewport().get_mouse_position()
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down", deadzone)
	
	if direction != Vector2.ZERO: ## Move by keybinds
		position += (direction * keybind_movement_multiplier) / zoom
	
	if drag_enabled: ## Move by drag
		if clicked: c_lock = true; _drag()
		elif !clicked and c_lock: c_lock = false #? Clamp position after drag is finished

func _physics_process(delta: float) -> void:
	if enable_camera_shake: ## Camera shake
		shake_strength = lerpf(shake_strength, 0.0, SCREEN_SHAKE_DECAY * delta)
		if shake_strength > MINIMUM_SHAKE_STRENGTH: offset += get_shake_offset(delta)
		else: set_offset(Vector2.ZERO)

func _drag() -> void:
	var pos_delta : Vector2 = (stored_pos - current_pos)
	stored_pos = current_pos #? Stores new position
	global_position += pos_delta / zoom #? Move camera based on delta while adapting to zoom

func _handle_touch(event : InputEvent) -> void: ## Touch compatibility
	if !UI.mouse_on_ui:
		if event.pressed:
			touch_points[event.index] = event.position
			clicked = true; stored_pos = event.position
		else:
			touch_points.erase(event.index)
			clicked = false
	else: touch_points.erase(event.index); clicked = false
	
	if touch_points.size() == 2:
		start_drag_distance = touch_points[1].distance_to(touch_points[2])

func _handle_drag(event : InputEvent) -> void: ## Touch drag compatibility
	if touch_points.size() == 2:
		var current_distance = touch_points[1].distance_to(touch_points[2])
		var diff = start_drag_distance - current_distance
		current_distance -= diff
		_set_zoom_level(diff / zoom_factor)

func _input(event) -> void:
	if event is InputEventScreenTouch: _handle_touch(event)
	elif event is InputEventScreenDrag: _handle_drag(event)
	
	if event.is_action_pressed("zoom_in") and !UI.mouse_on_ui and zoom_enabled: _set_zoom_level(_zoom_level + zoom_factor)
	if event.is_action_pressed("zoom_out") and !UI.mouse_on_ui and zoom_enabled: _set_zoom_level(_zoom_level - zoom_factor)
	
	if !UI.mouse_on_ui:
		if event.is_action_pressed("click"): clicked = true; stored_pos = get_viewport().get_mouse_position()
		elif event.is_action_released("click"): clicked = false
		
		if event.is_action_pressed("alt"): clicked = true; stored_pos = get_viewport().get_mouse_position()
		elif event.is_action_released("alt"): clicked = false
	else: clicked = false

func _set_zoom_level(value: float) -> void:
	_zoom_level = clamp(value, min_zoom, max_zoom)
	var previous_zoom : Vector2 = zoom
	var new_zoom : Vector2 = Vector2(_zoom_level, _zoom_level)
	if new_zoom.x >= max_zoom or new_zoom.x <= min_zoom: return
	var delta = new_zoom - previous_zoom
	var mouse_pos : Vector2 = get_global_mouse_position()
	zoom += delta
	var new_mouse_pos : Vector2 = get_global_mouse_position()
	position += mouse_pos - new_mouse_pos
#endregion

#region Additional functions
func toggle_shake(toggle : bool) -> void: enable_camera_shake = toggle

func start_shake(strength : float = base_shake_strength) -> void: shake_strength = strength

func get_shake_offset(_delta, effect_multiplier = 1) -> Vector2: return Vector2(shake_random.randf_range(-shake_strength,shake_strength) * effect_multiplier,shake_random.randf_range(-shake_strength,shake_strength * effect_multiplier))
