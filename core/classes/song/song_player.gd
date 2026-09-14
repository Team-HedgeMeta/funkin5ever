@tool

extends AudioStreamPlayer
class_name SongStreamPlayer

var animation_player:AnimationPlayer

func _ready() -> void:
	set_process_internal(true)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PARENTED:
			if animation_player != null:
				animation_player = null
			
			var parent: Node = get_parent()
			if parent is AnimationPlayer:
				animation_player = parent

var prev_playing:bool = false

func _process(_delta: float) -> void:
	if !is_instance_valid(animation_player): return
	
	if animation_player.is_playing() != prev_playing:
		self.playing = (animation_player.is_playing() && animation_player.current_animation == "song")
		prev_playing = self.playing
	
	if self.playing:
		if abs((get_playback_position() + AudioServer.get_time_since_last_mix()) - animation_player.current_animation_position) > 0.02:
			self.seek(animation_player.current_animation_position)
