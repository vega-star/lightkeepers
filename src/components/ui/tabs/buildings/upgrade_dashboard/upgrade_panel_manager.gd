class_name UpgradePanelManager extends VBoxContainer

const LIMIT_RULES : Array[int] = [5, 2]
const LIMIT_MAP : Array[bool] = [
	false, #? First tree above threshold
	false, #? Second tree above threshold
	false #? Primary tree locked as above second threshold + 1
]

var stored_limit : Array[bool] = LIMIT_MAP.duplicate() #? Duplicated to be writable. Constants cannot be edited!
