class_name DraggableObjectSprite extends Sprite2D

const DEFAULT_ORB_TEXTURE = preload("res://assets/sprites/misc/orb.png")
const SPRITES_PATH : String = "res://assets/sprites/elements/"

var element_sprite : Sprite2D
var element_orb : Sprite2D

func _ready() -> void:
	element_orb = Sprite2D.new()
	add_child(element_orb)

func load_all_sprites() -> Dictionary: #? Returns a indexable dictionary of sprites that should have the same file name as the element ID (both strings)
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
					print(file)
					print(file_path)
					print(elements_dict[file[0]])
			else: pass #? Normal file
			file_name = elements_folder.get_next()
		
		return elements_dict
	else:
		push_error("An error occurred when trying to access the sprites path via DraggableObjectSprite class.")
		return {}
