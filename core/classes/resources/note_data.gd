extends Resource
class_name NoteData

enum PlayerType
{
	OPPONENT,
	PLAYER,
	EXTRA
}

@export var column:int = 0
@export var time:float = 0 # time in seconds (not milliseconds!!)
@export var length:float = 0

@export var type:String = ""
@export var data:Dictionary = {}

@export var player:PlayerType = PlayerType.PLAYER
