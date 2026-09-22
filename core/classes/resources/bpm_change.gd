extends Resource
class_name BPMChange

@export_custom(PROPERTY_HINT_NONE, "suffix:s") var time:float = 0
@export_custom(PROPERTY_HINT_NONE, "suffix:BPM") var bpm:float = 100
@export var denominator:float = 4
@export var numerator:float = 4

func _init(_time:float = 0, _bpm:float = 100, _denominator:float = 4, _numerator:float = 4) -> void:
	self.time = _time
	self.bpm = _bpm
	self.denominator = _denominator
	self.numerator = _numerator
