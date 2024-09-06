## OPTIONS
# This is a framework for changing important game configurations like volume, resolution, effects and such on a interactable menu
# This menu can also be heavily modified and personalized to each project. Just be sure to reconnect the nodes!
# All information necessary is loaded from a single ConfigFile, and if it doesn't exist or it is the first load, it will create it
# Don't set this as a class, as it creates conflict when autoloaded.
extends CanvasLayer

signal config_file_loaded #? Used to wait until the file is correctly loaded
signal options_changed #? Useful to reset triggers and player behavior
signal language_changed #? Emits for certain nodes that needs TranslationServer to run again after a language is changed

#region | Core Configuration
@export_group("Main Configuration")
@export var reset_window_size_on_boot : bool = false #? If true, loads the last resolution/window size
@export var menu_button_group : ButtonGroup #? Useful, but remember that button groups cannot be multiple toggle buttons. This is better with right/left options.

@export_group("Tools")
@export var reset_config_on_load : bool = false #? Will override ConfigFile with a completely new one loading default values stored on the constant.
@export var show_keycode : bool = false #? Print the exact keycode for an input pressed anytime
@export var debug : bool = false #? Print messages in some actions for direct debug

const DEFAULT_RESOLUTION : Vector2 = Vector2(1280, 720) #? Can change to each project
const KEYBIND_FILE_PATH : String = "user://keybindings.json"
const CONFIG_FILE_PATH : String = "user://config.cfg"
const TEMP_CONFIG_FILE_PATH : String = "user://temp.cfg"
const LANG_ORDER : Array = ["en","pt-br"]
const SCREEN_DICT : Array = [ #? Different configurations to screen (Borderless is still bugged, TODO)
	"WINDOWED",
	"WINDOWED + BORDERLESS",
	"MAXIMIZED",
	"FULLSCREEN",
	"EXCLUSIVE FULLSCREEN"
]
const DEFAULT_KEY_DICT : Dictionary = { #? Default keybinds that is loaded when the game is first loaded. This needs to change to each game!
	"enter": 4194309,
	"escape": 4194305,
	"space": 32,
	"move_up": 4194320,
	"move_down": 4194322,
	"move_left": 4194319,
	"move_right": 4194321
	
}
const DEFAULT_CONFIGURATIONS : Dictionary = { #? Default keybinds that is loaded when the game is first loaded
	"window_mode": ["MAIN_OPTIONS","WINDOW_MODE", "WINDOW_MODE_WINDOWED"],
	"window_size": ["MAIN_OPTIONS","MINIMUM_WINDOW_SIZE", DEFAULT_RESOLUTION],
	"language": ["MAIN_OPTIONS", "LANGUAGE", "en"],
	"toggle_photosens": ["MAIN_OPTIONS","PHOTOSENS_MODE", false],
	"toggle_screen_shake": ["MAIN_OPTIONS","SCREEN_SHAKE", true],
	"master_volume": ["MAIN_OPTIONS","MASTER_VOLUME", 0.5],
	"master_toggled": ["MAIN_OPTIONS","MASTER_TOGGLED", true],
	"music_volume": ["MAIN_OPTIONS","MUSIC_VOLUME", 0.25],
	"music_toggled": ["MAIN_OPTIONS","MUSIC_TOGGLED", true],
	"effects_volume": ["MAIN_OPTIONS","EFFECTS_VOLUME", 0.5],
	"effects_toggled": ["MAIN_OPTIONS","EFFECTS_TOGGLED", true]
}

var temporary_config_file : ConfigFile = ConfigFile.new()
var temporary_config_file_load = temporary_config_file.load(TEMP_CONFIG_FILE_PATH) 
var config_file : ConfigFile = ConfigFile.new()
var config_file_load = config_file.load(CONFIG_FILE_PATH) 
var key_dict : Dictionary = {}
var setting_key : bool = false
var settings_changed : bool = false
var language_changed_detect : bool = false
var photosens_mode : bool

