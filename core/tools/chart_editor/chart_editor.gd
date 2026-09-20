extends CanvasLayer
class_name ChartEditor

# TODO:
# - More Undo/Redo-able actions

var undo_snapshots:Array[Chart] = []
var redo_snapshots:Array[Chart] = []
@onready var snapshot:Chart = song.chart

var song:Song:
	get:
		return get_parent() as Song

var conductor:Conductor:
	get:
		return song.conductor

# var undo_redo:UndoRedo = UndoRedo.new()

@onready var camera:Camera2D = %camera
@onready var note_group:Node2D = %note_group

@onready var grid_initial_y:float = %player_grid.global_position.y

func _ready() -> void:
	DebugDisplay.label.visible = false
	
	Discord.song()
	DiscordRPC.details = "Editing chart of: " + DiscordRPC.details
	DiscordRPC.start_timestamp = int(Time.get_unix_time_from_system())
	DiscordRPC.refresh()
	
	
	%bg.modulate.a = 0
	%grid.position.x += 500
	var tween:Tween = self.create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(%bg, "modulate:a", 0.25, 0.5)
	tween.tween_property(%grid, "position:x", 0, 0.5)
	
	song.in_chart_editor = true
	song.hud.visible = false
	song.countdown.cancel()
	if !song.animation_player.is_playing() or song.animation_player.current_animation != "song":
		song.animation_player.play("song")
		song.animation_player.seek(0)
		conductor.song_position = 0
	song.animation_player.pause()
	
	reload_snapshot()
	
func reload_snapshot() -> void:
	for note in note_group.get_children(): note.queue_free()
	
	for note_data in snapshot.notes:
		var note:Note = load("res://core/gameplay/notes/note.tscn").instantiate()
		note.editor = true
		note.data = note_data
		note.scale = Vector2(0.3, 0.3)
		
		note_group.add_child(note)
		
		var target_grid:Control = %player_grid
		match note_data.player:
			NoteData.PlayerType.OPPONENT:
				target_grid = %opponent_grid
			NoteData.PlayerType.EXTRA:
				target_grid = %extra_grid
		
		note.global_position.x = target_grid.global_position.x + floor(target_grid.grid_size.x * note_data.column) + (target_grid.grid_size.x / 2)
		note.global_position.y = maxf(target_grid.global_position.y + (conductor.get_step_from_time(note_data.time) * target_grid.grid_size.y) + (target_grid.grid_size.y / 2), 0)

func _process(delta: float) -> void:
	if song.animation_player.is_playing():
		conductor.song_position = song.animation_player.current_animation_position
	
	if Input.is_action_just_pressed("editor_playback"):
		if song.animation_player.is_playing():
			song.animation_player.pause()
		else:
			resume()
	
	%strumline.global_position.y = grid_initial_y + conductor.get_step_from_time(conductor.song_position) * %player_grid.grid_size.y
	
	if %strumline.global_position.y >= 720:
		%grid_parallax.repeat_times = 2
	elif %grid_parallax.repeat_times != 1:
		%grid_parallax.repeat_times = 1
	
	camera.global_position.y = %strumline.global_position.y
	
func resume() -> void:
	seek_animation()
	song.animation_player.play()

func seek_animation() -> void:
	song.animation_player.play()
	song.animation_player.seek(conductor.song_position)
	song.animation_player.pause()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				conductor.song_position -= 1
				seek_animation()
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				conductor.song_position += 1
				seek_animation()
	if event is InputEventPanGesture: # trackpad gesture
		song.animation_player.pause()
		conductor.song_position -= event.delta.y/10
		if conductor.song_position < 0:
			conductor.song_position = 0
		seek_animation()
