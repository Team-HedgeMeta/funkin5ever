extends BasicChart
class_name Funkin5everChart

func check_format(song:String, difficulty:String = "normal") -> bool:
	var base = get_raw_chart(song, difficulty)
	if base.has("scroll_speed") or base.has("bpm_changes"):
		return true
	return false

func get_chart(chart_path:String, difficulty:String = "normal") -> Chart:
	var base = get_raw_chart(chart_path, difficulty)
	var chart:Chart = Chart.new()
	
	chart.scroll_speed = base.scroll_speed
	
	for change in base.bpm_changes:
		chart.bpm_changes.push_back(BPMChange.new(change.time, change.bpm, change.get("denominator", 4), change.get("numerator", 4)))
	
	for n in base.notes:
		var note = NoteData.new()
		note.column = n.column
		note.time = n.time
		note.length = n.get("length", 0)
		note.type = n.get("type", "")
		note.player = [NoteData.PlayerType.OPPONENT, NoteData.PlayerType.PLAYER, NoteData.PlayerType.EXTRA][n.get("player", 0)]
		if n.has("data") && !n.data.is_empty(): note.data = n.get("data")
	
		chart.notes.push_back(note)
	
	return chart

static func export_string(chart:Chart) -> String:
	var result:Dictionary = {
		"bpm_changes": [],
		"notes": []
	}
	
	result.set("scroll_speed", chart.scroll_speed)
	
	for change in chart.bpm_changes:
		var export_change:Dictionary = {"time": change.time, "bpm": change.bpm}
		if change.denominator != 4: export_change.set("denominator", change.denominator)
		if change.numerator != 4: export_change.set("numerator", change.numerator)
		result.bpm_changes.push_back(export_change)
	
	for note in chart.notes:
		var export_note:Dictionary = {"column": note.column, "time": note.time}
		if note.length > 0: export_note.set("length", note.length)
		if !note.type.is_empty(): export_note.set("type", note.type)
		if !note.data.is_empty(): export_note.set("data", note.data)
		export_note.set("player", [NoteData.PlayerType.OPPONENT, NoteData.PlayerType.PLAYER, NoteData.PlayerType.EXTRA].find(note.player))
		
		result.notes.push_back(export_note)
	
	return JSON.stringify(result, "\t")
