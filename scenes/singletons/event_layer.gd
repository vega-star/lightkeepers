extends CanvasLayer

signal confirmation(value : bool)

@onready var confirmation_dialog = $Control/ConfirmationDialog

func _ready():
	confirmation_dialog.canceled.connect(_on_confirmation_canceled)
	confirmation_dialog.confirmed.connect(_on_confirmation_confirmed)

func request_confirmation(title : String, text : String, confirm_text : String = 'Confirm', cancel_text : String = 'Cancel') -> bool:
	UI.set_pause(true)
	confirmation_dialog.title = TranslationServer.tr(title)
	confirmation_dialog.dialog_text = TranslationServer.tr(text)
	confirmation_dialog.visible = true
	var confirmation_value = await confirmation
	
	print(request_confirmation)
	UI.set_pause(false)
	confirmation_dialog.visible = false
	return confirmation_value

func _on_confirmation_canceled(): confirmation.emit(false)
func _on_confirmation_confirmed(): confirmation.emit(true)
