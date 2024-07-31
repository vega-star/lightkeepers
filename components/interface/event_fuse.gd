extends Event

signal fuse_successful
signal fuse_failed

## Fuse
# Will merge two Elements into a complex Essence

@onready var input_1 = $BottomEssences/Slot/Input1
@onready var input_2 = $BottomEssences/Slot3/Input2
@onready var output = $Slot3/Output

const COMBINATIONS : Dictionary = {
	"fire": {
		"fire": "conflagration"
	}
}

func _on_close_event_button_pressed():
	print('close event pressed')
	if enforced: return
	
	visible = false
	call_deferred("queue_free")