## Internal node references
# These are subject to change as you modify the UI by creating new buttons or changing node orders.
# Luckily, no button is strictly bound/controlled by its path directly. Change these accordingly:
@onready var options_control : Control = $OptionsControl
@onready var options_menu : TabContainer = $OptionsControl/OptionsMenu
@onready var master_slider : HSlider = $OptionsControl/OptionsMenu/MAIN_OPTIONS/ScrollableMenu/Buttons/Master_Slider
@onready var effect_slider : HSlider = $OptionsControl/OptionsMenu/MAIN_OPTIONS/ScrollableMenu/Buttons/Effect_Slider
@onready var music_slider : HSlider = $OptionsControl/OptionsMenu/MAIN_OPTIONS/ScrollableMenu/Buttons/Music_Slider
@onready var master_toggle : CheckButton = $OptionsControl/OptionsMenu/MAIN_OPTIONS/ScrollableMenu/Buttons/Master_Slider/Master_Toggle
@onready var effect_toggle : CheckButton = $OptionsControl/OptionsMenu/MAIN_OPTIONS/ScrollableMenu/Buttons/Effect_Slider/Effect_Toggle
@onready var music_toggle : CheckButton = $OptionsControl/OptionsMenu/MAIN_OPTIONS/ScrollableMenu/Buttons/Music_Slider/Music_Toggle
@onready var keybind_grid : GridContainer = $OptionsControl/OptionsMenu/CONTROLS/ScrollableMenu/Container/KeybindGrid
@onready var reset_keybinds : Button = $OptionsControl/OptionsMenu/CONTROLS/ScrollableMenu/Container/ResetKeybinds
@onready var exit_button : TextureButton = $OptionsControl/ExitButton
@onready var exit_check : ConfirmationDialog = $OptionsControl/ExitCheck
@onready var reset_keybinds_check : ConfirmationDialog = $OptionsControl/ResetKeybindsCheck
#endregion

#region | Core Functions
func _ready():
	visible = false #? Here just in case you forget to make this node invisible after making UI changes.
	options_menu.current_tab = 0 #? Same as above.
	
	_bind_signals()
	await _load_keys()
	
	if reset_config_on_load: #? Config file loader
		print("OPTIONS | RESETTING CONFIG_FILE TO DEFAULT VALUES | This is useful to test fresh installations, but be careful!")
		if !OS.is_debug_build():
			push_warning("SET TO RESET IN NON-DEBUG BUILD | This could prevent saving previously made changes, so it is being deactivated.")
			reset_config_on_load = false
	
	if config_file_load == OK and !reset_config_on_load: pass #! Existing file found, being loaded
	else: #! Config file not found
		push_warning("CONFIG FILE NOT FOUND | GENERATING A NEW FILE WITH DEFAULT VALUES")
		for c in DEFAULT_CONFIGURATIONS:
			var command = DEFAULT_CONFIGURATIONS[c]
			config_file.set_value(command[0], command[1], command[2])
	config_file.save(CONFIG_FILE_PATH)
	config_file_loaded.emit()
	_load_data()
	
	match OS.get_name(): #? Instructions like nodes to hide if build is different. Web builds probably don't need resolution controls, for instance.
		"Web":
			pass
		_: pass
	
	if !UI.is_node_ready(): await UI.ready

func _input(event): # Able the player to exit options screen using actions, needed for when using controllers
	if Input.is_action_pressed("escape") and Options.visible == true: _toggle_menu(false)
	if show_keycode == true: if event is InputEventKey: print(OS.get_keycode_string(event.get_keycode_with_modifiers()) ,' - ', event.get_keycode_with_modifiers()) #? Prints every input as its keycode integer. Useful to fill the default key_dict manually.

func _bind_signals(): #? Binds signals from UI nodes by code
	#! Prevents having to recreate the links if this is script is re-implemented in another project, with new buttons and control nodes.
	visibility_changed.connect(_on_options_visibility_changed)
	reset_keybinds.pressed.connect(_on_reset_default_keybinds_button)
	reset_keybinds_check.confirmed.connect(_on_reset_default_keybinds)
	exit_check.confirmed.connect(_on_exit_check_confirmed)
	exit_check.canceled.connect(_on_exit_check_canceled)
	master_slider.drag_ended.connect(_on_master_slider_drag_ended); master_slider.value_changed.connect(_on_master_slider_value_changed)
	music_slider.drag_ended.connect(_on_music_slider_drag_ended); music_slider.value_changed.connect(_on_music_slider_value_changed)
	effect_slider.drag_ended.connect(_on_effect_slider_drag_ended); effect_slider.value_changed.connect(_on_effect_slider_value_changed)
	exit_button.pressed.connect(_on_exit_menu_pressed)

