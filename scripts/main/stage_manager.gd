## StageManager Singleton
## Contains functions, metadata, and controls stage in runtime
## Highly changeable data such as coins and health are managed by each stage StageAgent node
extends Node

signal stage_ended

var active_stage : Stage
var active_stage_agent : StageAgent
var on_stage : bool = false #? Queryable boolean that signals if the current active scene is considered a stage or not

func _ready() -> void:
	UI.event_layer.finish_panel.decison_made.connect(_on_stage_closing_decision_made)

func _on_stage_closing_decision_made() -> void:
	stage_ended.emit()

func start_stage(
		new_stage : Stage,
		new_stage_agent : StageAgent
	) -> void:
	active_stage = new_stage
	active_stage_agent = new_stage_agent
	on_stage = true
	UI.interface.set_visible(true)
	UI.pause_locked = false

func close_stage(success : bool = true) -> void: ## Invoke stage ended screen
	if UI.speed_toggled: UI.toggle_speed(false)
	UI.event_layer.finish_panel.conclude(success)
