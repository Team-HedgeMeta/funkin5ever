# REWRITING ENTIRE INPUT???? CRAZY
extends Resource
class_name Keybinds

@export var ui_accept:int = KEY_ENTER
@export var ui_cancel:int = KEY_ESCAPE
@export var ui_left:int = KEY_LEFT
@export var ui_down:int = KEY_DOWN
@export var ui_up:int = KEY_UP
@export var ui_right:int = KEY_RIGHT
@export var ui_mod_manager:int = KEY_TAB

@export var note_left:int = KEY_LEFT
@export var note_down:int = KEY_DOWN
@export var note_up:int = KEY_UP
@export var note_right:int = KEY_RIGHT

@export var volume_up:int = KEY_PLUS
@export var volume_down:int = KEY_MINUS

@export var debug_kill:int = KEY_R
@export var debug_switch:int = KEY_F3

@export var extra_actions:Dictionary[String, int] = {}

func reload_binds() -> void:
	for action in get_property_list():
		if action.type == TYPE_INT && action.hint_string.is_empty():
			var event = InputEventKey.new()
			event.keycode = self.get(action.name)
			InputMap.action_erase_events(action.name)
			InputMap.action_add_event(action.name, event)
	for action in extra_actions:
		register_extra_action(action, extra_actions.get(action))

func register_extra_action(name:String, keycode:int) -> void:
	if InputMap.has_action(name): return
	
	var event = InputEventKey.new()
	event.keycode = keycode
	InputMap.add_action(name)
	InputMap.action_add_event(name, event)
	
	extra_actions.set(name, keycode)
