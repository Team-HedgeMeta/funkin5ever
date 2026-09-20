@tool
extends Node2D
class_name Song

enum GameMode
{
	STORY,
	FREEPLAY,
	CHARTING
}

static var current:Song
static var playlist:Array[SongMetadata] = []
static var difficulty:String = "normal"
static var story_level:String
static var story_stats:GameStats
static var game_mode:GameMode = GameMode.FREEPLAY
static var return_scene:PackedScene

@export var animation_player:AnimationPlayer

@export var skip_countdown:bool = false
@export var camera_bop_interval:int = 4

@export_category("Theme")
@export var hud_scene:PackedScene = preload("res://core/gameplay/hud/default.tscn")
@export var countdown_skin:CountdownSkin = preload("res://core/gameplay/countdown/default/skin.tres")
@export var pause_scene:PackedScene = preload("res://core/gameplay/pause_screen.tscn")
@export var death_scene = preload("res://core/gameplay/death/death_screen.tscn")

@export_category("Tools")
@warning_ignore("unused_private_class_variable")
@export_tool_button("Convert Camera Events To KeyFrame") var _import_camera_events:Callable = import_camera_events
@export_category("Extra")
@export var extra_data:Dictionary[String, Variant] = {}

var conductor:Conductor

var chart:Chart
var meta:SongMetadata:
	get():
		return playlist[0]

var scripts:Array[SongScript] = []

var hud_layer:CanvasLayer
var hud:HUD
var countdown:Countdown

var song_started:bool = false
var in_cutscene:bool = false
var in_chart_editor:bool = false
var stats:GameStats


var player_vocal:SongStreamPlayer

signal _before_ready_post # I'M GOING INSANE

static func start_playlist(_playlist:Array[SongMetadata]) -> void:
	playlist = []
	for song in _playlist:
		playlist.push_back(song)
	if playlist.size() > 0:
		Transition.switch_scene(playlist[0].get_scene())
	else:
		print("[SONG] Playlist is empty, cannot start the game!")

func _init() -> void:
	if Engine.is_editor_hint(): return
	current = self

func _ready() -> void:
	if Engine.is_editor_hint(): return
	# fix when trying to run from editor directly
	if playlist.size() < 1:
		playlist.push_back(load(self.scene_file_path.replace("song.tscn", "meta.tres")))
	
	if GlobalSound.music_player.playing:
		GlobalSound.music_player.stop()
	
	conductor = Conductor.new()
	add_child(conductor)
	conductor.beat_hit.connect(_on_beat_hit)
	
	chart = meta.get_chart(difficulty)
	conductor.set_bpm_changes(chart.bpm_changes)
	
	stats = GameStats.new()
	
	animation_player.animation_finished.connect(func(n):
		if in_chart_editor: return
		match n:
			"intro_cutscene":
				_start_countdown()
			"song":
				_song_finished()
			"end_cutscene":
				_song_exit()
			
	)
	
	# local scripts
	if DirAccess.dir_exists_absolute(meta.resource_path.replace("meta.tres", "scripts/")):
		for script_file in DirAccess.get_files_at(meta.resource_path.replace("meta.tres", "scripts/")):
			if script_file.ends_with(".gd"):
				var instance = load(meta.resource_path.replace("meta.tres", "scripts/").path_join(script_file)).new() as SongScript
				scripts.push_back(instance)
				instance._ready()
	# global scripts
	for script_file in ContentManager.list_content_paths("gameplay/scripts/"):
		if script_file.ends_with(".gd"):
			var instance = load(ContentManager.get_content_path("gameplay/scripts/" + script_file)).new() as SongScript
			scripts.push_back(instance)
			instance._ready()
	
	hud_layer = CanvasLayer.new()
	add_child(hud_layer)
	hud = hud_scene.instantiate() as HUD
	
	if is_instance_valid(hud):
		hud_layer.add_child(hud)
	
		hud.player_strumline.scroll_speed = chart.scroll_speed
		hud.player_strumline.note_hit.connect(_player_note_hit)
		hud.player_strumline.note_miss.connect(_default_note_miss)
		hud.player_strumline.note_miss.connect(_player_note_miss)
		hud.opponent_strumline.scroll_speed = chart.scroll_speed
		hud.opponent_strumline.note_hit.connect(_opponent_note_hit)
		hud.opponent_strumline.note_miss.connect(_default_note_miss)
	
		for note in chart.notes:
			match note.player:
				NoteData.PlayerType.PLAYER:
					hud.player_strumline.note_queues.push_back(note)
				NoteData.PlayerType.OPPONENT:
					hud.opponent_strumline.note_queues.push_back(note)
	
	if is_instance_valid(animation_player.find_child("player", false)):
		if animation_player.find_child("player", false) is SongStreamPlayer:
			player_vocal = animation_player.find_child("player", false)
	elif is_instance_valid(animation_player.find_child("vocal", false)):
		if animation_player.find_child("vocal", false) is SongStreamPlayer:
			player_vocal = animation_player.find_child("vocal", false)
	
	countdown = preload("res://core/gameplay/countdown/countdown.tscn").instantiate() as Countdown
	countdown.skin = countdown_skin
	
	countdown.countdown_step.connect(func(step:int):
		for script in scripts:
			script._on_countdown_beat(step)
		if is_instance_valid(hud):
			hud._on_countdown_beat(step)
	)
	
	_before_ready_post.emit()
	
	if animation_player.has_animation("intro_cutscene"):
		in_cutscene = true
		animation_player.play("intro_cutscene")
	else:
		_start_countdown()
	
