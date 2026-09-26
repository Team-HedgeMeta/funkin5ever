@tool
extends SubViewportContainer
class_name WorldProjector

@export var world_scene:PackedScene:
	set(value):
		world_scene = value
		reload_world()

var world:World
var sub_viewport:SubViewport

func _init() -> void:
	if !Engine.is_editor_hint():
		setup()

func _ready() -> void:
	if Engine.is_editor_hint():
		setup()

func setup() -> void:
	var window_size:Vector2 = Vector2(float(ProjectSettings.get_setting("display/window/size/viewport_width")), float(ProjectSettings.get_setting("display/window/size/viewport_height")))
	self.size = window_size
	self.set_anchors_preset(Control.PRESET_FULL_RECT)
	if sub_viewport == null:
		sub_viewport = SubViewport.new()
		sub_viewport.size = window_size
		sub_viewport.own_world_3d = true
		#sub_viewport.transparent_bg = true
		add_child(sub_viewport)
	reload_world()
	

func reload_world() -> void:
	if is_instance_valid(world): world.queue_free()
	if !is_instance_valid(world_scene): return
	world = world_scene.instantiate() as World
	sub_viewport.add_child(world)
