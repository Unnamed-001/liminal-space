class_name PauseMenu extends Control

@onready var line_edit: LineEdit = $LineEdit
@onready var item_list: ItemList = $ItemList
@onready var save_button: Button = $Save
@onready var load_button: Button = $Load

var warned: bool = false
var active: bool = true
var list_game: Array

func _ready() -> void:
	find_games()

func show_menu() -> void:
	if visible:
		find_games()
	visible = !visible

func load_save(option: int, name_save: String) -> void:
	if active: 
		warned = false
		_show_warning(load_button)
		return
	if Vault.load_from_disk(name_save):
		print("CARGADO CORRECTAMENTE")
	else:
		printerr("ERROR AL CARGAR")

	active = true

func save_game(name_game: String) -> void:
	if active:
		warned = false
	if FileAccess.file_exists("user://" + name_game) and !warned:
		_show_warning(save_button)
		return

	if Vault._save_in_disk(name_game):
		print("GUARDADO CORRECTAMENTE")
	else:
		printerr("ERROR AL GUARDAR")

	save_button.text = "guardar"
	active = true

func _show_warning(button: Button) -> void:
	active = false
	warned = true
	button.text = "CONFIRMAR"

func find_games(path: String = "user://"):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var filename = dir.get_next()
		while filename != "":
			print(filename)
			if not dir.current_is_dir() and filename.ends_with(".json"):
				list_game.append(filename)
			filename = dir.get_next()

	print("Cargados guardados: ", list_game.size())
