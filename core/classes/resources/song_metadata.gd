@tool
extends Resource
class_name SongMetadata

@export var display_name:String = ""
@export var artist:String = ""
@export var charter:String = ""
@export var difficulties:Array[String] = ["normal"]
@export var freeplay_icon:HealthIconData = HealthIconData.new()
@export_category("Extra")
@export var extra_data:Dictionary[String, Variant] = {}

var _song_id:String:
	get:
		return self.resource_path.get_base_dir().get_file()

func get_scene() -> PackedScene:
	var scene_path = self.resource_path.get_base_dir().path_join("song.tscn")
	if ResourceLoader.exists(scene_path):
		return load(scene_path)
	return null

func get_chart(difficulty:String = "normal") -> Chart:
	var charts_path = self.resource_path.get_base_dir().path_join("charts/")
	
	var result:Chart
	
	for format in Chart.CHART_FORMATS:
		var format_instance:BasicChart = format.new()
		if format_instance.check_format(charts_path, difficulty):
			result = format_instance.get_chart(charts_path, difficulty)
	
	if result == null: result = Chart.new()
	
	result.notes.sort_custom(func(a: NoteData, b: NoteData) -> bool:
		if a.time < b.time:
			return true
		return false
	)
	result._song_id = self._song_id
	result._difficulty = difficulty
	
	return result
