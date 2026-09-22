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
@onready var ui:Control = %ui

@onready var grid_initial_y:float = %player_grid.global_position.y

func _ready() -> void:
	DebugDisplay.label.visible = false
	
	Discord.song()
	DiscordRPC.details = "Editing chart of: " + DiscordRPC.details
	DiscordRPC.start_timestamp = int(Time.get_unix_time_from_system())
	DiscordRPC.refresh()
	
	%save_dialogue.file_selected.connect(save)
	
	%bg.modulate.a = 0
	%grid.position.x += 500
	var tween:Tween = self.create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(%bg, "modulate:a", 0.25, 0.5)
	tween.tween_property(%grid, "position:x", 0, 0.5)
	
	song.in_chart_editor = true
	song.hud_layer.visible = false
	for strum in Strumline.instances:
			strum.note_queues.clear()
			for note in strum.note_group.get_children(): note.free()
			strum.note_queue_index = 0
	
	if is_instance_valid(song.countdown):
		song.countdown.cancel()
	if !song.animation_player.is_playing() or song.animation_player.current_animation != "song":
		song.animation_player.play("song")
		song.animation_player.seek(0)
		conductor.song_position = 0
	song.animation_player.pause()
	
	song.chart.sort()
	for note_data in song.chart.notes:
		add_note(note_data)
	
	if song.chart.bpm_changes.is_empty():
		var panel:ChartEditorBPMPanel = load("res://core/tools/chart_editor/components/bpm_panel.tscn").instantiate()
		panel.closable = false
		panel.editor = self
		panel.position = 0
		add_child(panel)
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
		copy_selected()
	elif Input.is_action_just_pressed("ui_cut"):
		cut_selected()
	elif Input.is_action_just_pressed("ui_paste"):
		paste()
	elif Input.is_action_just_pressed("ui_text_select_all"):
		select_all()
	elif Input.is_action_just_pressed("editor_save"):
		if Input.is_action_pressed("editor_shift"):
			save_as()
		else:
			save()
	elif Input.is_action_just_pressed("ui_accept"):
		exit()
	
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

	# Character Animation Preview
	var filtered_notes:Array[NoteData] = song.chart.notes.filter(func(n:NoteData) -> bool: return absf(n.time - Conductor.instance.song_position) < 0.01)
	if !filtered_notes.is_empty():
		for note in filtered_notes:
			if note.player == NoteData.PlayerType.PLAYER:
				for character in song.hud.player_strumline.characters:
					if character.has_animation(song.hud.player_strumline.skin.sing_animations[note.column]):
						character.play_anim(song.hud.player_strumline.skin.sing_animations[note.column], true)
			else:
				for character in song.hud.opponent_strumline.characters:
					if character.has_animation(song.hud.opponent_strumline.skin.sing_animations[note.column]):
						character.play_anim(song.hud.opponent_strumline.skin.sing_animations[note.column], true)
	
	var snap:int = 1
	%cursor.visible = (%extra_grid.position.x + (%extra_grid.columns * %extra_grid.grid_size.x) > ui.get_global_mouse_position().x) && (%opponent_grid.position.x < ui.get_global_mouse_position().x)
	%cursor.position.y = max(0, floor(%cursor.get_global_mouse_position().y / (%opponent_grid.grid_size.y / snap)) * (%opponent_grid.grid_size.y / snap))
	%cursor.position.x = get_grid(get_mouse_overlap_player()).position.x + get_mouse_lane() * get_grid(get_mouse_overlap_player()).grid_size.x
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
				if %cursor.visible:
					if !Input.is_action_pressed("editor_shift"):
						selected_notes.clear()
					var filtered:Array = note_group.get_children().filter(func(n:Note): return n.editor_hitbox.get_rect().has_point(n.get_local_mouse_position()))
					if !filtered.is_empty():
						for note:Note in filtered:
							selected_notes.push_back(note)
					else:
						selected_notes.clear()
						undo_redo.create_action("Place Note")
						
						var something:Array[Note] = [] # somehow we can't keep node
						undo_redo.add_do_method(func():
							var new_data:NoteData = NoteData.new()
							new_data.column = get_mouse_lane()
							new_data.time = conductor.get_time_from_step((%cursor.position.y - grid_initial_y) / %player_grid.grid_size.y)
							new_data.player = get_mouse_overlap_player()
							something.push_back(add_note(new_data))
							selected_notes.push_back(something[0])
						)
						undo_redo.add_undo_method(func():
							erase_note(something[0])
						)
						undo_redo.commit_action()
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
	
	var target_grid:Control = get_grid(data.player)
		
	note.global_position.x = target_grid.global_position.x + floor(target_grid.grid_size.x * data.column) + (target_grid.grid_size.x / 2)
	note.global_position.y = grid_initial_y + (conductor.get_step_from_time(data.time) * target_grid.grid_size.y) + (target_grid.grid_size.y / 2)
	if !song.chart.notes.has(data):
		song.chart.notes.push_back(data)
	return note
	
