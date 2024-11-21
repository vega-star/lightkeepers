extends Control

signal confirmation(value : bool)

@onready var confirmation_dialog : ConfirmationDialog = $ConfirmationDialog
@onready var finish_panel : Panel = $FinishPanel

func _ready():
	confirmation_dialog.canceled.connect(_on_confirmation_canceled)
	confirmation_dialog.confirmed.connect(_on_confirmation_confirmed)
	confirmation_dialog.get_child(1, true).set_horizontal_alignment(1)
	confirmation_dialog.get_child(1, true).set_vertical_alignment(1)

func request_confirmation(title : String, text : String, _ok_text : String = 'CONFIRM', _cancel_text : String = 'CANCEL') -> bool:
	UI.set_pause(true)
	confirmation_dialog.title = TranslationServer.tr(title)
	confirmation_dialog.dialog_text = TranslationServer.tr(text)
	confirmation_dialog.ok_button_text = _ok_text
	confirmation_dialog.cancel_button_text = _cancel_text
	confirmation_dialog.visible = true
	var confirmation_value = await confirmation
	
	UI.set_pause(false)
	confirmation_dialog.visible = false
	return confirmation_value

func _on_confirmation_canceled(): confirmation.emit(false)
func _on_confirmation_confirmed(): confirmation.emit(true)
