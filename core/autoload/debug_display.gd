extends CanvasLayer

@onready var label:Label = %label

var display_mode:int = 1

var memory_peak:float = 0
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("debug_switch"):
		display_mode = wrap(display_mode + 1, 0, 3)
		
	if display_mode == 0:
		self.visible = false
		return
	else:
		self.visible = true
	
	var mem = OS.get_static_memory_usage() / (1024 * 1024)
	if mem > memory_peak:
		memory_peak = mem
	
	label.text = "%sFPS • %sMB / %sMB" % [str(Engine.get_frames_per_second()), str(mem), str(memory_peak)]
	
	if display_mode == 2:
		label.text += "\nGodot Version: " + Engine.get_version_info().string
		label.text += "\nfunkin5ever Version: " + ProjectSettings.get("application/config/version")
		if Conductor.instance != null:
			label.text += "\n[Conductor Info]\nCurrent BPM: %s\nSong Position: %s\nCurrent Step: %s\nCurrent Beat: %s" % [Conductor.instance.get_bpm(), float(int(Conductor.instance.song_position * 100)) / 100, Conductor.instance.current_step, Conductor.instance.current_beat]
