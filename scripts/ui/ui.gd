class_name Interface
extends CanvasLayer

signal autoplay_toggled(toggle : bool)
signal turn_pass_requested

const DRAGGABLE_OBJECT_SCENE : PackedScene = preload('res://scenes/ui/draggable_object.tscn')
const CONTROL_SLOT_SCENE : PackedScene = preload('res://components/interface/control_slot.tscn')
const STARTING_ELEMENT_REG : Array[ElementRegister] = [
	preload("res://scripts/resources/elements/default_registers/FireRegister.tres"),
	preload("res://scripts/resources/elements/default_registers/WaterRegister.tres"),
	preload("res://scripts/resources/elements/default_registers/AirRegister.tres"),
	preload("res://scripts/resources/elements/default_registers/EarthRegister.tres")
]

@export var active_elements : Array[ElementRegister] #? Acts as a gateway to registers in each slot. Makes it way easier to make UI changes and checks!

@onready var essence_slots : HBoxContainer = $Screen/ElementContainer/EssenceInterface/ScrollContainer/EssenceSlots
@onready var element_slots : HBoxContainer = $Screen/ElementContainer/ElementInterface/ElementSlots
@onready var play_button : TextureButton = $Screen/CornerPanel/PlayButton
@onready var life_icon: TextureButton = $Screen/HUDContainer/LifePanel/DataContainer/LifeIcon
@onready var life_label: Label = $Screen/HUDContainer/LifePanel/DataContainer/LifeLabel
@onready var wave_counter: Label = $Screen/HUDContainer/WaveCounter
@onready var coin_label: Label = $Screen/HUDContainer/LifePanel/DataContainer/CoinLabel
@onready var debug_label : Label = $Screen/HUDContainer/InfoBox/DebugLabel
@onready var tile_description_label : Label = $Screen/HUDContainer/InfoBox/TileDescriptionLabel
@onready var object_description_label : Label = $Screen/HUDContainer/InfoBox/ObjectDescriptionLabel
@onready var draw_container : Control = $DrawContainer

var element_textures : Dictionary = {}
var element_menu_hidden : bool = false

func _ready():
	active_elements.append_array(STARTING_ELEMENT_REG)
	
	var elements_folder = DirAccess.open("res://assets/sprites/elements/")
	if elements_folder:
		elements_folder.list_dir_begin()
		var file_name = elements_folder.get_next()
		while file_name != "":
			if elements_folder.current_is_dir(): pass
			else: #TODO: load sprite to dictionary
				print("Found file: " + file_name)
			file_name = elements_folder.get_next()
	else:
		print("An error occurred when trying to access the path.")

func _on_play_button_pressed(): turn_pass_requested.emit()
func _on_autoplay_button_toggled(toggled_on): autoplay_toggled.emit(toggled_on)
func update_coins(coins : int): coin_label.set_text(str(coins))
func update_life(life : int): life_label.set_text(str(life))
func turn_update(turn : int, max_turn : int): wave_counter.set_text(TranslationServer.tr('TURN {0}/{1}'.format({0: turn, 1: max_turn})))

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
		new_object.element = element
		new_object.home_container = control_slot
		new_object.source_quantity = quantity
		
		control_slot.slot_register = register
		slot_container.add_child(control_slot)
		control_slot.get_child(0).add_child(new_object)
		
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
	Options.show()

const info_default_y : int = 208

func _on_hide_button_pressed() -> void:
	var info_tween : Tween = get_tree().create_tween()
	var hide_tween : Tween = get_tree().create_tween()
	var new_x : int = 0
	var info_new_y : int = info_default_y
	if !element_menu_hidden: # Element menu visible
		new_x = get_viewport().get_visible_rect().size.x - $Screen/CornerPanel.size.x - $Screen/ElementContainer/HideButton.size.x
		info_new_y = info_default_y
		element_menu_hidden = true
	else: #? Element menu invisible
		new_x = 0
		info_new_y = 0
		element_menu_hidden = false
	hide_tween.tween_property($Screen/ElementContainer, "position", Vector2(new_x, $Screen/ElementContainer.position.y), 0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	info_tween.tween_property($Screen/HUDContainer/InfoBox, "position", Vector2(0, info_new_y), 0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN_OUT)
