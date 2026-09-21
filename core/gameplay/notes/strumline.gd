@tool
extends Control
class_name Strumline

enum MissType
{
	NOTE_MISS,
	GHOST_TAP,
	HOLD_DROP
}

static var instances:Array[Strumline] = []

@export var skin:NoteSkin = preload("res://core/gameplay/notes/default/skin.tres"):
	set(value):
		skin = value
		reload_skin()
@export var botplay:bool = true
@export var play_note_splashes:bool = false

@export var characters:Array[Node] = []

@onready var strums:Array[Node2D] = [%left, %down, %up, %right]
@onready var note_group:Node2D = %notes

var down_scroll:bool = false

var inputs:Array[String] = ["note_left", "note_down", "note_up", "note_right"]
var note_queues:Array[NoteData] = []
var note_queue_index:int = 0
var scroll_speed:float = 1

var note_pool = ScenePool.new(load("res://core/gameplay/notes/note.tscn"))
var splash_pool = ScenePool.new(load("res://core/gameplay/notes/note_splash.tscn"))

signal note_spawned(note: Note)
signal note_hit(note:Note, is_sustain_part:bool)
signal note_miss(note:Note, type:MissType)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	reload_skin()
	
	note_hit.connect(_note_hit)
	note_miss.connect(_note_miss)
	
	instances.push_back(self)

func reload_skin() -> void:
	%notes.scale = Vector2(skin.scale, skin.scale)
	var idx:int = 0
	for strum in strums:
		strum.sprite_frames = skin.strum_frames
		strum.scale = Vector2(skin.scale, skin.scale)
		strum.play(skin.strum_static_animations[idx])
		idx += 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if !Song.current.in_chart_editor:
		if note_queues.size() > note_queue_index:
			var queue:NoteData = note_queues[note_queue_index]
			if queue.time - 3 <= Conductor.instance.song_position:
				if Conductor.instance.song_position > queue.time + queue.length + 0.1: # it gone too far
					note_queue_index += 1
				else:
					var note = note_pool.get_object()
					note.strumline = self
					note.data = queue
					%notes.add_child(note)
					note_queue_index += 1
					note_spawned.emit(note)
		
		for note in %notes.get_children():
			note.global_position.x = strums[note.data.column].global_position.x
			var offset:float = (Conductor.instance.song_position - note.data.time) * (scroll_speed * 450)
			if down_scroll:
				offset *= -1
			note.global_position.y = strums[note.data.column].global_position.y - offset
			if botplay && note.data.time <= Conductor.instance.song_position && note.state == Note.NoteState.HITTABLE:
				note_hit.emit(note, false)
			
			if note.state == Note.NoteState.HOLDING:
				if botplay or Input.is_action_pressed(inputs[note.data.column]):
					note_hit.emit(note, true)
				else:
					note_miss.emit(note, MissType.HOLD_DROP)
			
			if note.state == Note.NoteState.MISSED:
				note_miss.emit(note, MissType.NOTE_MISS)
		
		for i in strums.size():
			var strum = strums[i]
			
			if !botplay:
				if Input.is_action_just_pressed(inputs[i]):
					var filtered = %notes.get_children().filter(func(n): return n.state == Note.NoteState.HITTABLE and n.data.column == i)
					if filtered.size() > 0:
						note_hit.emit(filtered[0], false)
					else:
						strum.play(skin.strum_press_animations[i])
				
				if !botplay && !Input.is_action_pressed(inputs[i]):
					strum.play(skin.strum_static_animations[i])
			elif !strum.is_playing():
				strum.play(skin.strum_static_animations[i])

func _note_hit(note:Note, is_sustain_part:bool) -> void:
	strums[note.data.column].play(skin.strum_confirm_animations[note.data.column])
	
	for character in characters:
		if character.has_animation(note.sing_animations[note.data.column]):
			character.play_anim(note.sing_animations[note.data.column], !is_sustain_part if !character.sustain_nimble else true)
	
	if note.state == Note.NoteState.HITTABLE:
		if note.data.length > 0:
			note.clip_rect.clip_contents = true
			note.self_modulate = Color.TRANSPARENT
			note.state = Note.NoteState.HOLDING
		else:
			note.state = Note.NoteState.HIT
			note_pool.add_to_pool(note)
		
		if play_note_splashes:
			var splash = splash_pool.get_object()
			%splashes.add_child(splash)
			splash.global_position = strums[note.data.column].global_position
			splash.play_splash(note.data, skin)
			splash.tween.finished.connect(func(): splash_pool.add_to_pool(splash))
	elif note.state == Note.NoteState.HOLDING:
		if note.data.time + note.data.length <= Conductor.instance.song_position:
			note_pool.add_to_pool(note)
		elif !botplay && !Input.is_action_pressed(inputs[note.data.column]):
			note_miss.emit(note)
			return

func _note_miss(note:Note, type:MissType) -> void:
	for character in characters:
		if character.has_animation(note.sing_animations[note.data.column] + "_miss"):
			character.play_anim(note.sing_animations[note.data.column] + "_miss", true)
	note_pool.add_to_pool(note)

func _exit_tree() -> void:
	instances.erase(self)

func sort_queue() -> void:
	note_queues.sort_custom(func(a: NoteData, b: NoteData) -> bool:
		if a.time < b.time:
			return true
		return false
	)
