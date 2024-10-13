extends MenuPage

@onready var grid_container: GridContainer = $ScrollContainer/GridContainer

func set_focus(): grid_container.get_child(0).grab_focus()

func _ready(): _page_ready()

func _on_return_button_pressed(): owner.set_page_position(0) #? Main Screen

func _on_quit_button_pressed(): get_tree().quit() #? Quit game