func erase_note(note:Note) -> void:
	song.chart.notes.erase(note.data)
	if selected_notes.has(note): selected_notes.erase(note)
	note.queue_free()

func _sort_note_data(a: NoteData, b: NoteData) -> bool:
	if a.time < b.time:
		return true
	return false

func add_bpm_change(change:BPMChange) -> void:
	song.chart.bpm_changes.push_back(change)
	song.chart.bpm_changes.sort_custom(_sort_bpm_change)
	conductor.set_bpm_changes(song.chart.bpm_changes)
	update_note_times()
	
func erase_bpm_change(note:Note) -> void:
	song.chart.notes.erase(note.data)
	if selected_notes.has(note): selected_notes.erase(note)
	note.queue_free()

func _sort_bpm_change(a: BPMChange, b: BPMChange) -> bool:
	if a.time < b.time:
		return true
	return false

func get_mouse_overlap_player() -> NoteData.PlayerType:
	if %opponent_grid.global_position.x < ui.get_global_mouse_position().x && ui.get_global_mouse_position().x < %opponent_grid.position.x + %opponent_grid.grid_size.x * %opponent_grid.columns:
		return NoteData.PlayerType.OPPONENT
	elif  %player_grid.global_position.x < ui.get_global_mouse_position().x && ui.get_global_mouse_position().x < %player_grid.position.x + %player_grid.grid_size.x * %player_grid.columns:
		return NoteData.PlayerType.PLAYER
	return NoteData.PlayerType.EXTRA

func get_grid(player:NoteData.PlayerType) -> ChartEditorGrid:
	match player:
		NoteData.PlayerType.OPPONENT:
			return %opponent_grid
		NoteData.PlayerType.PLAYER:
			return %player_grid
		_:
			return %extra_grid

func get_mouse_lane() -> int:
	return absi(floor((ui.get_global_mouse_position().x - %opponent_grid.global_position.x) / %opponent_grid.grid_size.x)) % 4

func exit() -> void:
	song.chart.sort()
	
	Discord.song()
	if !song.animation_player.is_playing():
		song.animation_player.play()
	if Input.is_action_pressed("editor_ctrl"):
		song.animation_player.seek(0)
	song.hud_layer.visible = true
	song.in_chart_editor = false
	DebugDisplay.label.visible = true
	song.load_notes()
	self.queue_free()
	
func copy_selected() -> void:
	if !selected_notes.is_empty():
		var copy_data:Array[NoteData] = []
		for note:Note in selected_notes: copy_data.push_back(note.data)
		copy_data.sort_custom(_sort_note_data)
		
		clipboard = ChartEditorClipboard.new(copy_data[0].time)
		clipboard.notes = copy_data

func cut_selected() -> void:
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

func paste() -> void:
	if clipboard != null:
		undo_redo.create_action("Paste Note(s)")
		
		var time = clipboard.time
		var notes = clipboard.notes
		
		selected_notes.clear()
		
		var pasted_notes:Array[Note] = []
		undo_redo.add_do_method(func():
			for note in notes:
				var new_data:NoteData = note.duplicate(true)
				new_data.time = note.time - time + conductor.get_time_from_step((%cursor.position.y - grid_initial_y) / %player_grid.grid_size.y)
				new_data.player = get_mouse_overlap_player()
				var n:Note = add_note(new_data)
				pasted_notes.push_back(n)
				selected_notes.push_back(n)
		)
		undo_redo.add_undo_method(func():
			for note in pasted_notes:
				erase_note(note)
		)
		
		undo_redo.commit_action()

func select_all() -> void:
	selected_notes.clear()
	for note in note_group.get_children():
		selected_notes.push_back(note)

func save(dir:String = "") -> void:
	var target:String = dir
	if target.is_empty():
		var folder:String = ContentManager.get_content_path("gameplay/songs/" + song.meta._song_id)
		print(folder)
		if DirAccess.dir_exists_absolute(folder):
			target = folder.path_join("charts/" + song.chart._difficulty + ".json")
		else:
			save_as()
			return
	
	var file:FileAccess = FileAccess.open(target, FileAccess.WRITE)
	file.store_string(Funkin5everChart.export_string(song.chart))
	file.close()

func save_as() -> void:
	%save_dialogue.visible = true

func update_note_times() -> void:
	for note:Note in note_group.get_children():
		note.data.time = conductor.get_time_from_step((note.global_position.y - grid_initial_y) / %player_grid.grid_size.y)