func _load_data(): #? Updates all buttons present in the framework accordingly with the loaded configuration
	#$"ConfigTabs/MAIN_OPTIONS/Scroll/ConfigPanel/OptionsButtons/Language/LanguageMenu".selected = LANG_ORDER.find(config_file.get_value("MAIN_OPTIONS","LANGUAGE"))
	#photosens_mode = config_file.get_value("MAIN_OPTIONS","PHOTOSENS_MODE"); $ConfigTabs/ACCESSIBILITY/Scroll/ConfigPanel/Photosens_Mode.button_pressed = photosens_mode
	#$ConfigTabs/ACCESSIBILITY/Scroll/ConfigPanel/ScreenShake.button_pressed = config_file.get_value("MAIN_OPTIONS","SCREEN_SHAKE")
	if master_slider:
		master_slider.value = config_file.get_value("MAIN_OPTIONS","MASTER_VOLUME")
		_on_master_toggle_toggled(config_file.get_value("MAIN_OPTIONS","MASTER_TOGGLED"))
	if music_slider:
		music_slider.value = config_file.get_value("MAIN_OPTIONS","MUSIC_VOLUME")
		_on_music_toggle_toggled(config_file.get_value("MAIN_OPTIONS","MUSIC_TOGGLED"))
	if effect_slider:
		effect_slider.value = config_file.get_value("MAIN_OPTIONS","EFFECTS_VOLUME")
		_on_effect_toggle_toggled(config_file.get_value("MAIN_OPTIONS","EFFECTS_TOGGLED"))
	TranslationServer.set_locale(config_file.get_value("MAIN_OPTIONS","LANGUAGE"))
	if reset_window_size_on_boot: DisplayServer.window_set_mode(config_file.get_value("MAIN_OPTIONS","WINDOW_MODE"))

func _button_group_input(button_index):
	var index = button_index - 1
	print(index)

func _on_options_visibility_changed(): 
	if visible: #? Updates menu if visible
		_update_menu()
		_toggle_menu(true)
	else:
		save_keys()

func _update_menu(): #? Updates menu labels, buttons and temporary files
	options_menu.get_tab_bar().grab_focus()
	_screen_mode_update()
	
	var temporary_label : Label
	for c in keybind_grid.get_children(): #? Resets each keybind button label to its default option. Fully scalable!
		if c is Label: temporary_label = c
		elif c is KeybindButton: c.text = OS.get_keycode_string(key_dict[c.keybind]).to_upper()
	
	if temporary_config_file_load == OK: pass
	temporary_config_file.load(CONFIG_FILE_PATH)
	temporary_config_file.save(TEMP_CONFIG_FILE_PATH)

func _on_config_tabs_tab_selected(_tab): options_menu.get_tab_bar().grab_focus()

func _exit(turbo : bool = false): # Clean temporary data and reset signal
	if language_changed_detect: language_changed.emit()
	settings_changed = false
	language_changed_detect = false
	
	if !turbo:
		var toggle_tween : Tween = get_tree().create_tween()
		toggle_tween.tween_property(options_control, "position", Vector2(-options_menu.size.x, 0), 0.3).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		await get_tree().create_timer(0.3).timeout
	Options.visible = false

func _on_exit_menu_pressed():
	if settings_changed == true: exit_check.visible = true
	else: _exit()

func _toggle_menu(toggle : bool):
	var toggle_tween : Tween = get_tree().create_tween()
	if toggle:
		options_control.position.x = -options_menu.size.x
		toggle_tween.tween_property(options_control, "position", Vector2(0, 0), 0.3).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	else: _on_exit_menu_pressed()

