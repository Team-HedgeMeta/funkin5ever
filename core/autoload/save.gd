extends Node

const ENCRYPTION_KEY:String = "386a0fc4200f892ae12c4a5fe951a158"

var scores:Dictionary[String, GameStats] = {}

func _init() -> void:
	load_save()

func load_save() -> void:
	if FileAccess.file_exists("user://scores"):
		var f = FileAccess.open_encrypted_with_pass("user://scores", FileAccess.READ, ENCRYPTION_KEY)
		scores = str_to_var(f.get_as_text())
		f.close()

func save() -> void:
	var f = FileAccess.open_encrypted_with_pass("user://scores", FileAccess.WRITE, ENCRYPTION_KEY)
	f.store_string(var_to_str(scores))
	f.close()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save()
