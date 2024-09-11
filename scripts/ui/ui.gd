class_name Interface
extends CanvasLayer

signal autoplay_toggled(toggle : bool)
signal turn_pass_requested

const TIME_SCALE_MULTIPLY : int = 4
const DRAGGABLE_OBJECT_SCENE : PackedScene = preload('res://components/interface/object.tscn')
const CONTROL_SLOT_SCENE : PackedScene = preload('res://components/interface/control_slot.tscn')
const STARTING_ELEMENT_REG : Array[ElementRegister] = [
	preload("res://scripts/resources/elements/default_registers/FireRegister.tres"),
	preload("res://scripts/resources/elements/default_registers/WaterRegister.tres"),
	preload("res://scripts/resources/elements/default_registers/AirRegister.tres"),
	preload("res://scripts/resources/elements/default_registers/EarthRegister.tres")]
const INFO_DEFAULT_X : int = 11
const INFO_DEFAULT_Y : int = 240
const DEFAULT_LABEL_MODULATE = Color(10,10,10)
const DEFAULT_LABEL_MODULATE_POSITIVE = Color(0.2,20,1)
const DEFAULT_LABEL_MODULATE_NEGATIVE = Color(20,0.2,0.2)
const DEFAULT_LABEL_MODULATE_TIMER : float = 0.5

@export var shop_button_group : ButtonGroup
@export var hide_elements_when_start : bool = true

@onready var essence_slots : GridContainer = $Screen/Shop/Elements/ElementsScrollContainer/ElementsGrid
@onready var element_slots : BoxContainer = $Screen/Elements/ElementContainer/ElementInterface/ElementSlots
@onready var play_button: TextureButton = $Screen/CornerPanel/PlayButton
@onready var life_icon: TextureButton = $Screen/Status/DataContainer/LifeIcon
@onready var life_label: Label = $Screen/Status/DataContainer/LifeLabel
@onready var wave_counter: Label = $Screen/Status/TurnContainer/WaveCounter
@onready var coin_label: Label = $Screen/Status/DataContainer/CoinLabel
@onready var options_button: TextureButton = $Screen/Tools/OptionsButton
@onready var hide_button : TextureButton = $Screen/Elements/HideButton
@onready var corner_panel : Panel = $Screen/CornerPanel
@onready var towers_panel : Panel = $Screen/Shop/Towers
@onready var elements_storage_panel : Panel = $Screen/Shop/Elements
@onready var element_container : BoxContainer = $Screen/Elements
@onready var elements_grid : GridContainer = $Screen/Shop/Elements/ElementsScrollContainer/ElementsGrid
@onready var info_container : VBoxContainer = $Screen/Info
@onready var debug_label : Label = $Screen/Info/DebugLabel
@onready var tile_description_label : Label = $Screen/Info/TileDescriptionLabel
@onready var object_description_label : Label = $Screen/Info/ObjectDescriptionLabel
@onready var tower_panel : TowerPanel = $Screen/TowerPanel

var active_elements : Array[ElementRegister] #? Acts as a gateway to registers in each slot
var previous_life : int
var previous_coins : int
var element_textures : Dictionary = {}
var element_menu_hidden : bool = false
var speed_toggled : bool = false

func _ready():
	set_visible(false)
	active_elements.append_array(STARTING_ELEMENT_REG)
	var temp_dos : DraggableObjectSprite = DraggableObjectSprite.new()
	element_textures = temp_dos.load_all_sprites()
	temp_dos.queue_free()
	
	if hide_elements_when_start: hide_button.pressed.emit()
	for button in shop_button_group.get_buttons():
		button.pressed.connect(func(): _on_shop_button_pressed(button.get_index()))

func _on_shop_button_pressed(index : int):
	match index:
		0: #! Towers buttons pressed
			elements_storage_panel.set_visible(false)
			towers_panel.set_visible(true)
		1: #! Elements buttons pressed
			towers_panel.set_visible(false)
			elements_storage_panel.set_visible(true)

