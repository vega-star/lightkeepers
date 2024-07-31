extends CanvasLayer

signal config_file_loaded
signal options_changed
signal language_changed

#region Configuration
@export_group("Main Configuration")
@export var reset_window_size_on_boot : bool = false
@export var menu_button_group : ButtonGroup

@export_group("Tools")
@export var reset_config_on_load : bool = false # Will override config files with a completely new default one
@export var show_keycode : bool = false ## Print the exact keycode for an input pressed anytime
@export var debug : bool = false ## Print messages in some actions to facilitate direct debug

const keybind_file_path = "res://data/keybinding_reg.json"
const config_file_path = "user://config.cfg"
const temp_config_file_path = "user://temp.cfg"
const lang_order : Array = ["en","pt-br"]

## Different configurations to screen (Borderless is currently bugged, TODO)
const screen_dict : Array = [
	"WINDOWED",
	"WINDOWED + BORDERLESS",
	"MAXIMIZED",
	"FULLSCREEN",
	"EXCLUSIVE FULLSCREEN"
]
## Default keybinds that is loaded when the game is first loaded
const default_key_dict : Dictionary = {
	"move_up":4194320,
	"move_down":4194322,
	"move_right":4194321,
	"move_left":4194319,
	"dash":32,
	"roll":4194328,
	"shoot":90,
	"bomb":88,
	"reset":82,
	"pause":96,
	"quit":81
}
## Default keybinds that is loaded when the game is first loaded
const default_configurations : Dictionary = {
	"language": ["MAIN_OPTIONS", "LANGUAGE", "en"],
	"window_mode": ["MAIN_OPTIONS","WINDOW_MODE", "WINDOW_MODE_WINDOWED"],
	"window_size": ["MAIN_OPTIONS","MINIMUM_WINDOW_SIZE", Vector2(480,270)],
	"toggle_photosens": ["MAIN_OPTIONS","PHOTOSENS_MODE", false],
	"toggle_fire": ["MAIN_OPTIONS","TOGGLE_FIRE", true],
	"toggle_screen_shake": ["MAIN_OPTIONS","SCREEN_SHAKE", true],
	"master_volume": ["MAIN_OPTIONS","MASTER_VOLUME", 0.5],
	"master_toggled": ["MAIN_OPTIONS","MASTER_TOGGLED", true],
	"music_volume": ["MAIN_OPTIONS","MUSIC_VOLUME", 0.25],
	"music_toggled": ["MAIN_OPTIONS","MUSIC_TOGGLED", true],
	"effects_volume": ["MAIN_OPTIONS","EFFECTS_VOLUME", 0.5],
	"effects_toggled": ["MAIN_OPTIONS","EFFECTS_TOGGLED", true],
	"limit_hp": ["UI_OPTIONS", "LIMIT_HP_FSC", 3],
	"limit_ammo": ["UI_OPTIONS", "LIMIT_AMMO_FSC", 3],
	"hide_stage_bar": ["UI_OPTIONS", "HIDE_STAGE_BAR", false],
	"hide_boss_bar": ["UI_OPTIONS", "HIDE_BOSS_BAR", false]
}

var temporary_config_file : ConfigFile = ConfigFile.new()
var temporary_config_file_load = temporary_config_file.load(temp_config_file_path) 
var config_file : ConfigFile = ConfigFile.new()
var config_file_load = config_file.load(config_file_path) 
var key_dict : Dictionary = {}
var setting_key : bool = false
var settings_changed : bool = false
var language_changed_detect : bool = false
var photosens_mode : bool

## Internal node references
@onready var master_slider = $"ConfigTabs/MAIN_OPTIONS/Scroll/ConfigPanel/OptionsButtons/VolumeContainer/MasterVol/Master_Toggle/Master_Slider"
@onready var music_slider = $"ConfigTabs/MAIN_OPTIONS/Scroll/ConfigPanel/OptionsButtons/VolumeContainer/MusicVol/Music_Toggle/Music_Slider"
@onready var effect_slider = $"ConfigTabs/MAIN_OPTIONS/Scroll/ConfigPanel/OptionsButtons/VolumeContainer/SoundEffectVol/Effect_Toggle/Effect_Slider"
@onready var master_toggle = $"ConfigTabs/MAIN_OPTIONS/Scroll/ConfigPanel/OptionsButtons/VolumeContainer/MasterVol/Master_Toggle"
@onready var music_toggle = $"ConfigTabs/MAIN_OPTIONS/Scroll/ConfigPanel/OptionsButtons/VolumeContainer/MusicVol/Music_Toggle"
@onready var sound_effect_toggle = $"ConfigTabs/MAIN_OPTIONS/Scroll/ConfigPanel/OptionsButtons/VolumeContainer/SoundEffectVol/Effect_Toggle"
@onready var effect_menu = $ConfigTabs/GRAPHICS/Scroll/ConfigPanel/VisualEffects/VisualEffectsMenu
#endregion

