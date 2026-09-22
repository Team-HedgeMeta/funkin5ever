extends Panel

@export var editor:ChartEditor

@onready var file_menu:MenuButton = %file
@onready var edit_menu:MenuButton = %edit
@onready var view_menu:MenuButton = %view
@onready var snap_menu:MenuButton = %view

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	file_menu.get_popup().index_pressed.connect(_file_menu_callback)
	edit_menu.get_popup().index_pressed.connect(_edit_menu_callback)
	view_menu.get_popup().index_pressed.connect(_view_menu_callback)
	snap_menu.get_popup().index_pressed.connect(_snap_menu_callback)


func _file_menu_callback(index:int) -> void:
	match index:
		0: # Save Song
			editor.save()
		1: # Save Song As...
			editor.save_as()
		2: # Exit
			editor.exit()

func _edit_menu_callback(index:int) -> void:
	match index:
		0: # Undo
			editor.undo_redo.undo()
		1: # Redo
			editor.undo_redo.redo()
		2: # Separator
			pass
		3: # Cut
			editor.cut_selected()
		4: # Copy
			editor.copy_selected()
		5: # Paste
			editor.paste()
		6: # Separator
			pass
		7: # Select All
			editor.select_all()

func _view_menu_callback(index:int) -> void:
	print(index)

func _snap_menu_callback(index:int) -> void:
	print(index)
