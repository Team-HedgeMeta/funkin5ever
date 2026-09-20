extends Resource
class_name CharterClipboard

var time: float = 0
var notes: Array[NoteData] = []

func _init(time: float) -> void:
	self.time = time
