extends Panel

@export var editor:ChartEditor

@onready var time_info:Label = $title/time_info
@onready var step_info:Label = $title/step_info
@onready var beat_info:Label = $title/beat_info
@onready var measure_info:Label = $title/measure_info

func _process(delta: float) -> void:
	time_info.text = "Time: %s\n(RAW: %s)" % [format_time(editor.conductor.song_position), roundf(editor.conductor.song_position * 100) / 100]
	step_info.text = "Step: %s" % editor.conductor.current_step
	beat_info.text = "Beat: %s" % editor.conductor.current_beat
	measure_info.text = "Measure: %s" % (int(float(editor.conductor.current_beat) / 4)) # for now

func format_time(input:int) -> String:
	var min = floor(input / 60)
	var sec = input % 60
	return "%02d : %02d" % [min, sec]