func _ready():
	await load_keys()
	
	if visible: visible = false # Here just in case I forgot to make this node invisible after making UI changes. It can confuse players
	
	## Config file loader
	if reset_config_on_load: 
		print("OPTIONS | RESETTING CONFIG_FILE TO DEFAULT VALUES | This is useful to test fresh installations, but be careful!")
		if !OS.is_debug_build():
			push_warning("SET TO RESET IN NON-DEBUG BUILD | This could prevent saving previously made changes, so it is being deactivated.")
			reset_config_on_load = false
	
	if config_file_load == OK and !reset_config_on_load: pass # Existing file found, being loaded
	else: # Config file not found
		push_warning("CONFIG FILE NOT FOUND | GENERATING A NEW FILE WITH DEFAULT VALUES")
		for c in default_configurations:
			var command = default_configurations[c]
			config_file.set_value(command[0], command[1], command[2])
	config_file.save(config_file_path)
	config_file_loaded.emit()
	_load_data()
	
	## Nodes to hide if build is different
	match OS.get_name():
		"Web":
			$ConfigTabs/GRAPHICS/Scroll/ConfigPanel/ScreenMode.visible = false
		_: pass
	
	if !UI.is_node_ready(): await UI.ready
	$ConfigTabs.current_tab = 0
	for key in UI.ScreenEffect.effects: $ConfigTabs/GRAPHICS/Scroll/ConfigPanel/VisualEffects/VisualEffectsMenu.add_item(key)
	for mode in screen_dict: $ConfigTabs/GRAPHICS/Scroll/ConfigPanel/ScreenMode/ScreenModeMenu.add_item(mode)

func _load_data():
	$"ConfigTabs/MAIN_OPTIONS/Scroll/ConfigPanel/OptionsButtons/Language/LanguageMenu".selected = lang_order.find(config_file.get_value("MAIN_OPTIONS","LANGUAGE"))
	photosens_mode = config_file.get_value("MAIN_OPTIONS","PHOTOSENS_MODE"); $ConfigTabs/ACCESSIBILITY/Scroll/ConfigPanel/Photosens_Mode.button_pressed = photosens_mode
	$ConfigTabs/ACCESSIBILITY/Scroll/ConfigPanel/ScreenShake.button_pressed = config_file.get_value("MAIN_OPTIONS","SCREEN_SHAKE")
	$'ConfigTabs/MAIN_OPTIONS/Scroll/ConfigPanel/OptionsButtons/ToggleFiring'.button_pressed = config_file.get_value("MAIN_OPTIONS","TOGGLE_FIRE")
	$ConfigTabs/UI/Scroll/ConfigPanel/HideBossBar.button_pressed = config_file.get_value("UI_OPTIONS", "HIDE_STAGE_BAR")
	$ConfigTabs/UI/Scroll/ConfigPanel/HideStageBar.button_pressed = config_file.get_value("UI_OPTIONS", "HIDE_STAGE_BAR")
	master_slider.value = config_file.get_value("MAIN_OPTIONS","MASTER_VOLUME")
	music_slider.value = config_file.get_value("MAIN_OPTIONS","MUSIC_VOLUME")
	effect_slider.value = config_file.get_value("MAIN_OPTIONS","EFFECTS_VOLUME")
	_on_master_toggle_toggled(config_file.get_value("MAIN_OPTIONS","MASTER_TOGGLED"))
	_on_music_toggle_toggled(config_file.get_value("MAIN_OPTIONS","MUSIC_TOGGLED"))
	_on_effect_toggle_toggled(config_file.get_value("MAIN_OPTIONS","EFFECTS_TOGGLED"))
	TranslationServer.set_locale(config_file.get_value("MAIN_OPTIONS","LANGUAGE"))
	if reset_window_size_on_boot: DisplayServer.window_set_mode(config_file.get_value("MAIN_OPTIONS","WINDOW_MODE"))

