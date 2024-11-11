class_name Interface
extends CanvasLayer

signal mouse_on_ui_changed(present : bool)
signal autoplay_toggled(toggle : bool)
signal turn_pass_requested

#region Variables
const INFO_DEFAULT_X : int = 11
const INFO_DEFAULT_Y : int = 240
const DEFAULT_LABEL_MODULATE = Color(10,10,10)
const DEFAULT_LABEL_MODULATE_POSITIVE = Color(0.2,20,1)
const DEFAULT_LABEL_MODULATE_NEGATIVE = Color(20,0.2,0.2)
const DEFAULT_LABEL_MODULATE_TIMER : float = 0.5

@export var shop_button_group : ButtonGroup
@export var hide_elements_when_start : bool = true

#region Node references
@onready var stage_meter_bar : TextureProgressBar = $UILayer/TopBar/StageMeter/StageMeterBar
@onready var life_label : Label = $UILayer/TopBar/LifeCounter/LifeLabel
@onready var coin_label : Label = $UILayer/TopBar/CoinCounter/CoinLabel
@onready var options_button : TextureButton = $UILayer/OptionsButton
@onready var elements : HBoxContainer = $UILayer/ElementBar/ScrollContainer/Elements
#endregion

var focus_slot : Slot
var previous_life : int
var previous_coins : int
var mouse_on_ui : bool
#endregion

#region Main functions
func _ready():
	set_visible(false)
	# if hide_elements_when_start: hide_button.pressed.emit()

func update_coins(coins : int): update_label(coin_label, coins, previous_coins); previous_coins = coins

func update_life(life : int): update_label(life_label, life, previous_life); previous_life = life

func turn_update(turn : int, max_turn : int):
	stage_meter_bar.set_max(max_turn)
	stage_meter_bar.set_value(turn)

# func bind_element_picked_signal(emitting_signal : Signal): emitting_signal.connect(_on_element_picked)

func _on_screen_mouse_exited() -> void: pass
#endregion

#region Inputs and buttons
func _input(_event) -> void:
	if Input.is_action_just_pressed('enter'): turn_pass_requested.emit()

func _on_play_button_pressed():
	turn_pass_requested.emit()
	if UI.wave_is_active: UI.toggle_speed(!UI.speed_toggled)

func _on_autoplay_button_toggled(toggled_on): autoplay_toggled.emit(toggled_on)

func update_label(label : Label, new_value : int, previous_value : int, timer : float = DEFAULT_LABEL_MODULATE_TIMER):
	var modulate_color : Color
	var modulate_tween : Tween = get_tree().create_tween()
	label.set_text(str(new_value))
	if new_value > previous_value: modulate_color = DEFAULT_LABEL_MODULATE_POSITIVE
	else: modulate_color = DEFAULT_LABEL_MODULATE_NEGATIVE
	label.set_modulate(modulate_color)
	modulate_tween.tween_property(label, "modulate", Color(1,1,1), timer)

func _on_options_button_pressed() -> void:
	if options_button.button_pressed: Options.show()
	else: Options._on_exit_menu_pressed()

func _on_hide_fuse_menu_button_pressed() -> void:
	var hide_tween : Tween = get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var new_x : int = 0
	'''
	if fuse_system.visible:
		new_x = -(hide_button.size.x)
		hide_button.flip_h = false
		fuse_system.pop()
	else:
		fuse_system.set_visible(true)
		new_x = -(element_bar.size.x)
		hide_button.flip_h = true
	
	hide_tween.tween_property(element_bar, "position", Vector2(new_x, element_bar.position.y), 0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	await hide_tween.finished
	fuse_system.visible = !fuse_system.visible
	'''

## Mouse detector - Useful to prevent positioning/interacting with objects behind UI buttons
func _on_mouse_detector_mouse_entered() -> void: mouse_on_ui = false; mouse_on_ui_changed.emit(false)
func _on_mouse_detector_mouse_exited() -> void: mouse_on_ui = true; mouse_on_ui_changed.emit(true)
func _on_mouse_on_ui_changed(present: bool) -> void: pass # print('Mouse on ui: ', mouse_on_ui)
#endregion
