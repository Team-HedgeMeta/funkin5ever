extends AnimatedSprite2D
class_name Note

enum NoteState
{
	NEUTRAL,
	HOLDING,
	HITTABLE,
	HIT,
	MISSED
}

const safe_zone = 0.18

var strumline:Strumline
var data:NoteData:
	set(value):
		data = value
		reload_data()
var skin:NoteSkin

var editor:bool = false

var state:NoteState = NoteState.NEUTRAL

var sing_animations:Array[String] = []

@onready var clip_rect:ColorRect = %clip_rect
@onready var sustain:TextureRect = %sustain
@onready var tail:Sprite2D = %tail

func reload_data():
	self.self_modulate = Color.WHITE
	self.state = NoteState.NEUTRAL
	
	var skin_path:String = ContentManager.get_content_path("gameplay/notes/" + data.type + "/skin.tres")
	if FileAccess.file_exists(skin_path):
		skin = load(skin_path)
	else:
		if is_instance_valid(strumline):
			skin = strumline.skin
		else:
			skin = load("res://core/gameplay/notes/default/skin.tres")
	
	self.sprite_frames = skin.note_frames
	self.play(skin.note_animations[data.column])
	self.sing_animations = skin.sing_animations.duplicate()
	match data.column:
		0:
			%sustain.texture = skin.sustain_frame_left
			%tail.texture = skin.sustain_frame_left_end
		1:
			%sustain.texture = skin.sustain_frame_down
			%tail.texture = skin.sustain_frame_down_end
		2:
			%sustain.texture = skin.sustain_frame_up
			%tail.texture = skin.sustain_frame_up_end
		3:
			%sustain.texture = skin.sustain_frame_right
			%tail.texture = skin.sustain_frame_right_end
	
	if is_instance_valid(strumline) && strumline.down_scroll:
		%clip_rect.rotation = deg_to_rad(180)
	else:
		%clip_rect.rotation = 0

func _process(delta: float) -> void:
	if data.length > 0:
		%sustain.visible = true
		%tail.visible = true
		if !editor && is_instance_valid(strumline):
			%clip_rect.global_position.y = strumline.strums[data.column].global_position.y
			%sustain.global_position.y = self.global_position.y
			%sustain.scale.y = (data.length / Conductor.instance.get_step_crotchet(data.time)) * (strumline.scroll_speed*0.45)
		else:
			%sustain.scale.y = (data.length / Conductor.instance.get_step_crotchet(data.time))
		%tail.position.y = %sustain.position.y + (87 * %sustain.scale.y)
	else:
		%sustain.visible = false
		%tail.visible = false
	
	if state == NoteState.HIT || state == NoteState.MISSED || state == NoteState.HOLDING:
		return
	if  abs(data.time - Conductor.instance.song_position) <= safe_zone:
		state = NoteState.HITTABLE
	elif Conductor.instance.song_position - data.time > safe_zone:
		state = NoteState.MISSED
