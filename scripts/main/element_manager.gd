## ElementManager
# Autoloaded node that controls all necessary functions to modifiy, create, fuse, and other actions to Elements!
# Can be called anywhere on the game, but mostly used in UI actions and events 
extends Node

const SPRITES_PATH : String = "res://assets/sprites/elements/"
const CONTROL_SLOT_SCENE : PackedScene = preload('res://components/interface/control_slot.tscn')
const DRAGGABLE_OBJECT_SCENE : PackedScene = preload("res://components/interface/draggable_object.tscn")
const DEFAULT_ELEMENT_COLOR : Color = Color("ffec83")
const STARTING_ELEMENT_REG : Array[ElementRegister] = [
	preload("res://components/elements/default_registers/FireRegister.tres"),
	preload("res://components/elements/default_registers/WaterRegister.tres"),
	preload("res://components/elements/default_registers/AirRegister.tres"),
	preload("res://components/elements/default_registers/EarthRegister.tres")]
const ELEMENT_METADATA : Dictionary = {
	"fire": {
		"root_color": Color.ORANGE_RED
	},
	"water": {
		"root_color": Color.BLUE
	},
	"air": {
		"root_color": Color.CYAN
	},
	"earth": {
		"root_color": Color.SADDLE_BROWN
	},
	"cursed": {
		"root_color": Color.CRIMSON
	}
}
const COMBINATIONS : Dictionary = {
	"fire": {
		"fire": "conflagration",
		"water": "steam",
		"air": 'lightning',
		'earth': 'metal',
		'cursed': 'scorch'
	},
	'water': {
		'water': 'ice',
		'fire': 'steam',
		'earth': 'oil',
		'air':  'rain',
		'cursed': 'abyss'
	},
	'air': {
		'air': 'turbulence',
		'water': 'rain',
		'fire': 'lightning',
		'earth': 'dust',
		'cursed': 'miasma'
	},
	'earth': {
		'earth': 'mountain',
		'fire': 'metal',
		'water': 'oil',
		'air': 'dust',
		'cursed': 'rot'
	},
	'cursed': {
		'cursed': 'profaned'
	}
}

var active_registers : Array[ElementRegister]
var element_textures : Dictionary = {}

#region Main Functions
func _ready() -> void:
	active_registers.append_array(STARTING_ELEMENT_REG)
	element_textures = _load_all_sprites()

func _load_all_sprites() -> Dictionary: #? Returns a indexable dictionary of sprites that should have the same file name as the element ID (both strings)
	var elements_folder = DirAccess.open(SPRITES_PATH)
	if elements_folder:
		var elements_dict : Dictionary
		elements_folder.list_dir_begin()
		var file_name = elements_folder.get_next()
		while file_name != "":
			if elements_folder.current_is_dir(): pass #? Found directory, skip.
			elif file_name.ends_with(".import"): #? Found an import file
				var file = file_name.split(".") #? Will result in an array consisting in something similar as this: "['file_name', '[extension]', '.import']"
				if elements_dict.has(file[0]): pass #? File was already loaded, skipping.
				else: #? File not found in dict, thus loaded
					var file_path = str(SPRITES_PATH + file[0] + '.' + file[1])
					elements_dict[file[0]] = load(file_path)
			else: pass #? Normal file
			file_name = elements_folder.get_next()
		return elements_dict
	else:
		push_error("An error occurred when trying to access the sprites path via DraggableObjectSprite class.")
		return {}

## Purge all elements, resetting everything! Used when restarting stages and such
func _purge():
	active_registers.clear()
	active_registers.append_array(STARTING_ELEMENT_REG)
	for r in STARTING_ELEMENT_REG: r.quantity = 2 #? Reset to base quantity
#endregion

#region Element Manipulation
## Get data from each element metadata. Meta is the string of a key inside the metadata dict of the selected element_id.
func query_metadata(element_id : String, meta : String) -> Variant:
	if !ELEMENT_METADATA.has(element_id): print('NOT FOUND!'); return null
	return ELEMENT_METADATA[element_id][meta]

