@tool

extends Resource
class_name Chart

static var CHART_FORMATS = [VSliceChart, CodenameChart, NightmareVisionChart, PsychChart]

var _song_id:String = ""
var _difficulty:String = ""

@export var notes:Array[NoteData] = []

@export var scroll_speed:float = 1
@export var bpm_changes:Array[BPMChange] = []

# for converter, marker would be {time: 0, focus_player: true, speed: 1.2, ease: linear} and {time: 0, zoom: 1, direct: false, speed: 0.5, ease: linear}
var _camera_movement_markers:Array[Dictionary] = []
var _camera_zoom_markers:Array[Dictionary] = []

func sort() -> void:
	notes.sort_custom(func(a: NoteData, b: NoteData) -> bool:
		if a.time < b.time:
			return true
		return false
	)

func fix_markers() -> void:
	# fix markers and stuff
	var prev_marker:Dictionary
	for marker in _camera_movement_markers:
		if prev_marker != null && prev_marker.has("time"):
			if marker.get("time") < prev_marker.get("time") + prev_marker.get("speed"):
				prev_marker.set("speed", marker.get("time"))
		prev_marker = marker
	
	var prev_cam_marker:Dictionary
	for marker in _camera_zoom_markers:
		if prev_cam_marker != null && prev_cam_marker.has("time"):
			if marker.get("time") < prev_cam_marker.get("time") + prev_cam_marker.get("speed"):
				prev_cam_marker.set("speed", marker.get("time"))
		prev_cam_marker = marker
