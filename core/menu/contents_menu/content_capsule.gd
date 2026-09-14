extends Button

@export var content:ContentMetadata

func setup(_content:ContentMetadata) -> void:
	self.content = _content
	self.text = content.name if !content.name.is_empty() else content.id
	self.button_pressed = content.enabled
	$checkbox.toggle(content.enabled)

func _on_toggled(toggled_on: bool) -> void:
	$checkbox.toggle(toggled_on)
	content.enabled = toggled_on
