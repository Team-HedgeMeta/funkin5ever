extends CanvasLayer
class_name ChartEditorBPMPanel

@onready var bpm_input:LineEdit = %bpm_input
@onready var denominator_input:LineEdit = %denominator_input
@onready var numerator_input:LineEdit = %numerator_input
@onready var add_button:Button = %add_button

var closable:bool = true

var editor:ChartEditor
var position:float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_tree().paused = true
	add_button.pressed.connect(add)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel") && closable:
		self.queue_free()
		get_tree().paused = false

func add() -> void:
	var bpm_change:BPMChange = BPMChange.new(position, float(bpm_input.text), int(denominator_input.text), int(numerator_input.text))
	editor.add_bpm_change(bpm_change)
	self.queue_free()
	get_tree().paused = false
