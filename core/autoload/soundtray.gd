extends CanvasLayer

@export var animation_player:AnimationPlayer
@export var bars:TextureRect

var volume:int = 10:
	set(value):
		if value > 10:
			value = 10
		elif value < 0:
			value = 0
		volume = value
		AudioServer.set_bus_volume_db(0, remap(volume, 0, 10, -80, 0))

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	volume = Config.get_config("volume")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var prev_volume:int = volume
	if Input.is_action_just_pressed("volume_up"):
		volume += 1
	elif Input.is_action_just_pressed("volume_down"):
		volume -= 1
	
	if prev_volume != volume:
		bars.texture = load("res://core/menu/soundtray/bars_%s.png" % str(volume))
		if !animation_player.is_playing():
			animation_player.play("in")
		elif animation_player.current_animation == "in" && animation_player.current_animation_position > 0.51:
			animation_player.seek(0.51)
		animation_player.animation_finished.connect(func(anim):
			match anim:
				"in":
					animation_player.play("out")
		)
		if prev_volume > volume:
			GlobalSound.play_sfx(preload("res://core/menu/soundtray/volume_down.ogg"))
		else:
			if volume == 10:
				GlobalSound.play_sfx(preload("res://core/menu/soundtray/volume_max.ogg"))
			else:
				GlobalSound.play_sfx(preload("res://core/menu/soundtray/volume_up.ogg"))
		Config.set_config("volume", volume)
