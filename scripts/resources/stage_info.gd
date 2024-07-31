class_name StageInfo extends Resource

const STAGES : Dictionary = {
	'STAGE_ONE' = {}
}

@export var selected_stage_path : String
@export var locked : bool

var stage_lock : Dictionary = { ##TODO: TEMPORARY CACHE
	0: false,
	1: false,
	2: false,
	3: false,
	4: false
}
