extends Resource
class_name ConfigData

const DEFAULT_CONFIG_VERSION:int = 0

enum ShaderOption
{
	ALL,
	MINIMAL,
	DISABLED
}

@export var version:int = DEFAULT_CONFIG_VERSION

# config Variables
@export var down_scroll:bool = false
@export var middle_scroll:bool = false
@export var keybinds:Keybinds = Keybinds.new()

@export var volume:int = 10

@export var antialiasing:bool = true:
	set(value):
		antialiasing = value
		Global.root.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR if antialiasing else Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
@export var shaders:ShaderOption = ShaderOption.ALL
var _shaders_config:String = "all"

@export var content_list:Array[Dictionary] = []

@export var extra_config:Dictionary[String, Variant] = {}

func migrate() -> void:
	match self.version:
		_:
			pass
	
	self.version = DEFAULT_CONFIG_VERSION
	
func _on_load() -> void:
	match shaders:
		ShaderOption.MINIMAL:
			_shaders_config = "MINIMAL"
		ShaderOption.DISABLED:
			_shaders_config = "DISABLED"
		_:
			_shaders_config = "ALL"
	keybinds.reload_binds()

func _on_save() -> void:
	content_list = ContentManager.create_list_save()
	match _shaders_config:
		"MINIMAL":
			shaders = ShaderOption.MINIMAL
		"DISABLED":
			shaders = ShaderOption.DISABLED
		_:
			shaders = ShaderOption.ALL
