extends Resource
class_name ChartEditorClipboard

var time:float = 0
var notes:Array[NoteData] = []

func _init(_time: float = 0) -> void:
	self.time = _time
