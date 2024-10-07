class_name Interface
extends CanvasLayer

signal autoplay_toggled(toggle : bool)
signal turn_pass_requested

#region Variables
const TIME_SCALE_MULTIPLY : int = 4
const INFO_DEFAULT_X : int = 11
const INFO_DEFAULT_Y : int = 240
const DEFAULT_LABEL_MODULATE = Color(10,10,10)
const DEFAULT_LABEL_MODULATE_POSITIVE = Color(0.2,20,1)
const DEFAULT_LABEL_MODULATE_NEGATIVE = Color(20,0.2,0.2)
const DEFAULT_LABEL_MODULATE_TIMER : float = 0.5

@export var shop_button_group : ButtonGroup
@export var hide_elements_when_start : bool = true

#region Screen Nodes
@onready var life_icon : TextureButton = $UILayer/Screen/Status/DataContainer/LifeIcon
@onready var life_label : Label = $UILayer/Screen/Status/DataContainer/LifeLabel
@onready var wave_counter : Label = $UILayer/Screen/Status/TurnContainer/WaveCounter
@onready var coin_label : Label = $UILayer/Screen/Status/DataContainer/CoinLabel
@onready var info_container : VBoxContainer = $UILayer/Screen/Info
@onready var debug_label : Label = $UILayer/Screen/Info/DebugLabel
@onready var tile_description_label : Label = $UILayer/Screen/Info/TileDescriptionLabel
@onready var object_description_label : Label = $UILayer/Screen/Info/ObjectDescriptionLabel
@onready var options_button : TextureButton = $UILayer/Screen/Tools/OptionsButton
#endregion

#region Menu Nodes
@onready var essence_slots : GridContainer = $UILayer/Menu/Shop/Elements/ElementsScrollContainer/ElementsGrid
@onready var element_slots : BoxContainer = $UILayer/Menu/Elements/ElementContainer/ElementInterface/ElementSlots
@onready var play_button : TextureButton = $UILayer/Menu/CornerPanel/CornerContainer/PlayButton
@onready var hide_button : TextureButton = $UILayer/Menu/Elements/HideButton
@onready var corner_panel : Panel = $UILayer/Menu/CornerPanel
@onready var towers_panel : Panel = $UILayer/Menu/Shop/Towers
@onready var elements_storage_panel : Panel = $UILayer/Menu/Shop/Elements
@onready var element_container : BoxContainer = $UILayer/Menu/Elements
@onready var element_container_storage : BoxContainer = $UILayer/Menu/Elements/ElementContainer
@onready var elements_grid : GridContainer = $UILayer/Menu/Shop/Elements/ElementsScrollContainer/ElementsGrid
@onready var fuse_system : FuseSystem = $UILayer/Menu/Elements/ElementContainer/FusePanel/FuseSystem
@onready var tower_name_button : Button = $UILayer/Menu/Shop/Towers/TowerName/TowerNameButton
@onready var tower_grid : GridContainer = $UILayer/Menu/Shop/Towers/TowerScrollContainer/TowerGrid
@onready var element_button : TextureButton = $UILayer/Menu/CornerPanel/CornerContainer/ElementButton
#endregion

@onready var tower_panel : TowerPanel = $UILayer/TowerPanel

var previous_life : int
var previous_coins : int
var element_menu_hidden : bool = false
var speed_toggled : bool = false
#endregion

#region Main functions
func _ready():
	set_visible(false)
	if hide_elements_when_start: hide_button.pressed.emit()
	for tower_button in tower_grid.get_children():
		if !tower_button.is_node_ready(): await tower_button.ready
		tower_button.tower_selected.connect(_update_tower_name.bind(
			tower_button.tower,
			tower_button.tower_name
		))

func update_coins(coins : int): update_label(coin_label, coins, previous_coins); previous_coins = coins

func update_life(life : int): update_label(life_label, life, previous_life); previous_life = life

func turn_update(turn : int, max_turn : int): wave_counter.set_text('{0}/{1}'.format({0: turn, 1: max_turn}))

func bind_element_picked_signal(emitting_signal : Signal): emitting_signal.connect(_on_element_picked)

func _on_element_picked(reg : ElementRegister) -> void:
	$UILayer/Menu/Shop/Elements/ElementName/ElementNameButton.set_text(reg.element.element_id.capitalize())

func _on_screen_mouse_exited() -> void: pass

func _purge_elements() -> void: for c in elements_grid.get_children(): c.queue_free()
#endregion

#region Inputs and buttons
func _input(_event) -> void:
	if Input.is_action_just_pressed('enter'): turn_pass_requested.emit()
	if Input.is_action_just_pressed('switch_menu'): element_button.set_pressed(!element_button.button_pressed)

func _on_play_button_pressed(): turn_pass_requested.emit()

func _on_autoplay_button_toggled(toggled_on): autoplay_toggled.emit(toggled_on)

func _update_tower_name(_tower : Tower, tname : String):
	tower_name_button.set_text(tname)

func update_label(label : Label, new_value : int, previous_value : int, timer : float = DEFAULT_LABEL_MODULATE_TIMER):
	var modulate_color : Color
	var modulate_tween : Tween = get_tree().create_tween()
	label.set_text(str(new_value))
	if new_value > previous_value: modulate_color = DEFAULT_LABEL_MODULATE_POSITIVE
	elif new_value < previous_value: modulate_color = DEFAULT_LABEL_MODULATE_NEGATIVE
	label.set_modulate(modulate_color)
	modulate_tween.tween_property(label, "modulate", Color(1,1,1), timer)

func _on_options_button_pressed() -> void:
	if options_button.button_pressed: Options.show()
	else: Options._on_exit_menu_pressed()

func _on_hide_button_pressed() -> void:
	var hide_tween : Tween = get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var new_x : int = 0
	
	if !element_menu_hidden: # Element menu visible
		new_x = roundi(get_viewport().get_visible_rect().size.x - corner_panel.size.x - hide_button.size.x)
		element_menu_hidden = true
		hide_button.flip_h = false
		fuse_system.pop()
	else: #? Element menu invisible
		new_x = roundi(get_viewport().get_visible_rect().size.x - element_container.size.x)
		element_menu_hidden = false
		if !element_container_storage.visible: element_container_storage.visible = true
		hide_button.flip_h = true
	
	hide_tween.tween_property(element_container, "position", Vector2(new_x, element_container.position.y), 0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	await hide_tween.finished
	
	element_container_storage.visible = !element_menu_hidden
	fuse_system._remove_prop()

func _on_element_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		towers_panel.set_visible(false)
		elements_storage_panel.set_visible(true)
	else:
		elements_storage_panel.set_visible(false)
		towers_panel.set_visible(true)

func _on_speed_button_pressed() -> void:
	if !speed_toggled: Engine.time_scale = TIME_SCALE_MULTIPLY; speed_toggled = true
	else: Engine.time_scale = 1; speed_toggled = false
#endregion

#region Elements and DraggableObjects
func _request_container(element_type : int) -> Container:
	var slot_container : Container
	match element_type: #? Chose container based on type
		0: slot_container = element_slots
		1: slot_container = essence_slots
		_: slot_container = essence_slots
	return slot_container
#endregion
