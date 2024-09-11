## Event Manager
# Autoloaded
extends Node

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

func combine(first_element, second_element): #? Combine two elements into one more complex essence
	if !COMBINATIONS.has(first_element): return false #! INVALID ELEMENT
	if !COMBINATIONS[first_element].has(second_element): return false ## No combination found
	var result = COMBINATIONS[first_element][second_element]
	if result: return result
	else: return false

func fuse(combination_id : String, add_directly : bool = false) -> Element: #? Recieves an id of an essence generated by the combine function, generates the essence element and stores on the UI
	var combined_essence : Element = Element.new()
	combined_essence.element_type = 1
	combined_essence.element_id = combination_id
	if add_directly: add_element(1, combined_essence)
	return combined_essence

func add_element(type: int, element: Element): UI.HUD.add_element(type, element)

func generate_object( #? Generates a draggable object which can be located on containers in screen and attached into slots
		container : Container,
		home_container : Container,
		source_object : bool,
		element : Element
	) -> DraggableObject:
	var object = DraggableObject.new()
	object.container = container
	object.home_container = home_container ## Return to this node position if something goes wrong or the screen which it was positioned gets closed
	object.source_object = source_object ## Instead of moving the object, creates another one
	object.element = element
	add_child(object)
	return object

func generate_element( #? Generates an element resource that can be as complex as needed
		type : int, ## [0: element, 1: essence]
		id : String, ## [ex.: 'fire', 'water'] 
	) -> Element:
	var new_element = Element.new()
	new_element.element_type = type
	new_element.element_id = id
	add_child(new_element)
	return new_element