func _input(event): # Able the player to exit options screen using actions, needed for when using controllers
	if Input.is_action_pressed("quit") or Input.is_action_pressed("pause") and Options.visible == true:
		_on_exit_menu_pressed()

	if show_keycode == true: ## This conditional prints every input as its keycode integer. 
		# This is useful to fill key_dict manually, and I think it's faster than searching in docs.
		if event is InputEventKey: 
			print(event.get_keycode_with_modifiers()) 

func _button_group_input(button_index):
	var index = button_index - 1
	print(index)

func _emit_sound(sound_id : String): AudioManager.emit_sound_effect(null, sound_id)

func _on_reset_default_keybinds_button(): # Prompt to reset keybindings, preventing players from resetting accidentally
	$OptionsControl/ResetBinds.visible = true
	settings_changed = true

func _on_reset_default_keybinds(): # Reloads keys after redefining key_dict
	delete_old_keys()
	key_dict = default_key_dict
	setup_keys()
	_on_options_visibility_changed()
	save_keys()

func _on_options_visibility_changed(): 
	# | Converts keycode physical elements from key_dict to their respectives string labels, abling players to visualize which keys are currently bound to what.
	# I already know there's a efficient way to automate these attributions in the case other buttons are added, but I need to prioritize other elements first, so that's it for now
	if visible:
		$ConfigTabs.get_tab_bar().grab_focus() # Direct controller focus to this specific button
		_screen_mode_update(); _bind_display_update()
		
		if temporary_config_file_load == OK: pass
		temporary_config_file.load(config_file_path)
		temporary_config_file.save(temp_config_file_path)

func _on_config_tabs_tab_selected(_tab): 
	$ConfigTabs.get_tab_bar().grab_focus()

func _bind_display_update():
	$ConfigTabs/CONTROLS/Scroll/ConfigPanel/BindGrids/BindGridLeft/UP_B.text = OS.get_keycode_string(key_dict["move_up"])
	$ConfigTabs/CONTROLS/Scroll/ConfigPanel/BindGrids/BindGridLeft/DOWN_B.text = OS.get_keycode_string(key_dict["move_down"])
	$ConfigTabs/CONTROLS/Scroll/ConfigPanel/BindGrids/BindGridLeft/RIGHT_B.text = OS.get_keycode_string(key_dict["move_right"])
	$ConfigTabs/CONTROLS/Scroll/ConfigPanel/BindGrids/BindGridLeft/LEFT_B.text = OS.get_keycode_string(key_dict["move_left"])
	$ConfigTabs/CONTROLS/Scroll/ConfigPanel/BindGrids/BindGridLeft/PAUSE_B.text = OS.get_keycode_string(key_dict["pause"])
	$ConfigTabs/CONTROLS/Scroll/ConfigPanel/BindGrids/BindGridRight/DASH_B.text = OS.get_keycode_string(key_dict["dash"])
	$ConfigTabs/CONTROLS/Scroll/ConfigPanel/BindGrids/BindGridRight/ROLL_B.text = OS.get_keycode_string(key_dict["roll"])
	$ConfigTabs/CONTROLS/Scroll/ConfigPanel/BindGrids/BindGridRight/RESET_B.text = OS.get_keycode_string(key_dict["reset"])
	$ConfigTabs/CONTROLS/Scroll/ConfigPanel/BindGrids/BindGridRight/SHOOT_B.text = OS.get_keycode_string(key_dict["shoot"])
	$ConfigTabs/CONTROLS/Scroll/ConfigPanel/BindGrids/BindGridRight/BOMB_B.text = OS.get_keycode_string(key_dict["bomb"])

func _screen_mode_update():
	var new_mode = DisplayServer.window_get_mode()
	config_file.set_value("MAIN_OPTIONS", "WINDOW_MODE", new_mode)