func _on_play_button_pressed(): turn_pass_requested.emit()
func _on_autoplay_button_toggled(toggled_on): autoplay_toggled.emit(toggled_on)

func update_label(label : Label, new_value : int, previous_value : int, timer : float = DEFAULT_LABEL_MODULATE_TIMER):
	var modulate_color : Color
	var modulate_tween : Tween = get_tree().create_tween()
	label.set_text(str(new_value))
	if new_value > previous_value: modulate_color = DEFAULT_LABEL_MODULATE_POSITIVE
	elif new_value < previous_value: modulate_color = DEFAULT_LABEL_MODULATE_NEGATIVE
	label.set_modulate(modulate_color)
	modulate_tween.tween_property(label, "modulate", Color(1,1,1), timer)
func update_coins(coins : int): update_label(coin_label, coins, previous_coins); previous_coins = coins
func update_life(life : int): update_label(life_label, life, previous_life); previous_life = life
func turn_update(turn : int, max_turn : int): wave_counter.set_text(TranslationServer.tr('{0}/{1}'.format({0: turn, 1: max_turn})))

func add_element(element_type : int, element : Element, quantity : int = 1):
	var register : ElementRegister
	var element_registered : bool = false
	var slot_container : Container
	match element_type: #? Chose container based on type
		0: slot_container = element_slots
		1: slot_container = essence_slots
	
	for reg in active_elements:
		if element.element_id == reg.element.element_id: 
			element_registered = true
			register = reg
			break
	
	if element_registered: #? Element already exists on register
		register.quantity += quantity
	else: #? New element
		register = ElementRegister.new()
		var control_slot : ControlSlot = CONTROL_SLOT_SCENE.instantiate()
		var new_object : DraggableObject = DRAGGABLE_OBJECT_SCENE.instantiate()
		var element_string = element.element_id.capitalize()
		
		control_slot.set_name('{0}{1}'.format({0: element_string, 1: 'Container'}))
		new_object.set_name('{0}{1}'.format({0: element_string, 1: 'Object'}))
		
		control_slot.slot_register = register
		slot_container.add_child(control_slot)
		control_slot.get_child(0).add_child(new_object)
		
		element.element_type = 2
		
		new_object.element = element
		new_object.active_slot = control_slot.slot
		new_object.home_slot = control_slot.slot
		control_slot.slot.slot_type = 2
		
		register.element = element
		register.control_slot = control_slot.get_path()
		register.slot = control_slot.slot.get_path()
		register.quantity = quantity
		active_elements.append(register)

func _input(event) -> void:
	if Input.is_action_just_pressed('enter'): turn_pass_requested.emit()

func _on_screen_mouse_exited() -> void:
	pass

func _on_options_button_pressed() -> void:
	if options_button.button_pressed: Options.show()
	else: Options._on_exit_menu_pressed()

func _on_hide_button_pressed() -> void:
	var info_tween : Tween = get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var hide_tween : Tween = get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var new_x : int = 0
	# var info_new_y : int = INFO_DEFAULT_Y
	
	if !element_menu_hidden: # Element menu visible
		new_x = get_viewport().get_visible_rect().size.x - corner_panel.size.x - hide_button.size.x
		# info_new_y = get_viewport().get_visible_rect().size.y - info_container.size.y - INFO_DEFAULT_X
		element_menu_hidden = true
		hide_button.flip_h = false
	else: #? Element menu invisible
		new_x = get_viewport().get_visible_rect().size.x - element_container.size.x
		# info_new_y = INFO_DEFAULT_Y
		element_menu_hidden = false
		# hide_button.flip_h = true
	
	hide_tween.tween_property(element_container, "position", Vector2(new_x, element_container.position.y), 0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	# info_tween.tween_property(info_container, "position", Vector2(INFO_DEFAULT_X, info_new_y), 0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

func _on_speed_button_pressed() -> void:
	if !speed_toggled: Engine.time_scale = TIME_SCALE_MULTIPLY; speed_toggled = true
	else: Engine.time_scale = 1; speed_toggled = false
