## Event Class
# Stores general communication from events to the game itself
class_name Event extends Control

signal event_aborted
signal event_completed(event_metadata : Dictionary)

@export_group('Event Properties')
@export_enum('GENERAL:0', 'CRAFTING:1', 'CHOICE:2') var slot_type : int
@export var enforced : bool = false ## If true, the event cannot be closed until event_completed signal is emitted
@export var volatile : bool = true ## Is freed when exited

var locked : bool = false
var stage : Stage

func _ready():
	_set_event_ready()

func _set_event_ready():
	stage = get_tree().get_first_node_in_group('stage')
	event_completed.connect(_on_event_completed)
	if enforced: locked = true

func _on_event_completed():
	if locked: locked = false
	_close_event()

func _close_event():
	if enforced: return
	visible = false
	if volatile: call_deferred("queue_free")
