## OPTIONS
# This is a framework for changing important game configurations like volume, resolution, effects and such on a interactable menu
# This menu can also be heavily modified and personalized to each project. Just be sure to reconnect the nodes!
# All information necessary is loaded from a single ConfigFile, and if it doesn't exist or it is the first load, it will create it
# Don't set this as a class, as it creates conflict when autoloaded.
extends CanvasLayer

signal focus_freed
signal config_file_loaded #? Used to wait until the file is correctly loaded
signal options_changed #? Useful to reset triggers and player behavior
signal language_changed #? Emits for certain nodes that needs TranslationServer to run again after a language is changed

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
	"enter": 4194309, #| Enter
	"escape": 4194305, #| Esc
	"space": 32, #| Space
	"move_up": 87, #| W
	"move_down": 83, #| S
	"move_left": 65, #| A
	"move_right": 68, #| D
	"switch_menu": 81 #| Q
}
const DEFAULT_CONFIGURATIONS : Dictionary = { #? Default keybinds that is loaded when the game is first loaded
	"window_mode": ["MAIN_OPTIONS","WINDOW_MODE", "WINDOW_MODE_WINDOWED"],
	"window_size": ["MAIN_OPTIONS","MINIMUM_WINDOW_SIZE", DEFAULT_RESOLUTION],
	"drag_activated": ["MAIN_OPTIONS", "DRAG_MODE", true],
	"autoturn_toggle": ["MAIN_OPTIONS","AUTOTURN_TOGGLED", true],
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

#region | Core Configuration
@export_group("Main Configuration")
@export var reset_window_size_on_boot : bool = false ## If true, loads the default resolution/window size
@export var menu_button_group : ButtonGroup ## Useful in certain layouts, but remember that button groups cannot be multiple toggled. This is better with right/left options.

@export_group("Tools")
@export var reset_config_on_load : bool = false ## Reset ConfigFile when started, loading default values stored on constants.
@export var show_keycode : bool = false ## Print the exact keycode for an input pressed anytime

var temporary_config_file : ConfigFile = ConfigFile.new()
var temporary_config_file_load = temporary_config_file.load(TEMP_CONFIG_FILE_PATH) 
var config_file : ConfigFile = ConfigFile.new()
var config_file_load = config_file.load(CONFIG_FILE_PATH) 
var key_dict : Dictionary = {}
var setting_key : bool = false
var settings_changed : bool = false
var language_recently_changed : bool
var photosens_mode : bool
var drag_mode : bool = true

## Internal node references
# These are subject to change as you modify the UI by creating new buttons or changing node orders.
# Change these accordingly:
@onready var options_control : Control = $OptionsControl
@onready var options_menu : TabContainer = $OptionsControl/OptionsMenu
@onready var drag_toggle_button : CheckButton = $OptionsControl/OptionsMenu/CONTROLS/ScrollableMenu/Container/DragToggleButton
@onready var master_slider : HSlider = $OptionsControl/OptionsMenu/MAIN_OPTIONS/ScrollableMenu/MenuContainer/VolumeButtons/Master_Slider
@onready var effects_slider: HSlider = $OptionsControl/OptionsMenu/MAIN_OPTIONS/ScrollableMenu/MenuContainer/VolumeButtons/Effects_Slider
@onready var music_slider : HSlider = $OptionsControl/OptionsMenu/MAIN_OPTIONS/ScrollableMenu/MenuContainer/VolumeButtons/Music_Slider
@onready var master_toggle : CheckButton = $OptionsControl/OptionsMenu/MAIN_OPTIONS/ScrollableMenu/MenuContainer/VolumeButtons/Master_Slider/Master_Toggle
@onready var effect_toggle: CheckButton = $OptionsControl/OptionsMenu/MAIN_OPTIONS/ScrollableMenu/MenuContainer/VolumeButtons/Effects_Slider/Effect_Toggle
@onready var music_toggle : CheckButton = $OptionsControl/OptionsMenu/MAIN_OPTIONS/ScrollableMenu/MenuContainer/VolumeButtons/Music_Slider/Music_Toggle
@onready var keybind_grid : GridContainer = $OptionsControl/OptionsMenu/CONTROLS/ScrollableMenu/Container/KeybindGrid
@onready var reset_keybinds : Button = $OptionsControl/OptionsMenu/CONTROLS/ScrollableMenu/Container/ResetKeybinds
@onready var language_button : OptionButton = $OptionsControl/OptionsMenu/MAIN_OPTIONS/ScrollableMenu/MenuContainer/LanguageButton
@onready var exit_button_1 : TextureButton = $OptionsControl/OptionsMenu/MAIN_OPTIONS/ExitButton
@onready var exit_button_2: TextureButton = $OptionsControl/OptionsMenu/CONTROLS/ExitButton
@onready var exit_check : ConfirmationDialog = $OptionsControl/ExitCheck
@onready var reset_keybinds_check : ConfirmationDialog = $OptionsControl/ResetKeybindsCheck
@onready var stage_container : VBoxContainer = $OptionsControl/OptionsMenu/MAIN_OPTIONS/ScrollableMenu/MenuContainer/Stage
#endregion

#region | Core Functions
func _ready() -> void:
	visible = false #? Here just in case you forget to make this node invisible after making UI changes.
	options_menu.current_tab = 0 #? Same as above
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
	
	exit_check.get_child(1, true).set_horizontal_alignment(1)
	exit_check.get_child(1, true).set_vertical_alignment(1)
	reset_keybinds_check.get_child(1, true).set_horizontal_alignment(1)
	reset_keybinds_check.get_child(1, true).set_vertical_alignment(1)
	if !UI.is_node_ready(): await UI.ready

func _input(event) -> void: # Able the player to exit options screen using actions, needed for when using controllers
	if Input.is_action_just_pressed("escape") and !Options.visible: show()
	elif Input.is_action_just_pressed("escape") and Options.visible: _on_exit_menu_pressed()
	if show_keycode == true: if event is InputEventKey: print(OS.get_keycode_string(event.get_keycode_with_modifiers()) ,' - ', event.get_keycode_with_modifiers()) #? Prints every input as its keycode integer. Useful to fill the default key_dict manually.

func _bind_signals() -> void: #? Binds signals from UI nodes by code
	#! Prevents having to recreate the links if this is script is re-implemented in another project, with new buttons and control nodes.
	visibility_changed.connect(_on_options_visibility_changed)
	reset_keybinds.pressed.connect(_on_reset_default_keybinds_button)
	reset_keybinds_check.confirmed.connect(_on_reset_default_keybinds)
	exit_check.confirmed.connect(_on_exit_check_confirmed)
	exit_check.canceled.connect(_on_exit_check_canceled)
	drag_toggle_button.pressed.connect(_on_drag_toggle_pressed)
	master_slider.drag_ended.connect(_on_master_slider_drag_ended); master_slider.value_changed.connect(_on_master_slider_value_changed)
	music_slider.drag_ended.connect(_on_music_slider_drag_ended); music_slider.value_changed.connect(_on_music_slider_value_changed)
	effects_slider.drag_ended.connect(_on_effects_slider_drag_ended); effects_slider.value_changed.connect(_on_effects_slider_value_changed)
	language_button.item_selected.connect(_on_language_menu_item_selected)
	exit_button_1.pressed.connect(_on_exit_menu_pressed)
	exit_button_2.pressed.connect(_on_exit_menu_pressed)

func _load_data() -> void: #? Updates all buttons present in the framework accordingly with the loaded configuration
	drag_mode = config_file.get_value("MAIN_OPTIONS","DRAG_MODE")
	drag_toggle_button.button_pressed = drag_mode
	UI.autoplay_turn = config_file.get_value("MAIN_OPTIONS","AUTOTURN_TOGGLED")
	
	if master_slider: master_slider.value = config_file.get_value("MAIN_OPTIONS","MASTER_VOLUME"); _toggle_channel(CHANNELS.MASTER, config_file.get_value("MAIN_OPTIONS","MASTER_TOGGLED"))
	if music_slider: music_slider.value = config_file.get_value("MAIN_OPTIONS","MUSIC_VOLUME"); _toggle_channel(CHANNELS.MUSIC, config_file.get_value("MAIN_OPTIONS","MUSIC_TOGGLED"))
	if effects_slider: effects_slider.value = config_file.get_value("MAIN_OPTIONS","EFFECTS_VOLUME"); _toggle_channel(CHANNELS.EFFECTS, config_file.get_value("MAIN_OPTIONS","EFFECTS_TOGGLED"))
	TranslationServer.set_locale(config_file.get_value("MAIN_OPTIONS","LANGUAGE"))
	language_button.selected = LANG_ORDER.find(config_file.get_value("MAIN_OPTIONS","LANGUAGE"))
	if reset_window_size_on_boot: DisplayServer.window_set_mode(config_file.get_value("MAIN_OPTIONS","WINDOW_MODE"))

func _button_group_input(button_index : int) -> void:
	var index = button_index - 1
	print(index)

func _on_options_visibility_changed() -> void:
	if StageManager.on_stage:
		if get_tree().paused: pass #? Already paused before calling options
		else:
			UI.pause_locked = true
			UI.pause_layer.pause()
			UI.pause_layer.set_signaled_unpause(self, visibility_changed) #? Will unpause after closing menu
	
	if visible: _update_menu() #? Updates menu if visible
	else: save_keys() #? Updates keys

func _update_menu() -> void: #? Updates menu labels, buttons and temporary files
	options_menu.get_tab_bar().grab_focus()
	_screen_mode_update()
	
	stage_container.set_visible(StageManager.on_stage)
	
	var _temporary_label : Label
	for c in keybind_grid.get_children(): #? Resets each keybind button label to its default option. Fully scalable!
		if c is Label: _temporary_label = c
		elif c is KeybindButton: c.text = OS.get_keycode_string(key_dict[c.keybind]).to_upper()
	
	if temporary_config_file_load == OK: pass
	temporary_config_file.load(CONFIG_FILE_PATH)
	temporary_config_file.save(TEMP_CONFIG_FILE_PATH)

func _on_config_tabs_tab_selected(_tab) -> void: options_menu.get_tab_bar().grab_focus()

func _on_exit_menu_pressed() -> void:
	if settings_changed == true: exit_check.visible = true
	else: _exit()

func _on_exit_check_confirmed() -> void: #? Save new configuration
	save_keys()
	options_changed.emit()
	config_file.save(CONFIG_FILE_PATH)
	_exit()

func _on_exit_check_canceled() -> void: #? Reset old configuration
	config_file = temporary_config_file
	config_file.load(TEMP_CONFIG_FILE_PATH)
	_load_data()
	_exit()

func _exit() -> void: # Clean temporary data and reset signal
	if language_recently_changed: language_changed.emit()
	settings_changed = false
	language_recently_changed = false
	Options.visible = false
	focus_freed.emit()

func _screen_mode_update() -> void:
	var new_mode = DisplayServer.window_get_mode()
	config_file.set_value("MAIN_OPTIONS", "WINDOW_MODE", new_mode)
#endregion

#region | Keybindings
## Keybindings settings, remapping keys, etc.
# Foundation based on a tutorial from Rungeon. Almost completely rewritten due to changes in Godot 4.2 plus other functions were added
# Currently only works with keyboard keys. Mouse events (middle mouse press, zoom in, etc.) are more complicated and controlled directly with Input when needed.
# Even so, his tutorial is great and explore more details about registering and updating keybindings, check it out:
# Source: https://www.youtube.com/watch?v=WHGHevwhXCQ
# Github: https://github.com/trolog/godotKeybindingTutorial
func _load_keys() -> void: ## Load keybiding file with player configuration
	var file = FileAccess.open(KEYBIND_FILE_PATH, FileAccess.READ_WRITE)
	if (FileAccess.file_exists(KEYBIND_FILE_PATH)):
		delete_old_keys()
		var content = file.get_as_text()
		var data = JSON.parse_string(content)
		file.close()
		
		if(typeof(data) == TYPE_DICTIONARY): key_dict = data; setup_keys() #? Valid!
		elif data == {} or !data: _reset_keys(); push_warning("CAUTION | File is empty. Populating input binds")
		else: push_error("ERROR | Data from keybind file exists, but it is either corrupted or in another format.")
	else:
		_reset_keys()
		push_error("ERROR | Keybind path ", KEYBIND_FILE_PATH, " is invalid! Unable to save keybinds.")

func _reset_keys() -> void:
	key_dict = DEFAULT_KEY_DICT.duplicate() #? If not a duplicate, key_dict would just point to a constant value. Thus, it would render the dict READ_ONLY and block further modifications!
	await setup_keys()
	save_keys()

func delete_old_keys() -> void: #? Clear the old keys from input when inputting new ones
	for i in key_dict:
		var oldkey = InputEventKey.new()
		oldkey.keycode = int(Options.key_dict[i])
		InputMap.action_erase_event(i, oldkey)

func setup_keys() -> void: ## Registers keys in dict as inputs
	for i in key_dict: #? Iterates through elements in a dictionary
		for j in get_tree().get_nodes_in_group("button_keys"): #? Iterates through buttons
			if(j.action_name == i): #? Stops when the action name is equivalent to key
				j.text = OS.get_keycode_string(key_dict[i]).to_upper() #? Sets button text to the string label of a key
		var newkey = InputEventKey.new() #? Waits for a key press
		newkey.keycode = int(key_dict[i]) #? Recieves keycode from 
		InputMap.action_add_event(i,newkey) #? Adds the new key to InputMap
	
func save_keys() -> void: #? Save the new keybindings to file
	var file = FileAccess.open(KEYBIND_FILE_PATH, FileAccess.WRITE)
	var result = JSON.stringify(key_dict, "\t")
	file.store_string(result)
	file.close()

func _on_reset_default_keybinds_button() -> void: reset_keybinds_check.visible = true ## Calls prompt to reset keybindings, preventing players from resetting accidentally

func _on_reset_default_keybinds() -> void: ## Reloads keys after redefining key_dict. Also prompts labels update to show the default keys in place
	await delete_old_keys()
	await _reset_keys()
	_update_menu() 
	settings_changed = true
#endregion

#region | Advanced Buttons
func _on_language_menu_item_selected(index) -> void:
	settings_changed = true
	language_recently_changed = true
	var lang : String
	lang = LANG_ORDER[index]
	config_file.set_value("MAIN_OPTIONS","LANGUAGE", lang)
	TranslationServer.set_locale(lang)

func button_toggle(button, config, section : String = "MAIN_OPTIONS") -> void:
	var button_status = bool(button.button_pressed)
	config_file.set_value(section, config, button_status)
	settings_changed = true

func _on_photosens_mode_pressed() -> void:
	# button_toggle($ConfigTabs/ACCESSIBILITY/Scroll/ConfigPanel/Photosens_Mode, "PHOTOSENS_MODE")
	# photosens_mode = $ConfigTabs/ACCESSIBILITY/Scroll/ConfigPanel/Photosens_Mode.button_pressed
	pass

func _on_drag_toggle_pressed() -> void:
	config_file.set_value("MAIN_OPTIONS","DRAG_MODE", drag_toggle_button.button_pressed)
	settings_changed = true

func _on_screen_mode_selected(index) -> void:
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
	# print('Display format selected: {0}'.format({0:window_modes[index]}))
	config_file.save(CONFIG_FILE_PATH)
#endregion

#region Audio Controls
enum CHANNELS {MASTER, MUSIC, EFFECTS}

func _toggle_channel(channel : CHANNELS, toggle : bool, skip_master : bool = false) -> void:
	if channel == CHANNELS.MASTER and !skip_master: for c in CHANNELS: _toggle_channel(CHANNELS[c], toggle, true); return #? If master, do for every channel
	var channel_id : String = CHANNELS.keys()[channel]
	var slider : Slider
	config_file.set_value("MAIN_OPTIONS","{0}_TOGGLED".format({0:channel_id}), toggle)
	match channel:
		0: slider = master_slider
		1: slider = music_slider
		2: slider = effects_slider
	
	slider.editable = toggle
	if toggle: slider.modulate.a = 1; set_volume(channel, linear_to_db(config_file.get_value("MAIN_OPTIONS","{0}_VOLUME".format({0:channel_id}))))
	else: slider.modulate.a = 0.5; set_volume(channel, linear_to_db(0))

func set_volume(bus_id, new_db) -> void: AudioServer.set_bus_volume_db(bus_id, new_db)
func _on_master_slider_value_changed(value) -> void: config_file.set_value("MAIN_OPTIONS","MASTER_VOLUME", value); set_volume(0, linear_to_db(master_slider.value))
func _on_music_slider_value_changed(value) -> void: config_file.set_value("MAIN_OPTIONS","MUSIC_VOLUME", value); set_volume(1, linear_to_db(music_slider.value))
func _on_effects_slider_value_changed(value) -> void: config_file.set_value("MAIN_OPTIONS","EFFECTS_VOLUME", value); set_volume(2, linear_to_db(effects_slider.value))
func _on_master_slider_drag_ended(_value_changed) -> void: config_file.save(CONFIG_FILE_PATH)
func _on_music_slider_drag_ended(_value_changed) -> void: config_file.save(CONFIG_FILE_PATH)
func _on_effects_slider_drag_ended(_value_changed) -> void: config_file.save(CONFIG_FILE_PATH)
#endregion

#region Loaders
func _on_resource_loaded() -> void: pass

func _on_restart_stage_button_pressed() -> void: 
	var request : bool = await UI.event_layer.request_confirmation(
		'RESTART_STAGE',
		TranslationServer.tr('STAGE_PROGRESS_WARNING_TEXT'),
		'CONFIRM', 'CANCEL'
	)
	if request: _exit(); LoadManager.reload_scene()

func _on_main_menu_button_pressed() -> void:
	var request : bool = await UI.event_layer.request_confirmation(
		'RETURN_TO_MENU',
		TranslationServer.tr('STAGE_PROGRESS_WARNING_TEXT'),
		'CONFIRM', 'CANCEL'
	)
	if request: _exit(); LoadManager.return_to_menu()

func _on_auto_turn_toggled(toggled_on : bool) -> void:
	config_file.set_value("MAIN_OPTIONS", "AUTOTURN_TOGGLED", toggled_on)
	UI.autoplay_turn = toggled_on
#endregion