func _on_exit_check_confirmed():
	save_keys()
	options_changed.emit()
	config_file.save(CONFIG_FILE_PATH)
	_exit()

func _on_exit_check_canceled():
	config_file = temporary_config_file
	await config_file.load(TEMP_CONFIG_FILE_PATH)
	await _load_data()
	_exit()

func _screen_mode_update():
	var new_mode = DisplayServer.window_get_mode()
	config_file.set_value("MAIN_OPTIONS", "WINDOW_MODE", new_mode)

#endregion

#region | Keybindings
## Keybindings settings, remapping keys, etc.
# Foundation based on a tutorial from Rungeon. Almost completely rewritten due to changes in Godot 4.2 and other functions were added
# Even so, his tutorial is great and explore more details about registering and updating keybindings, check it out:
# Source: https://www.youtube.com/watch?v=WHGHevwhXCQ
# Github: https://github.com/trolog/godotKeybindingTutorial
# 
# Currently only works with keyboard keys. Mouse events (middle mouse press, zoom in, etc.) are not detected yet.
# Still works nonetheless!

func _load_keys():
	var file = FileAccess.open(KEYBIND_FILE_PATH, FileAccess.READ_WRITE)
	if (FileAccess.file_exists(KEYBIND_FILE_PATH)):
		delete_old_keys()
		var content = file.get_as_text()
		var data = JSON.parse_string(content)
		file.close()
		
		if(typeof(data) == TYPE_DICTIONARY):
			key_dict = data
			setup_keys()
		elif data == {} or !data:
			key_dict = DEFAULT_KEY_DICT
			await setup_keys()
			save_keys()
			print("CAUTION | File is empty. Populating input binds")
		else:
			printerr("ERROR | Data from keybind file exists, but it is either corrupted or in another format.")
	else:
		printerr("ERROR | Keybind path is invalid! Unable to save keybinds.")

#? Clear the old keys when inputting new ones
func delete_old_keys():
	for i in key_dict:
		var oldkey = InputEventKey.new()
		oldkey.keycode = int(Options.key_dict[i])
		InputMap.action_erase_event(i,oldkey)

func setup_keys(): #? Registry keys in dict as events
	for i in key_dict: #? Iterates through elements in a dictionary
		for j in get_tree().get_nodes_in_group("button_keys"): #? Iterates through buttons
			if(j.action_name == i): #? Stops when the action name is equivalent to key
				j.text = OS.get_keycode_string(key_dict[i]) #? Sets button text to the string label of a key
		var newkey = InputEventKey.new() #? Waits for a key press
		newkey.keycode = int(key_dict[i]) #? Recieves keycode from 
		InputMap.action_add_event(i,newkey) #? Adds the new key to InputMap
	
func save_keys(): #? Save the new keybindings to file
	var file = FileAccess.open(KEYBIND_FILE_PATH, FileAccess.WRITE)
	var result = JSON.stringify(key_dict, "\t")
	file.store_string(result)
	file.close()
	if debug == true: print(result + " | Key saved")

#? Prompt to reset keybindings, preventing players from resetting accidentally
func _on_reset_default_keybinds_button(): reset_keybinds_check.visible = true

#? Reloads keys after redefining key_dict. Also prompts labels update to show the default keys in place
func _on_reset_default_keybinds():
	await delete_old_keys()
	key_dict = DEFAULT_KEY_DICT
	await setup_keys()
	_update_menu() 
	settings_changed = true
#endregion

#region | Advanced Buttons

func button_toggle(button, config, section : String = "MAIN_OPTIONS"):
	var button_status = bool(button.button_pressed)
	config_file.set_value(section, config, button_status)
	settings_changed = true

func _on_photosens_mode_pressed():
	# button_toggle($ConfigTabs/ACCESSIBILITY/Scroll/ConfigPanel/Photosens_Mode, "PHOTOSENS_MODE")
	# photosens_mode = $ConfigTabs/ACCESSIBILITY/Scroll/ConfigPanel/Photosens_Mode.button_pressed
	pass