func load_keys():
	var file = FileAccess.open(keybind_file_path, FileAccess.READ)
	
	if (FileAccess.file_exists(keybind_file_path)):
		delete_old_keys()
		var content = file.get_as_text()
		var data = JSON.parse_string(content)
		file.close()
		
		if debug == true:# | (DEBUG) |
			print(content)
			print(data)
		
		if(typeof(data) == TYPE_DICTIONARY):
			key_dict = data
			setup_keys()
		elif data == {}:
			key_dict = default_key_dict
			setup_keys()
			print("CAUTION | File is empty. Populating input binds")
		else:
			printerr("ERROR | Data from keybind file exists, but it is either corrupted or in another format.")
	else:
		printerr("ERROR | Keybind path is invalid! Unable to save keybinds.")
	pass

func delete_old_keys(): # Clear the old keys when inputting new ones
	for i in key_dict:
		var oldkey = InputEventKey.new()
		oldkey.keycode = int(Options.key_dict[i])
		InputMap.action_erase_event(i,oldkey)

func setup_keys(): # Registry keys in dict as events
	for i in key_dict: # | Iterates through elements in a dictionary
		for j in get_tree().get_nodes_in_group("button_keys"): # | Iterates through buttons
			if(j.action_name == i): # | Stops when the action name is equivalent to key
				j.text = OS.get_keycode_string(key_dict[i]) # | Sets button text to the string label of a key
			if debug == true: print('Element: {0} | Button {1}'.format({0:i,1:j})) # | (DEBUG |
		var newkey = InputEventKey.new() # | Waits for a key press
		newkey.keycode = int(key_dict[i]) # | Recieves keycode from 
		InputMap.action_add_event(i,newkey) # | Finally, adds the new key to InputMap
	
func save_keys(): # Save the new key bindings to file
	var file = FileAccess.open(keybind_file_path, FileAccess.WRITE)
	var result = JSON.stringify(key_dict, "\t")
	file.store_string(result)
	file.close()
	
	if debug == true:
		print(result)
		print("Key saved")
	pass

func _on_exit_menu_pressed():
	if settings_changed == true: $OptionsControl/ExitCheck.visible = true
	else: _exit()

func _on_exit_check_confirmed():
	save_keys()
	options_changed.emit()
	config_file.save(config_file_path)
	_exit()

func _on_exit_check_canceled():
	config_file = temporary_config_file
	await config_file.load(temp_config_file_path)
	await _load_data()
	_exit()

func _exit(): # Clean temporary data and reset signal
	Options.visible = false
	if language_changed_detect: language_changed.emit()
	settings_changed = false
	language_changed_detect = false

func _on_toggle_firing_pressed():
	button_toggle($'ConfigTabs/MAIN_OPTIONS/Scroll/ConfigPanel/OptionsButtons/ToggleFiring', "TOGGLE_FIRE")

func _on_photosens_mode_pressed():
	button_toggle($ConfigTabs/ACCESSIBILITY/Scroll/ConfigPanel/Photosens_Mode, "PHOTOSENS_MODE")
	photosens_mode = $ConfigTabs/ACCESSIBILITY/Scroll/ConfigPanel/Photosens_Mode.button_pressed

func _on_screen_shake_pressed():
	button_toggle($ConfigTabs/ACCESSIBILITY/Scroll/ConfigPanel/ScreenShake, "SCREEN_SHAKE")

func _on_show_boss_bar_pressed():
	button_toggle($ConfigTabs/UI/Scroll/ConfigPanel/HideBossBar, "HIDE_BOSS_BAR", "UI_OPTIONS")

func _on_hide_stage_bar_pressed():
	button_toggle($ConfigTabs/UI/Scroll/ConfigPanel/HideStageBar, "HIDE_STAGE_BAR", "UI_OPTIONS")

func button_toggle(button, config, section : String = "MAIN_OPTIONS"):
	var button_status = bool(button.button_pressed)
	
	config_file.set_value(section, config, button_status)
	settings_changed = true

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
	config_file.save(config_file_path)

# Foundation based on a tutorial from Rungeon, mostly rewritten due to changes in Godot 4.2 and a lot of other functions were added
# Even so, his tutorial is great and explore more details about registering and updating keybindings
# Source: https://www.youtube.com/watch?v=WHGHevwhXCQ
# Github: https://github.com/trolog/godotKeybindingTutorial

