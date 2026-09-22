extends Node2D

@onready var death_player:AudioStreamPlayer = %death
@onready var loop_player:AudioStreamPlayer = %loop
@onready var confirm_player:AudioStreamPlayer = %confirm

var character:Character2D
var conductor:Conductor
var camera:Camera2D

var controllable:bool = true

func _ready() -> void:
	if Song.current.hud.player_strumline.characters.size() < 1:
		print("[Death Screen] Current player is invalid! Can't start death screen.")
		return
	
	var origin_character = Song.current.hud.player_strumline.characters[0]
	character = origin_character.death_character.instantiate()
	add_child(character)
	if origin_character is Character3D:
		character.global_position = Vector2(origin_character.global_position.x, origin_character.global_position.y)
	else:
		character.global_position = origin_character.global_position
	
	conductor = Conductor.new(false)
	conductor.set_bpm_changes([BPMChange.new(0, character.death_music_bpm)])
	
	conductor.beat_hit.connect(_beat_hit)
	
	death_player.stream = origin_character.death_music_intro
	loop_player.stream = origin_character.death_music_loop
	confirm_player.stream = origin_character.death_music_retry
	
	for child in Song.current.get_children():
		if child is Camera2D:
			camera = child
			break
	if is_instance_valid(camera):
		var twn = self.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		twn.tween_property(camera, "global_position", Vector2(character.global_position.x, character.global_position.y - 200), 2)
	
	death_player.play()
	death_player.finished.connect(start_loop)
	character.play_anim("intro")

func start_loop() -> void:
	loop_player.finished.connect(func():
		if controllable:
			loop_player.play()
	)
	loop_player.play()
	_beat_hit(0)
	
func _beat_hit(beat:int) -> void:
	if controllable:
		character.play_anim("loop")

func _process(delta: float) -> void:
	if loop_player.playing:
		conductor.song_position = loop_player.get_playback_position()
	if controllable && Input.is_action_just_pressed("ui_accept"):
		controllable = false
		loop_player.stop()
		death_player.stop()
		
		confirm_player.play()
		character.play_anim("retry")
		get_tree().create_timer(2).timeout.connect(func():
			get_tree().paused = false
			get_parent().process_mode = Node.PROCESS_MODE_DISABLED
			Song.current._on_exit()
			Transition.switch_scene(load(Song.current.scene_file_path))
		)
	if controllable && Input.is_action_just_pressed("ui_cancel"):
		controllable = false
		get_tree().paused = false
		get_parent().process_mode = Node.PROCESS_MODE_DISABLED
		Song.current._on_exit()
		Transition.switch_scene(Song.return_scene)
