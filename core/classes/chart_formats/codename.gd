extends BasicChart
class_name CodenameChart

func check_format(song:String, difficulty:String = "normal") -> bool:
	var base = get_raw_chart(song, difficulty)
	if base.has("codenameChart"):
		return true
	elif base.has("strumLines"):
		return true
	return false

func get_chart(chart_path:String, difficulty:String = "normal") -> Chart:
	var base = BasicChart.get_raw_chart(chart_path, difficulty)
	var meta = BasicChart.get_raw_meta(chart_path)
	var chart = Chart.new()
	
	chart.bpm_changes.push_back(BPMChange.new(0, meta.bpm))
	chart.scroll_speed = base.scrollSpeed
	
	base.noteTypes.push_front("")
	
	for strumline in base.strumLines:
		for base_note in strumline.notes:
			var note_data:NoteData = NoteData.new()
			note_data.time = base_note.time / 1000
			note_data.column = base_note.id
			note_data.length = base_note.sLen / 1000
			note_data.type = base.noteTypes[int(base_note.type)]
			match int(strumline.type):
				0:
					note_data.player = NoteData.PlayerType.OPPONENT
				1:
					note_data.player = NoteData.PlayerType.PLAYER
				_:
					note_data.player = NoteData.PlayerType.EXTRA
			chart.notes.push_back(note_data)
	
	var base_events = BasicChart.get_raw_events(chart_path)
	if base_events.has("events"):
		base.events.append_array(base_events)
	
	var step_crotchet:float = (60 / chart.bpm_changes[0].bpm) / 4
	
	for base_event in base.events:
		if base_event.name == "Change BPM":
			chart.bpm_changes.push_back(BPMChange.new(base_event.time / 1000, base_event.args[0]))
		elif base_event.name == "Camera Movement":
			var speed:float = 1.9
			if base_event.args.size() > 1 && base_event.args[1] == false:
				speed = 0
			elif base_event.args.size() > 3 && base_event.args[3] != "CLASSIC":
				speed = (step_crotchet * base_event.args[2])
			
			var _trans:String = base_event.args[3] if (base_event.args.size() > 3 && base_event.args[3] != "CLASSIC") else "expo"
			var _ease:String = base_event.args[4] if (base_event.args.size() > 4) else "Out"
			
			chart._camera_movement_markers.push_back({
				"time": base_event.time / 1000,
				"focus_player": (base_event.args[0] if base_event.has("args") && base_event.args.size() > 0 else 0) != 0,
				"speed": speed,
				"ease": _trans + _ease
			})
		elif base_event.e == "Camera Zoom":
			var speed:float = 1
			if base_event.args.size() > 0 && base_event.args[0] == false:
				speed = 0
			elif base_event.args.size() > 4 && base_event.args[4] != "CLASSIC":
				speed = (step_crotchet * base_event.args[3])
			
			var _trans:String = base_event.args[4] if (base_event.args.size() > 4 && base_event.args[4] != "CLASSIC") else "expo"
			var _ease:String = base_event.args[5] if (base_event.args.size() > 5) else "Out"
			chart._camera_zoom_markers.push_back({
				"time": base_event.time / 1000,
				"zoom": (base_event.args[1] if base_event.has("args") && base_event.args.size() > 0 else 1),
				"direct": (base_event.args[6] if base_event.has("args") && base_event.args.size() > 5 else "stage") == "stage",
				"speed": speed,
				"ease": _trans + _ease
			})
	return chart
