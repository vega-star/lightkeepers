## ElementManager
# Autoloaded node that controls all necessary functions to modifiy, create, fuse, and other actions to Elements!
# Can be called anywhere on the game, but mostly used in UI actions and events 
extends Node

const BASE_QUANTITY : int = 2
const SPRITES_PATH : String = "res://assets/sprites/elements/"
const CONTROL_SLOT_SCENE : PackedScene = preload("res://components/interface/control_slot.tscn")
const DRAGGABLE_OBJECT_SCENE : PackedScene = preload("res://components/interface/draggable_object.tscn")
const DEFAULT_ELEMENT_COLOR : Color = Color("ffec83")
const STARTING_ELEMENT_REG : Array[ElementRegister] = [
	preload("res://components/elements/default_registers/FireRegister.tres"),
	preload("res://components/elements/default_registers/WaterRegister.tres"),
	preload("res://components/elements/default_registers/AirRegister.tres"),
	preload("res://components/elements/default_registers/EarthRegister.tres")]

const ELEMENT_METADATA : Dictionary = {
	"fire": {
		"type": 0,
		"root_color": Color.ORANGE_RED,
		"combinations": {
			"fire": "conflagration",
			"water": "steam",
			"air": "lightning",
			"earth": "metal",
			"cursed": "scorch"
		}
	},
	"conflagration": {
		"type": 1,
		"root_color": Color.RED,
		"recipe": ["fire", "fire"],
		"combinations": {}
	},
	"water": {
		"type": 0,
		"root_color": Color.BLUE,
		"effect": {
			
		},
		"combinations": {
			"water": "ice",
			"fire": "steam",
			"earth": "oil",
			"air":  "rain",
			"cursed": "abyss"
		}
	},
	"ice": {
		"type": 1,
		"root_color": Color.AQUA,
		"recipe": ["water", "water"],
		"combinations": {}
	},
	"air": {
		"type": 0,
		"root_color": Color.LIGHT_GRAY,
		"combinations": {
			"air": "turbulence",
			"water": "rain",
			"fire": "lightning",
			"earth": "dust",
			"cursed": "miasma"
		}
	},
	"turbulence": {
		"type": 1,
		"root_color": Color.DARK_GRAY,
		"recipe": ["turbulence", "turbulence"],
		"combinations": {}
	},
	"earth": {
		"type": 0,
		"root_color": Color.SADDLE_BROWN,
		"combinations": {
			"earth": "rock",
			"fire": "metal",
			"water": "oil",
			"air": "dust",
			"cursed": "rot"
		}
	},
	"rock": {
		"type": 1,
		"root_color": Color.DARK_SLATE_GRAY,
		"recipe": ["earth", "earth"],
		"combinations": {}
	},
	"cursed": {
		"type": 0,
		"root_color": Color.CRIMSON,
		"combinations": {
			"cursed": "profaned"
		}
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
				var file = file_name.split(".") #? Will result in an array consisting in something similar as this: "["file_name", "[extension]", ".import"]"
				if elements_dict.has(file[0]): pass #? File was already loaded, skipping.
				else: #? File not found in dict, thus loaded
					var file_path = str(SPRITES_PATH + file[0] + "." + file[1])
					elements_dict[file[0]] = load(file_path)
			else: pass #? Normal file
			file_name = elements_folder.get_next()
		return elements_dict
	else:
		push_error("An error occurred when trying to access the sprites path via DraggableObjectSprite class.")
		return {}

func _purge(): ## Purge all elements, resetting everything! Used when restarting stages and such
	active_registers.clear()
	active_registers.append_array(STARTING_ELEMENT_REG)
	for r in STARTING_ELEMENT_REG: r.quantity = BASE_QUANTITY #? Reset to base quantity
#endregion

#region Element Manipulation
func query_metadata(element_id : String, meta : String = "") -> Variant: ## Get data from each element metadata. Meta is the string of a key inside the metadata dict of the selected element_id.
	if !ELEMENT_METADATA.has(element_id): print("NOT FOUND!"); return null #? No key "element_id" found in element_metadata dict
	if meta == "": return ELEMENT_METADATA[element_id] #? No meta string given, thus will return full metadata
	else: return ELEMENT_METADATA[element_id][meta] #? Returning specific metadata

func combine(first_element, second_element) -> String: ## Returns an element ID from two other IDs by checking the metadata dictionary. Only returns the ID, no element is created!
	if !ELEMENT_METADATA.has(first_element) or !ELEMENT_METADATA.has(second_element): return "" #! INVALID ELEMENTS
	var combination_dict : Dictionary = ELEMENT_METADATA[first_element]["combinations"]
	if !combination_dict.has(second_element): return "" #! INVALID COMBINATION
	var result = combination_dict[second_element]
	if result: return result
	else: return ""

func generate_object(element : Element) -> DraggableObject: ## Generates a draggable object which can be located on containers in screen and attached into slots
	var object = DRAGGABLE_OBJECT_SCENE.instantiate()
	object.element = element
	return object

## Generates an Element resource from an ID and type
func generate_element( 
		type : int, ## [0: element, 1: essence]
		id : String, ## [ex.: "fire", "water"] 
		add_directly : bool = true, ## Determines if it gets created as a fresh node or not
	) -> Element:
	var new_element = Element.new()
	new_element.element_type = type
	new_element.element_id = id
	if add_directly: add_child(new_element)
	return new_element

func split(element_id : String) -> void: ## Divide an essence by destroying it and retrieving its igredients
	var reg = query_element(element_id)
	var recipe = query_metadata(element_id, "recipe")
	# reg.quantity -= 1 # Only in case the object is not deleted
	for e in recipe:
		var element : Element = Element.new()
		element.element_type = 1
		element.element_id = e
		add_element(element)

func query_element(id : String) -> ElementRegister: ## Query an element to see if it already exists on the runtime array
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
func _set_control_slot(reg : ElementRegister) -> ControlSlot: ## Create and define ControlSlot
	var control_slot : ControlSlot = CONTROL_SLOT_SCENE.instantiate()
	control_slot.set_name("{0}{1}".format({0: reg.element.element_id.capitalize(), 1: "Container"}))
	control_slot.slot_register = reg
	return control_slot

func _set_object(slot : Slot, element : Element, additional : String = "") -> DraggableObject: ## Create and define DraggableObject
	var object : DraggableObject = generate_object(element)
	object.set_name("{0}{1}{2}".format({0: element.element_id.capitalize(), 1: "Object", 2: additional}))
	object.active_slot = slot
	object.home_slot = slot
	slot.add_child(object)
	slot.active_object = object
	
	if element_textures.has(element.element_id): object.object_element_sprite.set_texture(element_textures[element.element_id])
	else: printerr(element.element_id, " | Element sprite not found!")
	return object

func _restock_output(slot : Slot, reg : ElementRegister) -> DraggableObject: ## Restock slot
	if !slot.is_output: return null
	if reg.quantity >= 1:
		var regen_object = _set_object(slot, reg.element)
		reg.quantity - 1
		# print("ElementManager | New object generated on", slot.get_path())
		return regen_object
	else: #! Register empty
		push_warning("ElementManager | Output cannot generate object because quantity is zero!")
		return null
#endregion