func _start_countdown() -> void:
	if in_chart_editor: return
	for script in scripts:
		script._ready_post()
	if is_instance_valid(hud):
		hud._ready_post()
	
	in_cutscene = false
	
	# Discord thing
	Discord.song()
	
	if skip_countdown:
		_start_song()
		return
	
	conductor.song_position = -conductor.get_crotchet() * 5
	
	countdown.countdown_finished.connect(_start_song)
	hud_layer.add_child(countdown)
	countdown.start()

func _start_song() -> void:
	animation_player.play("song")

	for script in scripts:
		script._on_song_start()
	if is_instance_valid(hud):
		hud._on_song_start()
	
	song_started = true

func _default_note_miss(note:Note, _type:Strumline.MissType) -> void:
	for script in scripts:
		script._on_note_miss(note, note.strumline)
	if is_instance_valid(hud):
		hud._on_note_miss(note, note.strumline)

func _player_note_hit(note:Note, is_sustain_part:bool) -> void:
	if is_instance_valid(player_vocal): player_vocal.volume_linear = 1
	if !is_sustain_part:
		var judge = stats.score_note(note)
		for script in scripts:
			script._on_note_hit(note, note.strumline, judge)
		if is_instance_valid(hud):
			hud._on_note_hit(note, note.strumline, judge)
	
func _player_note_miss(_note:Note, type:Strumline.MissType) -> void:
	if is_instance_valid(player_vocal): player_vocal.volume_linear = 0
	if type == Strumline.MissType.NOTE_MISS:
		stats.miss_note()
	
func _opponent_note_hit(note:Note, is_sustain_part:bool) -> void:
	if !is_sustain_part:
		for script in scripts:
			script._on_note_hit(note, note.strumline)
		if is_instance_valid(hud):
			hud._on_note_hit(note, note.strumline)
	
func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if !in_chart_editor:
		if !in_cutscene && animation_player.is_playing():
			conductor.song_position = animation_player.current_animation_position
		else:
			conductor.song_position += delta
		
		for script in scripts:
			script._process(delta)
		
		if Input.is_action_just_pressed("ui_accept"):
			var pause = pause_scene.instantiate()
			add_child(pause)
			get_tree().paused = true
		
		if Input.is_action_just_pressed("debug_chart_editor"):
			var editor:ChartEditor = load("res://core/tools/chart_editor/chart_editor.tscn").instantiate()
			add_child(editor)

		if Input.is_action_just_pressed("debug_kill"):
			stats.health = 0
		
		if stats.health == 0:
			hud_layer.visible = false
			var death = death_scene.instantiate()
			add_child(death)
			get_tree().paused = true

