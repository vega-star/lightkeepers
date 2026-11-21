class_name StageSchedule extends Resource

enum DIFFICULTIES {
	EASY,
	NORMAL,
	HARD,
	CHALLENGING,
	NIGHTMARE
}

## Used to describe difficulty of this certain schedule
@export var difficulty_category : DIFFICULTIES = 1

## Full collection of turns in stage
@export var turns : Array[Turn]
