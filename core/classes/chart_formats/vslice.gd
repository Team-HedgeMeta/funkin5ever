extends BasicChart
class_name VSliceChart

func check_format(chart_path:String, difficulty:String = "normal") -> bool:
	var base = get_raw_chart(chart_path, difficulty)
	if base.has("hard") or base.has("easy") or base.has("normal") or base.has("erect"):
		return true
	elif base.has("generatedBy") and base.generatedBy.contains("Friday Night Funkin'"):
		return true
	return false

func get_chart(chart_path:String, difficulty:String = "normal") -> Chart:
	var base = BasicChart.get_raw_chart(chart_path, difficulty)
	var meta = BasicChart.get_raw_meta(chart_path)
	var chart = Chart.new()
	
	for original_change in meta.timeChanges:
		chart.bpm_changes.push_back(BPMChange.new(original_change.t / 1000, original_change.bpm, original_change.get("n", 4), original_change.get("d", 4)))
	chart.scroll_speed = base.scrollSpeed.get(difficulty)
	
	for base_note in base.notes.get(difficulty):
		var note_data:NoteData = NoteData.new()
		note_data.time = base_note.t / 1000
		note_data.column = int(base_note.d) % 4
		note_data.length = base_note.l / 1000 if base_note.has("l") else 0
		note_data.type = base_note.get("k", "")
		if base_note.d > 3: # opponent
			note_data.player = NoteData.PlayerType.OPPONENT
		else: # player
			note_data.player = NoteData.PlayerType.PLAYER
		chart.notes.push_back(note_data)
	
	var step_crotchet:float = (60 / chart.bpm_changes[0].bpm) / 4
	
	for event in base.events:
		if event.e == "FocusCamera":
			var speed:float = (step_crotchet * event.v.get("duration")) if event.v.has("duration") else 1.9
			if event.v.get("ease", "CLASSIC") == "CLASSIC":
				speed = 2.8
			elif event.v.get("ease") == "INSTANT":
				speed = 0
			
			var _trans:String = event.v.get("ease", "CLASSIC")
			if _trans == "CLASSIC" or _trans == "INSTANT": _trans = "expo"
			var _ease:String = event.v.get("easeDir", "")
			
			chart._camera_movement_markers.push_back({"time": event.t / 1000, "focus_player": event.v.get("char", 0) == 0, "speed": speed, "ease": _trans + _ease})
		elif event.e == "ZoomCamera":
			var speed:float = (step_crotchet * event.v.get("duration")) if event.v.has("duration") else step_crotchet * 4
			if event.v.get("ease", "CLASSIC") == "CLASSIC":
				speed = 1
			elif event.v.get("ease") == "INSTANT":
				speed = 0
			
			var _trans:String = event.v.get("ease", "CLASSIC")
			if _trans == "CLASSIC" or _trans == "INSTANT": _trans = "expo"
			var _ease:String = event.v.get("easeDir", "")
			
			chart._camera_zoom_markers.push_back({"time": event.t / 1000, "zoom": event.v.get("zoom", 1), "direct": event.v.get("mode", "stage") == "direct", "speed": speed, "ease": _trans + _ease})
	return chart