var zoom_tween:Tween
func _on_beat_hit(beat:int) -> void:
	if in_chart_editor: return
	if beat % camera_bop_interval == 0:
		if is_instance_valid(zoom_tween):
			zoom_tween.kill()
		if is_instance_valid(hud):
			hud.scale += Vector2(0.02, 0.02)
			zoom_tween = get_tree().create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
			zoom_tween.tween_property(hud, "scale", Vector2.ONE, conductor.get_crotchet() * 4)

func _on_exit() -> void:
	for script in scripts:
		script.queue_free()
		scripts.erase(script)
	
	Discord.menu()
	GlobalSound.play_music(load("res://core/menu/music.ogg"))
	
func _song_finished() -> void:
	if animation_player.has_animation("end_cutscene"):
		in_cutscene = true
		animation_player.play("end_cutscene")
	else:
		_song_exit()

func _song_exit() -> void:
	for script in scripts:
		script._on_song_finish()
	if is_instance_valid(hud):
		hud._on_song_finish()
	
	_on_exit()
	match game_mode:
		GameMode.STORY:
			if story_stats == null:
				story_stats = GameStats.new()
			story_stats.score += stats.score
			if playlist.size() > 1:
				playlist.pop_front()
				Transition.switch_scene(playlist[0].get_scene())
			else:
				var key:String = story_level + ":" + chart._difficulty
				if Save.scores.has(key):
					var prev_stats:GameStats = Save.scores.get(key)
					if story_stats.score > prev_stats.score:
						Save.scores.set(key, story_stats)
				else:
					Save.scores.set(key, story_stats)
				Save.save()
				story_stats = null
				Transition.switch_scene(return_scene)
		_: #GameMode.FREEPLAY
			story_stats = null
			var key:String = meta._song_id + ":" + chart._difficulty
			if Save.scores.has(key):
				var prev_stats:GameStats = Save.scores.get(key)
				if stats.score > prev_stats.score:
					Save.scores.set(key, stats)
			else:
				Save.scores.set(key, stats)
			Save.save()
			Transition.switch_scene(return_scene)

func import_camera_events() -> void:
	if !Engine.is_editor_hint():
		return
	if !self.extra_data.has("player_camera_position") or !self.extra_data.has("opponent_camera_position"):
		print("add 'player_camera_position' and 'opponent_camera_position' to extra data, to convert camera events properly!")
		return
	
	var new_meta:SongMetadata = load(self.scene_file_path.replace("song.tscn", "meta.tres"))
	if !is_instance_valid(self.animation_player):
		print("AnimationPlayer is not assigned!")
		return
		
	var camera:Camera2D
	
	for child in self.get_children():
		if child is Camera2D:
			camera = child as Camera2D
			break
	if !is_instance_valid(camera):
		print("Cannot find main camera!")
		return
	
	# ok so we can finally convert shitz
	var new_chart:Chart = new_meta.get_chart()
	var song_animation:Animation = animation_player.get_animation("song")
	
	var camera_track:int = song_animation.add_track(Animation.TYPE_VALUE, 0)
	song_animation.track_set_path(camera_track, NodePath(String(self.get_path_to(camera)) + ":position"))
	
	var prev_position:Vector2 = camera.position
	for marker in new_chart._camera_movement_markers:
		var target:Vector2 = extra_data.get("player_camera_position") if marker.get("focus_player") else extra_data.get("opponent_camera_position")
		song_animation.track_insert_key(camera_track, marker.get("time"), prev_position, 0.5)
		song_animation.track_insert_key(camera_track, marker.get("time") + 1.1, target, 0)
		prev_position = target
