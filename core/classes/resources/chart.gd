@tool

extends Resource
class_name Chart

static var CHART_FORMATS = [VSliceChart, CodenameChart, NightmareVisionChart, PsychChart]

var _song_id:String = ""
var _difficulty:String = ""

@export var notes:Array[NoteData] = []

@export var scroll_speed:float = 1
@export var bpm_changes:Array[BPMChange] = []

# for converter, marker would be {time: 0, focus_player: true}
var _camera_movement_markers:Array[Dictionary] = []

func sort() -> void:
	notes.sort_custom(func(a: NoteData, b: NoteData) -> bool:
		if a.time < b.time:
			return true
		return false
	)
