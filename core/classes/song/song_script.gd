extends Node2D
class_name SongScript

var song:Song:
	get():
		return Song.current

func _init() -> void:
	if is_instance_valid(Conductor.instance):
		Conductor.instance.step_hit.connect(_on_step_hit)
		Conductor.instance.beat_hit.connect(_on_beat_hit)

func _ready() -> void: pass
func _on_load_notes() -> void: pass
func _ready_post() -> void: pass

@warning_ignore("unused_parameter")
func _on_countdown_beat(step:int) -> void: pass

@warning_ignore("unused_parameter")
func _process(delta:float) -> void: pass

func _on_song_start() -> void: pass

@warning_ignore("unused_parameter")
func _on_step_hit(step:int) -> void: pass
@warning_ignore("unused_parameter")
func _on_beat_hit(beat:int) -> void: pass

@warning_ignore("unused_parameter")
func _on_note_hit(note:Note, strumline:Strumline, judge:String = "sick"): pass
@warning_ignore("unused_parameter")
func _on_note_miss(note:Note, strumline:Strumline): pass
@warning_ignore("unused_parameter")
func _on_ghost_tap(strumline:Strumline): pass

func _on_exit(): pass
func _on_song_finish(): pass
