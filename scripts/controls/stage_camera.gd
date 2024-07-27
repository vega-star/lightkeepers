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
@export var zoom_enabled : bool = true
@export var dynamic_zoom : bool = false
@export var camera_debug : bool = false

const click_threshold = 0.2

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

@onready var center_marker = $CenterMarker

func _process(delta):
	current_pos = get_viewport().get_mouse_position()
	
	if clicked:
		click_lock = true
		var diff : Vector2 = (stored_pos - current_pos)
		stored_pos = current_pos
		stored_offset += diff
		set_offset(stored_offset)
	elif !clicked and click_lock:
		global_position = to_global(offset)
		set_offset(Vector2.ZERO)
		stored_offset = Vector2.ZERO
		click_lock = false
	
	if camera_debug: UI.debug_label.set_text('MOUSE_POS: {4}\nG_POSITION: {0}\nOFFSET: {1}\nSTORED_OFFSET: {2}\nSTORED_POSITION: {3}\nGLOBAL_OFFSET_POSITION: {5}'.format({0: global_position, 1: offset, 2: stored_offset, 3: stored_pos, 4:current_pos, 5: to_global(offset)}))

func _input(event):
	if event.is_action_pressed("drag_zoom"): 
		clicked = true
		stored_offset = Vector2.ZERO
		stored_pos = get_viewport().get_mouse_position()
	elif event.is_action_released("drag_zoom"): 
		clicked = false

func _set_zoom_level(value: float):
	_zoom_level = clamp(value, min_zoom, max_zoom)
	var previous_zoom : Vector2 = zoom
	var new_zoom : Vector2 = Vector2(_zoom_level, _zoom_level)
	
	zoom_tween = get_tree().create_tween()
	zoom_tween.tween_property(self, "zoom", new_zoom, zoom_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	
	if new_zoom.x >= max_zoom or new_zoom.x <= min_zoom: return # Cancel zoom if it exceeds zoom limits
	if dynamic_zoom: _set_zoom_position(previous_zoom - new_zoom)

func _set_zoom_position(delta : Vector2):
	var mouse_position = get_viewport().get_mouse_position()
	global_position = lerp(global_position, mouse_position, mouse_zoom_factor * zoom.x)

func _unhandled_input(event):
	if event.is_action_pressed("zoom_in") and zoom_enabled: _set_zoom_level(_zoom_level + zoom_factor)
	if event.is_action_pressed("zoom_out") and zoom_enabled: _set_zoom_level(_zoom_level - zoom_factor)

# func limit_by_rect(rectangle : Rect2): #TODO? MAYBE