#region Toggle
func _on_master_toggle_toggled(toggled_on):
	config_file.set_value("MAIN_OPTIONS","MASTER_TOGGLED", toggled_on)
	config_file.set_value("MAIN_OPTIONS","MUSIC_TOGGLED", toggled_on)
	config_file.set_value("MAIN_OPTIONS","EFFECTS_TOGGLED", toggled_on)
	
	master_slider.editable = toggled_on
	music_slider.editable = toggled_on
	effect_slider.editable = toggled_on
	
	if toggled_on:
		$'ConfigTabs/MAIN_OPTIONS/Scroll/ConfigPanel/OptionsButtons/VolumeContainer/MasterVol'.modulate.a = 1
		$'ConfigTabs/MAIN_OPTIONS/Scroll/ConfigPanel/OptionsButtons/VolumeContainer/MusicVol'.modulate.a = 1
		$'ConfigTabs/MAIN_OPTIONS/Scroll/ConfigPanel/OptionsButtons/VolumeContainer/SoundEffectVol'.modulate.a = 1
		
		set_volume(0, linear_to_db(config_file.get_value("MAIN_OPTIONS","MASTER_VOLUME")))
	else:
		$'ConfigTabs/MAIN_OPTIONS/Scroll/ConfigPanel/OptionsButtons/VolumeContainer/MasterVol'.modulate.a = 0.5
		$'ConfigTabs/MAIN_OPTIONS/Scroll/ConfigPanel/OptionsButtons/VolumeContainer/MusicVol'.modulate.a = 0.5
		$'ConfigTabs/MAIN_OPTIONS/Scroll/ConfigPanel/OptionsButtons/VolumeContainer/SoundEffectVol'.modulate.a = 0.5
		
		set_volume(0, linear_to_db(0))

func _on_music_toggle_toggled(toggled_on):
	config_file.set_value("MAIN_OPTIONS","MUSIC_TOGGLED", toggled_on)
	music_slider.editable = toggled_on
	
	if toggled_on:
		$'ConfigTabs/MAIN_OPTIONS/Scroll/ConfigPanel/OptionsButtons/VolumeContainer/MusicVol'.modulate.a = 1
		set_volume(2, linear_to_db(config_file.get_value("MAIN_OPTIONS","MUSIC_VOLUME")))
	else:
		$'ConfigTabs/MAIN_OPTIONS/Scroll/ConfigPanel/OptionsButtons/VolumeContainer/MusicVol'.modulate.a = 0.5
		set_volume(2, linear_to_db(0))

func _on_effect_toggle_toggled(toggled_on):
	config_file.set_value("MAIN_OPTIONS","EFFECTS_TOGGLED", toggled_on)
	effect_slider.editable = toggled_on
	
	if toggled_on:
		$'ConfigTabs/MAIN_OPTIONS/Scroll/ConfigPanel/OptionsButtons/VolumeContainer/SoundEffectVol'.modulate.a = 1
		set_volume(1, linear_to_db(config_file.get_value("MAIN_OPTIONS","EFFECTS_VOLUME")))
	else:
		$'ConfigTabs/MAIN_OPTIONS/Scroll/ConfigPanel/OptionsButtons/VolumeContainer/SoundEffectVol'.modulate.a = 0.5
		set_volume(1, linear_to_db(0))
#endregion

#region Audio
func set_volume(bus_id, new_db):
	AudioServer.set_bus_volume_db(bus_id, new_db)

func _on_master_slider_value_changed(value):
	config_file.set_value("MAIN_OPTIONS","MASTER_VOLUME", value)
	set_volume(0, linear_to_db(master_slider.value))

func _on_music_slider_value_changed(value):
	config_file.set_value("MAIN_OPTIONS","MUSIC_VOLUME", value)
	set_volume(2, linear_to_db(music_slider.value))

func _on_effect_slider_value_changed(value):
	config_file.set_value("MAIN_OPTIONS","EFFECTS_VOLUME", value)
	set_volume(1, linear_to_db(effect_slider.value))

func _on_master_slider_drag_ended(_value_changed):
	config_file.save(config_file_path)

func _on_music_slider_drag_ended(_value_changed):
	config_file.save(config_file_path)

func _on_effect_slider_drag_ended(_value_changed):
	config_file.save(config_file_path)
#endregion

func _on_visual_effect_selected(index):
	UI.ScreenEffect.change_effect(effect_menu.get_item_text(index))

func _on_language_menu_item_selected(index):
	settings_changed = true
	language_changed_detect = true
	var lang : String
	lang = lang_order[index]
	config_file.set_value("MAIN_OPTIONS","LANGUAGE", lang)
	TranslationServer.set_locale(lang)

