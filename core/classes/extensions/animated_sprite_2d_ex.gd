@tool
extends AnimatedSprite2D
class_name AnimatedSprite2DEx

@export var playing: bool = false:
	set(value):
		if value:
			self.frame = 0
			play()
		else:
			pause()
	get:
		return is_playing()
