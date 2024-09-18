class_name StageCamera
extends Camera2D

@export_category('Zoom Configuration')
@export var mouse_zoom_factor : float = 0.2
@export var drag: float = 0.2
@export var drag_multiplier : float = 5
@export var drag_smoothing : float = 0.5
@export var min_zoom := 0.5
@export var max_zoom := 2.0
@export var zoom_factor := 0.1
@export var zoom_duration := 0.1

@export_category('Camera Behavior')
@export var deadzone : float = 0.25 # Useful for controller compatibility
@export var drag_enabled : bool = true
@export var zoom_enabled : bool = true
@export var dynamic_zoom : bool = false
@export var camera_debug : bool = false
@export var enable_camera_shake : bool = true
@export var base_shake_strength : float = 2.0
@export var shake_decay : float = 3.0

const MINIMUM_SHAKE_STRENGTH : float = 0.05
const CLICK_THRESHOLD : float = 0.2
const LIMIT_OFFSET : int = 250

var clicked
var click_lock : bool # Prevents multiple resets on offset
var previously_clicked : bool
var current_pos : Vector2 # Current mouse position
var stored_pos : Vector2 # Stored mouse position
var stored_offset : Vector2  # Stored camera offset
var _zoom_level : float = 1.0 : set = _set_zoom_level

var zoom_tween : Tween
var offset_tween : Tween
var reset_offset_tween : Tween
var shake_random = RandomNumberGenerator.new()
var shake_strength : float

func _process(delta) -> void:
	current_pos = get_viewport().get_mouse_position()
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down", deadzone)
	position += direction * (drag_multiplier * 5 * zoom)
	
	if enable_camera_shake:
		shake_strength = lerpf(shake_strength, 0.0, shake_decay * delta)
		if shake_strength > MINIMUM_SHAKE_STRENGTH: position += get_shake_offset(delta)
	
	if drag_enabled:
		if clicked:
			click_lock = true
			var diff : Vector2 = (stored_pos - current_pos)
			stored_pos = current_pos
			stored_offset += diff
			set_offset(stored_offset)
		elif !clicked and click_lock:
			global_position = to_global(offset).clamp( #? Convert and prevent clipping through limits
				Vector2(get_limit(SIDE_LEFT) + LIMIT_OFFSET / zoom.x, get_limit(SIDE_TOP) + LIMIT_OFFSET / zoom.x),
				Vector2(get_limit(SIDE_RIGHT) - LIMIT_OFFSET / zoom.x, get_limit(SIDE_BOTTOM) - LIMIT_OFFSET / zoom.x)
			)
			set_offset(Vector2.ZERO)
			stored_offset = Vector2.ZERO
			click_lock = false

func _input(event) -> void:
	if event.is_action_pressed("drag_zoom"): 
		clicked = true
		stored_offset = Vector2.ZERO
		stored_pos = get_viewport().get_mouse_position()
	elif event.is_action_released("drag_zoom"): 
		clicked = false

func toggle_shake(toggle : bool) -> void: enable_camera_shake = toggle
func start_shake(strength : float = base_shake_strength) -> void: shake_strength = strength
func get_shake_offset(delta, effect_multiplier = 1) -> Vector2: return Vector2(shake_random.randf_range(-shake_strength,shake_strength) * effect_multiplier,shake_random.randf_range(-shake_strength,shake_strength * effect_multiplier))

func _set_zoom_level(value: float) -> void:
	_zoom_level = clamp(value, min_zoom, max_zoom)
	var previous_zoom : Vector2 = zoom
	var new_zoom : Vector2 = Vector2(_zoom_level, _zoom_level)
	var mouse_position = get_viewport().get_mouse_position()
	
	if new_zoom.x >= max_zoom or new_zoom.x <= min_zoom: return
	
	var delta = new_zoom - previous_zoom
	var mouse_pos : Vector2 = get_global_mouse_position()
	zoom += delta
	var new_mouse_pos : Vector2 = get_global_mouse_position()
	position += mouse_pos - new_mouse_pos

func _unhandled_input(event) -> void:
	if event.is_action_pressed("zoom_in") and zoom_enabled: _set_zoom_level(_zoom_level + zoom_factor)
	if event.is_action_pressed("zoom_out") and zoom_enabled: _set_zoom_level(_zoom_level - zoom_factor)
