## StageManager Singleton
## Contains functions, metadata, and controls stage in runtime
## Highly changeable data such as coins and health are managed by each stage StageAgent node
extends Node

signal stage_started
signal stage_ended

const RUN_DATA_STRUCTURE : Dictionary = {
	"status": {},
	"objects": {
		"towers": {}
	},
	"metadata": {}
}

var active_stage : Stage
var active_stage_agent : StageAgent
var on_stage : bool = false #? Queryable boolean that signals if the current active scene is considered a stage or not
var run_data : Dictionary

func _ready() -> void: UI.event_layer.finish_panel.decison_made.connect(_on_stage_closing_decision_made)

func _on_stage_closing_decision_made() -> void: stage_ended.emit()

func start_stage(new_stage : Stage) -> void:
	active_stage = new_stage
	active_stage_agent = new_stage.stage_agent
	run_data.clear()
	run_data = RUN_DATA_STRUCTURE.duplicate(true)
	on_stage = true
	UI.interface.set_visible(true)
	UI.pause_locked = false
	await new_stage.ready
	stage_started.emit()

func close_stage(success : bool = true) -> void: ## Invoke stage ended screen
	if UI.speed_toggled: UI.speed_toggled = false
	UI.event_layer.finish_panel.conclude(success)