## Returns an element ID from two other IDs by checking the COMBINATIONS dictionary
func combine(first_element, second_element) -> String: 
	if !COMBINATIONS.has(first_element) or !COMBINATIONS.has(second_element): return '' #! INVALID ELEMENTS
	if !COMBINATIONS[first_element].has(second_element): return ' '#! No combination found
	var result = COMBINATIONS[first_element][second_element]
	if result: return result
	else: return ''

## Recieves an ID of an essence generated by the combine function, returns the new_element
func fuse(combination_id : String, add_directly : bool = false) -> Element: 
	var combined_essence : Element = Element.new()
	combined_essence.element_type = 1
	combined_essence.element_id = combination_id
	if add_directly: add_element(combined_essence)
	return combined_essence

## Generates a draggable object which can be located on containers in screen and attached into slots
func generate_object(element : Element) -> DraggableObject:
	var object = DRAGGABLE_OBJECT_SCENE.instantiate()
	object.element = element
	return object

## Generates an Element resource from an ID and type
func generate_element( 
		type : int, ## [0: element, 1: essence]
		id : String, ## [ex.: 'fire', 'water'] 
	) -> Element:
	var new_element = Element.new()
	new_element.element_type = type
	new_element.element_id = id
	add_child(new_element)
	return new_element

## Query an element to see if it already exists on the runtime array
func query_element(id : String) -> ElementRegister:
	for reg in active_registers: if id == reg.element.element_id: return reg
	return null

## Add to an existing element or a new one to ElementRegister array, as well as creating the required nodes
func add_element(
		element : Element, #? Element resource to add
		element_type : int = 1, #? 1 is Essence, 2 is Element
		quantity : int = 1, #? How many charges will be added
		container : Container = UI.HUD._request_container(element.element_type) #? Defaults to UI containers
	) -> ElementRegister:
	
	assert(container)
	var register : ElementRegister = query_element(element.element_id)
	if register: #? Element already exists on register
		register.quantity += quantity
		return register
	else: #? New element
		register = ElementRegister.new()
		register.element = element
		register.quantity = quantity
		register.element.element_type = element_type
		
		var control_slot : ControlSlot = _set_control_slot(register)
		container.add_child(control_slot)
		control_slot.slot.slot_type = element_type
		register.control_slot = control_slot.get_path()
		register.slot = control_slot.slot.get_path()
		
		var _object = _set_object(control_slot.slot, element)
		control_slot.slot.element_register = register
		control_slot.slot.slot_type = element_type
		UI.HUD.bind_element_picked_signal(control_slot.slot.slot_object_picked)
		
		active_registers.append(register)
		return register
#endregion

#region Integration
## Create and define ControlSlot
func _set_control_slot(reg : ElementRegister) -> ControlSlot:
	var control_slot : ControlSlot = CONTROL_SLOT_SCENE.instantiate()
	control_slot.set_name('{0}{1}'.format({0: reg.element.element_id.capitalize(), 1: 'Container'}))
	control_slot.slot_register = reg
	return control_slot

## Create and define DraggableObject
func _set_object(slot : Slot, element : Element, additional : String = '') -> DraggableObject:
	var object : DraggableObject = generate_object(element)
	object.set_name('{0}{1}{2}'.format({0: element.element_id.capitalize(), 1: 'Object', 2: additional}))
	object.active_slot = slot
	object.home_slot = slot
	slot.add_child(object)
	slot.active_object = object
	
	if element_textures.has(element.element_id): object.object_element_sprite.set_texture(element_textures[element.element_id])
	else: printerr(element.element_id, ' | Element sprite not found!')
	return object

## Restock slot
func _restock_output(slot : Slot, reg : ElementRegister) -> DraggableObject:
	if !slot.is_output: return null
	if reg.quantity >= 1:
		var regen_object = _set_object(slot, reg.element)
		reg.quantity - 1
		# print('ElementManager | New object generated on', slot.get_path())
		return regen_object
	else: #! Register empty
		push_warning('ElementManager | Output cannot generate object because quantity is zero!')
		return null
#endregion
