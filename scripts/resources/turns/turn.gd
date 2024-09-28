class_name Turn extends Resource
## Turn Resource
##
## Differentiate from wave by containing multiple waves of various enemies
## Is iterated and contained by TurnSchedule resource

## An array of every wave contained in this turn
@export var turn_waves : Array[Wave]

## Coins added when the turn is finished
@export var coins_on_turn_completion : int = 25
