extends Event

signal fuse_successful
signal fuse_failed

## Fuse
# Will merge two Elements into a complex Essence

@onready var input_1 = $BottomEssences/Slot/Input1
@onready var input_2 = $BottomEssences/Slot3/Input2
@onready var output = $Slot3/Output

