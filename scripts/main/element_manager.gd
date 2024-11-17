## ElementManager
# Autoloaded node that controls all necessary functions to modifiy, create, fuse, and other actions to Elements!
# Can be called anywhere on the game, but mostly used in UI actions and events 
extends Node

const BASE_QUANTITY : int = 2
const element_metadata_PATH : String = "res://components/elements/element_metadata.json"
const SPRITES_PATH : String = "res://assets/sprites/elements/"
const TOWER_ROOT_SCENE : PackedScene = preload("res://scenes/towers/tower.tscn")
const CONTROL_SLOT_SCENE : PackedScene = preload("res://scenes/ui/slots/control_slot.tscn")
const DRAGGABLE_ORB_SCENE : PackedScene = preload("res://scenes/ui/drag/draggable_orb.tscn")
const DEFAULT_ELEMENT_COLOR : Color = Color("ffec83")
const STARTING_ELEMENT_REG : Array[ElementRegister] = [
	preload("res://components/elements/default_registers/FireRegister.tres"),
	preload("res://components/elements/default_registers/WaterRegister.tres"),
	preload("res://components/elements/default_registers/AirRegister.tres"),
	preload("res://components/elements/default_registers/EarthRegister.tres")]

var effects : Array[Effect]
var active_registers : Array[ElementRegister]
var element_textures : Dictionary = {}
var element_metadata : Dictionary = {}

#region Main Functions
func _ready() -> void:
	active_registers.append_array(STARTING_ELEMENT_REG)
	element_textures = _load_all_sprites()
	element_metadata = _load_element_metadata()

func _load_element_metadata() -> Dictionary: #? Returns a patched dictionary containing all needed metadata
	var metadata_file : FileAccess = FileAccess.open(element_metadata_PATH, FileAccess.READ)
	var metadata : Dictionary = JSON.parse_string(metadata_file.get_as_text())
	var eid : int = 0
	metadata_file.close()
	for e in metadata: # Patch data to Godot friendly format
		metadata[e]["eid"] = eid
		metadata[e]["root_color"] = Color("#"+metadata[e]["root_color"])
		eid += 1
	return metadata

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
	else: push_error("ElementManager | An error occurred when trying to access the sprites path."); return {}

func _purge(): ## Purge all elements, resetting everything! Used when restarting stages and such
	active_registers.clear()
	active_registers.append_array(STARTING_ELEMENT_REG)
	for r in STARTING_ELEMENT_REG: r.quantity = BASE_QUANTITY #? Reset to base quantity
#endregion

#region Element Manipulation
## Get data from each element metadata. Meta is the string of a key inside the metadata dict of the selected element_id.
func query_metadata(element_id : String, meta : String = "") -> Variant:
	if !element_metadata.has(element_id): #? No key "element_id" found in element_metadata dict
		push_warning(element_id, ' metadata not found in system. Will generate another errors if left unset.')
		return {}
	
	if meta == "": return element_metadata[element_id] #? No meta string given, thus will return full metadata of said element
	else: return element_metadata[element_id][meta] #? Returning specific metadata

## Returns an element ID from two other IDs by checking the metadata dictionary. Only returns the ID, no element is created!
func combine(first_element, second_element) -> String:
	if !element_metadata.has(first_element) or !element_metadata.has(second_element): return "" #! INVALID ELEMENTS
	var combination_dict : Dictionary = element_metadata[first_element]["combinations"]
	if !combination_dict.has(second_element): return "" #! INVALID COMBINATION
	var result = combination_dict[second_element]
	if result: return result
	else: return ""

## Generates a draggable orb which can be located on containers in screen and attached into slots
func generate_orb(element_reg : ElementRegister) -> DraggableOrb:
	var orb = DRAGGABLE_ORB_SCENE.instantiate()
	orb.element_register = element_reg
	orb.element = element_reg.element
	return orb

## Generates an Element resource from an ID and type
func generate_element( 
		type : int, ## [0: element, 1: essence]
		id : String, ## [ex.: "fire", "water"] 
		add_directly : bool = true, ## Determines if it gets created as a fresh node or not
	) -> Element:
	var new_element = Element.new()
	var metadata = query_metadata(id)
	new_element.element_type = type
	new_element.element_id = id
	if !metadata.is_empty(): new_element.element_metadata = metadata
	if add_directly: add_child(new_element)
	return new_element

func split(element_id : String) -> void: ## Divide an essence by destroying it and retrieving its igredients
	var reg = query_element(element_id)
	var recipe = query_metadata(element_id, "recipe")
	# reg.quantity -= 1 # Only in case the orb is not deleted
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
		container : Container = UI.HUD.elements_grid #? Defaults to UI containers
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
		
		var _orb = _set_orb(control_slot.slot, register)
		control_slot.slot.element_register = register
		control_slot.slot.slot_type = element_type
		UI.HUD.bind_element_picked_signal(control_slot.slot.slot_orb_picked)
		
		active_registers.append(register)
		return register
#endregion

#region Integration
func _set_control_slot(reg : ElementRegister) -> ControlSlot: ## Create and define ControlSlot
	var control_slot : ControlSlot = CONTROL_SLOT_SCENE.instantiate()
	control_slot.set_name("{0}{1}".format({0: reg.element.element_id.capitalize(), 1: "Container"}))
	control_slot.slot_register = reg
	return control_slot

func _set_orb(slot : Slot, element_register : ElementRegister, additional : String = "") -> DraggableOrb: ## Create and define DraggableOrb
	var orb : DraggableOrb = generate_orb(element_register)
	var element_id : String = element_register.element.element_id
	orb.set_name("{0}{1}{2}".format({0: element_id.capitalize(), 1: "Object", 2: additional}))
	orb.active_slot = slot
	orb.home_slot = slot
	slot.add_child(orb)
	slot.active_orb = orb
	if element_textures.has(element_id): orb.orb_element_sprite.set_texture(element_textures[element_id])
	else: printerr(element_id, " | Element sprite not found!")
	return orb

func _restock_output(slot : Slot, reg : ElementRegister) -> DraggableOrb: ## Restock slot
	if !slot.is_output: return null
	if reg.quantity >= 1:
		var regen_orb = _set_orb(slot, reg)
		reg.quantity - 1
		# print("ElementManager | New orb generated on", slot.get_path())
		return regen_orb
	else: #! Register empty
		push_warning("ElementManager | Output cannot generate orb because quantity is zero!")
		return null
#endregion
