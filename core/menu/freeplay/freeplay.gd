extends Node2D

const DEFAULT_SONG_LIST:Array[SongMetadata] = []

static var current_item:int = 0
static var current_difficulty:int = 0
var controllable:bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for song in DEFAULT_SONG_LIST:
		create_song(song)
	
	for content in ContentManager.enabled_contents:
		for song in content.freeplay_song_list:
			create_song(song)
	await get_tree().create_timer(0.02).timeout # avoid the camera bug, kill me
	change_item(0)
	change_diff(0)

func change_item(change:int = 0) -> void:
	current_item = wrap(current_item + change, 0, %songs.get_child_count())
	%camera.global_position.y = %songs.get_child(current_item).global_position.y
	GlobalSound.play_sfx(preload("res://core/menu/scroll.ogg"))
	change_diff()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_up") && controllable:
		change_item(-1)
	elif Input.is_action_just_pressed("ui_down") && controllable:
		change_item(1)
	if Input.is_action_just_pressed("ui_left") && controllable:
		change_diff(-1)
	if Input.is_action_just_pressed("ui_right") && controllable:
		change_diff(1)
	if Input.is_action_just_pressed("ui_cancel") && controllable:
		controllable = false
		GlobalSound.play_sfx(preload("res://core/menu/cancel.ogg"))
		Transition.switch_scene(load("res://core/menu/main_menu/main_menu.tscn"))
	elif Input.is_action_just_pressed("ui_accept") && controllable:
		controllable = false
		GlobalSound.play_sfx(preload("res://core/menu/confirm.ogg"))

		Song.game_mode = Song.GameMode.FREEPLAY
		Song.difficulty = %songs.get_child(current_item).meta.difficulties[current_difficulty]
		Song.return_scene = load(self.scene_file_path)
		
		Song.start_playlist([%songs.get_child(current_item).meta])
	
	for item in %songs.get_children():
		item.modulate.a = 1.0 if item.get_index() == current_item else 0.5

func create_song(meta:SongMetadata) -> void:
	var item = load("res://core/menu/freeplay/song_item.tscn").instantiate()
	item.meta = meta
	%songs.add_child(item)

var prev_diff:String = "normal"

func change_diff(change:int = 0) -> void:
	current_difficulty = wrap(current_difficulty + change, 0, %songs.get_child(current_item).meta.difficulties.size())

	if change == 0 && %songs.get_child(current_item).meta.difficulties.has(prev_diff):
		current_difficulty = %songs.get_child(current_item).meta.difficulties.find(prev_diff)
	
	%difficulty_label.text = "< " if current_difficulty != 0 else "  "
	%difficulty_label.text += %songs.get_child(current_item).meta.difficulties[current_difficulty].to_upper()
	%difficulty_label.text += " >" if current_difficulty != (%songs.get_child(current_item).meta.difficulties.size() - 1) else "  "
	
	var key:String = %songs.get_child(current_item).meta._song_id + ":" + %songs.get_child(current_item).meta.difficulties[current_difficulty]
	if Save.scores.has(key):
		%score_label.text = "PERSONAL BEST: %s" % str(Save.scores.get(key).score)
	else:
		%score_label.text = "PERSONAL BEST: 0"
	
	%bg.size.x = %score_label.size.x
	
	prev_diff = %songs.get_child(current_item).meta.difficulties[current_difficulty]
