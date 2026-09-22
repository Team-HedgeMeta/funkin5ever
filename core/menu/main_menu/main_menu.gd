extends Node2D

static var current_item:int = 0
var controllable:bool = true
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%info_label.text = "funkin5ever v" + ProjectSettings.get("application/config/version")
	%info_label.text += "\nPress %s to open Content Manager" % OS.get_keycode_string(Config.data.keybinds.ui_mod_manager).to_upper()
	
	if !GlobalSound.music_player.playing:
		GlobalSound.play_music(load("res://core/menu/music.ogg"))
	
	var init:Callable = func():
		%camera.limit_top = %container.get_child(0).global_position.y - 100
		%camera.limit_bottom = %container.get_child(%container.get_child_count() - 1).global_position.y + 200
		change_item(0)
	
	init.call_deferred()

func change_item(change:int = 0) -> void:
	current_item = wrap(current_item + change, 0, %container.get_child_count())
	%camera.global_position.y = %container.get_child(current_item).global_position.y
	GlobalSound.play_sfx(preload("res://core/menu/scroll.ogg"))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_up") && controllable:
		change_item(-1)
	elif Input.is_action_just_pressed("ui_down") && controllable:
		change_item(1)
	if Input.is_action_just_pressed("ui_cancel") && controllable:
		controllable = false
		GlobalSound.play_sfx(preload("res://core/menu/cancel.ogg"))
		Transition.switch_scene(load("res://core/menu/title/title.tscn"))
	elif Input.is_action_just_pressed("ui_accept") && controllable:
		controllable = false
		GlobalSound.play_sfx(preload("res://core/menu/confirm.ogg"))
		
		var tween:Tween = get_tree().create_tween().set_parallel(true)
		for item in %container.get_children():
			if item.get_index() != current_item:
				tween.tween_property(item, "modulate:a", 0, 0.2)
		await get_tree().create_timer(0.5).timeout
		match %container.get_child(current_item).name:
			"story":
				pass
			"freeplay":
				Transition.switch_scene(load("res://core/menu/freeplay/freeplay.tscn"))
			"credits":
				Transition.switch_scene(load("res://core/menu/freeplay/freeplay.tscn"))
			"options":
				MainConfigMenu.return_scene = self.scene_file_path
				Transition.switch_scene(load("res://core/menu/config_menu/main_config.tscn"))
			
	elif Input.is_action_just_pressed("ui_mod_manager") && controllable:
		controllable = false
		Transition.switch_scene(load("res://core/menu/contents_menu/contents_menu.tscn"))
	
	for item in %container.get_children():
		item.selected = item.get_index() == current_item
