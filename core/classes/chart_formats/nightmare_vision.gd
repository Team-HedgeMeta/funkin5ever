extends BasicChart
class_name NightmareVisionChart

func check_format(song:String, difficulty:String = "normal") -> bool:
	var base = get_raw_chart(song, difficulty)
	if base.has("song") && base.song is not String:
		if base.song.has("format") && base.song.format.begins_with("nmv"):
			return true
	return false

func get_chart(chart_path:String, difficulty:String = "normal") -> Chart:
	var base = BasicChart.get_raw_chart(chart_path, difficulty).song
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
			data.type = base_data[3] if base_data.size() > 3 and base_data[3] is String else ""
			data.player = NoteData.PlayerType.OPPONENT if int(base_data[1]) > 3 else NoteData.PlayerType.PLAYER
			
			chart.notes.push_back(data)
		
		if section.mustHitSection != prev_must_hit:
			chart._camera_movement_markers.push_back({"time": section_time, "focus_player": section.mustHitSection, "speed": 1.9, "ease": "expoOut"})
			prev_must_hit = section.mustHitSection
		
		if section.get("changeBPM", false):
			chart.bpm_changes.push_back(BPMChange.new(section_time, section.bpm))
			current_bpm = section.bpm
		section_time += ((60 / current_bpm) / 4) * section.get("lengthInSteps", 16)
	
	return chart
