extends Node
class_name Conductor

static var instance:Conductor

var song_position:float = 0:
	set(value):
		song_position = value
		update_position()

var current_step:int = -1
var current_beat:int = -1

signal step_hit(s:int)
signal beat_hit(b:int)

var bpm_changes:Array[BPMChange] = []

func _init(replace_instance:bool = true) -> void:
	self.name = "conductor"
	if replace_instance:
		if instance != null:
			instance.queue_free()
		instance = self
	
func set_bpm_changes(changes:Array[BPMChange]) -> void:
	bpm_changes = changes.duplicate_deep(0)
	if bpm_changes.size() < 1:
		bpm_changes.push_back(BPMChange.new())

func update_position() -> void:
	var old_step:int = current_step
	var old_beat:int = current_beat
	current_step = floor(get_step_from_time(self.song_position))
	current_beat = floor(current_step / 4)

	if(old_step != current_step):
		step_hit.emit(current_step)
	if (old_beat != current_beat):
		beat_hit.emit(current_beat)

func get_bpm(time:float = song_position) -> float:
	return get_bpm_change(time).bpm
	
func get_crotchet(time:float = song_position) -> float:
	return 60 / get_bpm_change(time).bpm

func get_step_crotchet(time:float = song_position) -> float:
	return get_crotchet(time) / 4

func get_time_from_step(target_step:float = 0.0) -> float:
	if target_step < 0: return -1
	if target_step == 0: return 0
	
	var current_calc_step:float = 0
	var current_calc_time:float = 0
	
	for i in range(bpm_changes.size()):
		var change = bpm_changes[i]
		var step_crotchet = get_step_crotchet(change.time)
		
		var next_time = bpm_changes[i+1].time if i + 1 < bpm_changes.size() else 999999.0
		var max_steps_in_section = (next_time - change.time) / step_crotchet
		
		if target_step <= current_calc_step + max_steps_in_section:
			var remaining_steps = target_step - current_calc_step
			return change.time + (remaining_steps * step_crotchet)
		else:
			current_calc_step += max_steps_in_section
			current_calc_time = next_time
			
	return current_calc_time

func get_step_from_time(time:float = 0.0) -> float:
	var calc_step:float = 0
	if time < 0: return -1
	if time == 0: return 0
	
	for i in range(bpm_changes.size()):
		var change = bpm_changes[i]
		var next_time = bpm_changes[i+1].time if i + 1 < bpm_changes.size() else time
		var end_time = min(time, next_time)
		
		if time >= change.time:
			var duration = end_time - change.time
			calc_step += duration / get_step_crotchet(change.time)
		
		if i + 1 < bpm_changes.size() and time < bpm_changes[i+1].time:
			break
			
	return calc_step

func get_bpm_change(time:float = song_position) -> BPMChange:
	var result:BPMChange = bpm_changes[0]
	for change in bpm_changes:
		if time >= change.time:
			result = change
	return result