func _on_screen_mode_selected(index):
	## Window mode translator
	# The real reason behind this weird dict is that I didn't like the default numbers
	# Source: https://docs.godotengine.org/en/stable/classes/class_displayserver.html#enum-displayserver-windowmode
	var window_modes = {
		0:0, #? WINDOWED
		1:0, #? WINDOWED + BORDERLESS
		2:2, #? MAXIMIZED
		3:3, #? FULLSCREEN
		4:4  #? EXCLUSIVE FULLSCREEN
	}
	if index == 1: DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS,true)
	else: DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS,false)
	DisplayServer.window_set_mode(window_modes[index])
	config_file.set_value("MAIN_OPTIONS","WINDOW_MODE",window_modes[index])
	if debug: print('Display format selected: {0}'.format({0:window_modes[index]}))
	config_file.save(CONFIG_FILE_PATH)

func _on_master_toggle_toggled(toggled_on):
	config_file.set_value("MAIN_OPTIONS","MASTER_TOGGLED", toggled_on)
	config_file.set_value("MAIN_OPTIONS","MUSIC_TOGGLED", toggled_on)
	config_file.set_value("MAIN_OPTIONS","EFFECTS_TOGGLED", toggled_on)
	
	master_slider.editable = toggled_on
	music_slider.editable = toggled_on
	effect_slider.editable = toggled_on
	
	if toggled_on:
		master_slider.modulate.a = 1
		music_slider.modulate.a = 1
		effect_slider.modulate.a = 1
		set_volume(0, linear_to_db(config_file.get_value("MAIN_OPTIONS","MASTER_VOLUME")))
	else:
		master_slider.modulate.a = 0.5
		music_slider.modulate.a = 0.5
		effect_slider.modulate.a = 0.5
		set_volume(0, linear_to_db(0))

func _on_music_toggle_toggled(toggled_on):
	config_file.set_value("MAIN_OPTIONS","MUSIC_TOGGLED", toggled_on)
	music_slider.editable = toggled_on
	
	if toggled_on:
		music_slider.modulate.a = 1
		set_volume(2, linear_to_db(config_file.get_value("MAIN_OPTIONS","MUSIC_VOLUME")))
	else:
		music_slider.modulate.a = 0.5
		set_volume(2, linear_to_db(0))

func _on_effect_toggle_toggled(toggled_on):
	config_file.set_value("MAIN_OPTIONS","EFFECTS_TOGGLED", toggled_on)
	effect_slider.editable = toggled_on
	
	if toggled_on:
		effect_slider.modulate.a = 1
		set_volume(1, linear_to_db(config_file.get_value("MAIN_OPTIONS","EFFECTS_VOLUME")))
	else:
		effect_slider.modulate.a = 0.5
		set_volume(1, linear_to_db(0))

func set_volume(bus_id, new_db):
	AudioServer.set_bus_volume_db(bus_id, new_db)

func _on_master_slider_value_changed(value): config_file.set_value("MAIN_OPTIONS","MASTER_VOLUME", value); set_volume(0, linear_to_db(master_slider.value))
func _on_music_slider_value_changed(value): config_file.set_value("MAIN_OPTIONS","MUSIC_VOLUME", value); set_volume(2, linear_to_db(music_slider.value))
func _on_effect_slider_value_changed(value): config_file.set_value("MAIN_OPTIONS","EFFECTS_VOLUME", value); set_volume(1, linear_to_db(effect_slider.value))
func _on_master_slider_drag_ended(_value_changed): config_file.save(CONFIG_FILE_PATH)
func _on_music_slider_drag_ended(_value_changed): config_file.save(CONFIG_FILE_PATH)
func _on_effect_slider_drag_ended(_value_changed): config_file.save(CONFIG_FILE_PATH)

# func _on_visual_effect_selected(index): UI.ScreenEffect.change_effect(effect_menu.get_item_text(index))

func _on_language_menu_item_selected(index):
	settings_changed = true
	language_changed_detect = true
	var lang : String
	lang = LANG_ORDER[index]
	config_file.set_value("MAIN_OPTIONS","LANGUAGE", lang)
	TranslationServer.set_locale(lang)

#endregion
