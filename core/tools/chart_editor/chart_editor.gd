extends CanvasLayer
class_name ChartEditor

# TODO:
# - More Undo/Redo-able actions

const UNDO_LIMIT:float = 50

var undo_redo: UndoRedo = UndoRedo.new()
var clipboard:ChartEditorClipboard
var selected_notes:Array[Note] = []

var song:Song:
	get:
		return get_parent() as Song

var conductor:Conductor:
	get:
		return song.conductor

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
	song.hud_layer.visible = false
	for strum in Strumline.instances:
			for note in strum.note_group.get_children(): note.free()
			strum.note_queue_index = 0
	
	if is_instance_valid(song.countdown):
		song.countdown.cancel()
	if !song.animation_player.is_playing() or song.animation_player.current_animation != "song":
		song.animation_player.play("song")
		song.animation_player.seek(0)
		conductor.song_position = 0
	song.animation_player.pause()
	
	
	for note in note_group.get_children(): note.queue_free()
	for strum in Strumline.instances:
		strum.note_queues.clear()
	
	song.chart.sort()
	for note_data in song.chart.notes:
		add_note(note_data)

func _process(delta: float) -> void:
	if song.animation_player.is_playing():
		conductor.song_position = song.animation_player.current_animation_position
	
	if Input.is_action_just_pressed("editor_playback"):
		if song.animation_player.is_playing():
			song.animation_player.pause()
		else:
			resume()
	elif Input.is_action_just_pressed("ui_undo"):
		undo_redo.undo()
	elif Input.is_action_just_pressed("ui_redo"):
		undo_redo.redo()
	elif Input.is_action_just_pressed("ui_copy"):
		if !selected_notes.is_empty():
			var copy_data:Array[NoteData] = []
			for note:Note in selected_notes: copy_data.push_back(note.data.duplicate(true))
			copy_data.sort_custom(_sort_note_data)
			
			clipboard = ChartEditorClipboard.new(copy_data[0].time)
			clipboard.notes = copy_data
	elif Input.is_action_just_pressed("ui_cut"):
		if !selected_notes.is_empty():
			undo_redo.create_action("Cut Note(s)")
			
			var cut_data:Array[NoteData] = []
			for note:Note in selected_notes: cut_data.push_back(note.data)
			cut_data.sort_custom(_sort_note_data)
			
			clipboard = ChartEditorClipboard.new(cut_data[0].time)
			for n in cut_data:
				clipboard.notes.push_back(n)
			
			undo_redo.add_do_method(func():
				for note in selected_notes:
					erase_note(note)
			)
			undo_redo.add_undo_method(func():
				for data in cut_data:
					add_note(data)
			)
			
			undo_redo.commit_action()
	elif Input.is_action_just_pressed("ui_paste"):
		undo_redo.create_action("Paste Note(s)")
		
		var time = clipboard.time
		var notes = clipboard.notes
		
		var pasted_notes:Array[Note] = []
		undo_redo.add_do_method(func():
			for note in notes:
				note.time = note.time - time + conductor.song_position
				pasted_notes.push_back(add_note(note))
		)
		undo_redo.add_undo_method(func():
			for note in pasted_notes:
				erase_note(note)
		)
			
		undo_redo.commit_action()
	elif Input.is_action_just_pressed("ui_accept"):
		Discord.song()
		if !song.animation_player.is_playing():
			song.animation_player.play()
		if Input.is_action_pressed("editor_ctrl"):
			song.animation_player.seek(0)
		song.hud_layer.visible = true
		song.in_chart_editor = false
		DebugDisplay.label.visible = true
		self.queue_free()
	
	for note:Note in note_group.get_children():
		if selected_notes.has(note):
			note.modulate.a = 0.5
		else:
			note.modulate.a = 1
	
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
			if event.button_index == MOUSE_BUTTON_LEFT:
				if !Input.is_action_pressed("editor_shift"):
					selected_notes.clear()
				var filtered:Array = note_group.get_children().filter(func(n:Note): return n.editor_hitbox.get_rect().has_point(n.get_local_mouse_position()))
				if !filtered.is_empty():
					for note:Note in filtered:
						selected_notes.push_back(note)
			if event.button_index == MOUSE_BUTTON_RIGHT:
				selected_notes.clear()
				
				var filtered:Array = note_group.get_children().filter(func(n:Note): return n.editor_hitbox.get_rect().has_point(n.get_local_mouse_position()))
				if !filtered.is_empty():
					var removed_data:Array[NoteData] = []
					for note:Note in filtered: removed_data.push_back(note.data)
				
					undo_redo.create_action("Remove Note(s)")
					undo_redo.add_do_method(func():
						for note:Note in filtered:
							erase_note(note)
					)
					undo_redo.add_undo_method(func():
						for data in removed_data:
							add_note(data)
					)
					undo_redo.commit_action(true)
	if event is InputEventPanGesture: # trackpad gesture
		song.animation_player.pause()
		conductor.song_position -= event.delta.y/10
		if conductor.song_position < 0:
			conductor.song_position = 0
		seek_animation()

func add_note(data:NoteData) -> Note:
	var note:Note = load("res://core/gameplay/notes/note.tscn").instantiate()
	note.editor = true
	note.data = data
	note.scale = Vector2(0.3, 0.3)
	
	note_group.add_child(note)
	
	var target_grid:Control = %extra_grid
	match data.player:
		NoteData.PlayerType.OPPONENT:
			target_grid = %opponent_grid
			song.hud.opponent_strumline.note_queues.push_back(data)
		NoteData.PlayerType.PLAYER:
			target_grid = %player_grid
			song.hud.player_strumline.note_queues.push_back(data)
		
	note.global_position.x = target_grid.global_position.x + floor(target_grid.grid_size.x * data.column) + (target_grid.grid_size.x / 2)
	note.global_position.y = target_grid.position.y + (conductor.get_step_from_time(data.time) * target_grid.grid_size.y) + (target_grid.grid_size.y / 2)
	if !song.chart.notes.has(data):
		song.chart.notes.push_back(data)
	return note
	
func erase_note(note:Note) -> void:
	for strum in Strumline.instances:
		if strum.note_queues.has(note.data):
			strum.note_queues.erase(note.data)
	song.chart.notes.erase(note.data)
	note.queue_free()

func _sort_note(a: Note, b: Note) -> bool:
	if a.data.time < b.data.time:
		return true
	return false

func _sort_note_data(a: NoteData, b: NoteData) -> bool:
	if a.time < b.time:
		return true
	return false
