extends Sprite2D
class_name HealthIcon

@export var data:HealthIconData:
	set(value):
		data = value
		reload_icon()

@export var player:bool = false

@export var do_bop:bool = true
@export var bop_beat:int = 2

var tween:Tween

signal data_changed

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	reload_icon()
	
	if Conductor.instance != null:
		Conductor.instance.beat_hit.connect(_beat_hit)

func reload_icon() -> void:
	if data == null: data = HealthIconData.new()
	
	self.texture = data.texture
	
	if data.has_winning_icon:
		self.hframes = 3
	elif data.has_losing_icon:
		self.hframes = 2
	else:
		self.hframes = 1

func _beat_hit(beat:int) -> void:
	if beat % bop_beat == 0:
		if tween != null: tween.kill()
		tween = get_tree().create_tween().set_parallel(true).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
		self.scale = data.scale * 1.14
		tween.tween_property(self, "scale", data.scale, Conductor.instance.get_crotchet())

func _process(_delta: float) -> void:
	if Song.current != null:
		var health:float = Song.current.stats.health
		if player:
			self.frame = 1 if health < 0.4 && data.has_losing_icon else (2 if health > 1.6 && data.has_winning_icon else 0)
		else:
			self.frame = 1 if health > 1.6 && data.has_losing_icon else (2 if health < 0.4 && data.has_winning_icon else 0)
