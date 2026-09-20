extends Control
class_name Countdown

@onready var sprite:Sprite2D = %sprite
@onready var sound:AudioStreamPlayer = %sound

var skin:CountdownSkin

var current_step:int = 0
var countdown_timer:Timer

signal countdown_step(step:int)
signal countdown_finished

func _ready() -> void:
	sprite.visible = false

func start() -> void:
	countdown_timer = Timer.new()
	add_child(countdown_timer)
	
	countdown_timer.timeout.connect(func():
		match current_step:
			0: # three
				sprite.visible = (skin.on_your_mark_texture != null)
				sprite.texture = skin.on_your_mark_texture
				sound.stream = skin.on_your_mark_sound
				sound.play()
			1: # two
				sprite.visible = (skin.ready_texture != null)
				sprite.texture = skin.ready_texture
				sound.stream = skin.ready_sound
				sound.play()
			2: #one
				sprite.visible = (skin.set_texture != null)
				sprite.texture = skin.set_texture
				sound.stream = skin.set_sound
				sound.play()
			3: #go
				sprite.visible = (skin.go_texture != null)
				sprite.texture = skin.go_texture
				sound.stream = skin.go_sound
				sound.play()
			4:
				countdown_timer.stop()
				countdown_timer.queue_free()
				countdown_finished.emit()
				self.visible = false
		if sprite.visible:
			sprite.scale = Vector2(skin.scale + 0.03, skin.scale + 0.03)
			var tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tween.tween_property(sprite, "scale", Vector2(skin.scale, skin.scale), Conductor.instance.get_crotchet() * 0.5)
		if current_step != 4:
			countdown_step.emit(current_step)
			current_step += 1
	)
	
	countdown_timer.start(Conductor.instance.get_crotchet())

func cancel() -> void:
	if current_step == 4: return
	countdown_timer.cancel_free()
	sound.stop()
	sprite.visible = false
	self.queue_free()
