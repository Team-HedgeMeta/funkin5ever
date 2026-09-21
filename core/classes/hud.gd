extends Control
class_name HUD

@export var player_strumline:Strumline
@export var opponent_strumline:Strumline

func _init() -> void:
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

func _on_song_finish(): pass
