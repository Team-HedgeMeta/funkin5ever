extends BasicChart
class_name PsychChart

func check_format(chart_path:String, difficulty:String = "normal") -> bool:
	var base = get_raw_chart(chart_path, difficulty)
	if base.has("format") && base.format.begins_with("psych_v1"):
		return true
	elif base.has("song") && base.song is not String: #legacy
		return true
	return false

func get_chart(chart_path:String, difficulty:String = "normal") -> Chart:
	var legacy:bool = false
	var base = BasicChart.get_raw_chart(chart_path, difficulty)
	if base.song is not String: # legacy format
		legacy = true
		base = base.song
	var chart = Chart.new()
	
	var section_time:float = 0
	var current_bpm:float = base.bpm
	var prev_must_hit:bool = !base.notes[0].mustHitSection
	
	chart.scroll_speed = base.speed
	chart.bpm_changes.push_back(BPMChange.new(0, base.bpm))
	
	for section in base.notes:
		for base_data in section.sectionNotes:
			var data = NoteData.new()
			data.time = base_data[0] / 1000
			data.column = int(base_data[1]) % 4
			data.length = base_data[2] / 1000
			if base_data.size() > 3:
				if base_data[3] is String:
					data.type = base_data[3]
			
			if legacy:
				if (section.mustHitSection && base_data[1] < 4) or (!section.mustHitSection && base_data[1] > 3):
					data.player = NoteData.PlayerType.PLAYER
				else:
					data.player = NoteData.PlayerType.OPPONENT
			else:
				if base_data[1] < 4:
					data.player = NoteData.PlayerType.PLAYER
				else:
					data.player = NoteData.PlayerType.OPPONENT
			
			chart.notes.push_back(data)
		
		if section.mustHitSection != prev_must_hit:
			chart._camera_movement_markers.push_back({"time": section_time, "focus_player": section.mustHitSection, "speed": 1.9, "ease": "expoOut"})
			prev_must_hit = section.mustHitSection
		
		if section.get("changeBPM", false):
			chart.bpm_changes.push_back(BPMChange.new(section_time, section.bpm))
			current_bpm = section.bpm
		section_time += ((60 / current_bpm) / 4) * (section.get("lengthInSteps") if section.has("lengthInSteps") else section.get("sectionBeats", 4) * 4)
	return chart
