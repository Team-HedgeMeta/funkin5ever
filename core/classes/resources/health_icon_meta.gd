extends Resource
class_name HealthIconData

@export var texture:Texture2D = preload("res://core/gameplay/dummy_icon.png")
@export var scale:Vector2 = Vector2.ONE
@export var has_losing_icon:bool = true
@export var has_winning_icon:bool = false
@export var color:Color = Color("A1A1A1")
