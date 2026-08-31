class_name PauseMenu extends Control

@onready var line_edit: LineEdit = $LineEdit
@onready var item_list: ItemList = $ItemList
@onready var save_button: Button = $Save
@onready var load_button: Button = $Load

var list_game: Array[String] = []

func show_menu() -> void:
	visible = true
	line_edit.text = Time.get_date_string_from_system() + "_" + Time.get_time_string_from_system()
	if visible:
		find_games()

func load_save(name_save: String) -> void:
	load_button.text = "Cargar"
	if Vault.load_from_disk(name_save):
		print("CARGADO CORRECTAMENTE")
	else:
		printerr("ERROR AL CARGAR")

	load_button.remove_meta("avisado")
	load_button.text = "Cargar"

func save_game(name_game: String) -> void:
	# Le pasamos "true" al final asumiendo que tu _save_in_disk pide confirmación
	save_button.text = "Guardar"
	if Vault._save_in_disk(name_game, true): 
		print("GUARDADO CORRECTAMENTE")
		find_games() # Refrescar la lista de guardados tras guardar con éxito
	else:
		printerr("ERROR AL GUARDAR")

	save_button.remove_meta("avisado")
	save_button.text = "Guardar"

func _show_warning(button: Button) -> void:
	button.set_meta("avisado", true)
	button.text = "CONFIRMAR"

func find_games(path: String = "user://") -> void:
	list_game.clear() # Evita duplicar elementos si se llama varias veces
	item_list.clear() # Limpia también el nodo UI
	
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var filename = dir.get_next()

		while filename != "":
			if not dir.current_is_dir() and filename.ends_with(Storage.EXTENSION):
				list_game.append(filename)
				item_list.add_item(filename) # Agregar a la interfaz
			filename = dir.get_next()

	print("Cargados guardados: ", list_game.size())

func _on_save_pressed() -> void:
	load_button.remove_meta("avisado")

	if line_edit.text.strip_edges() == "":
		print("Ingrese un nombre válido")
		return

	var name_game = line_edit.text + Storage.EXTENSION

	# Si el archivo existe y el botón aún no tiene la meta "avisado"
	if FileAccess.file_exists("user://" + name_game) and not save_button.has_meta("avisado"):
		_show_warning(save_button)
		return # Cortamos la ejecución aquí, esperando un segundo clic

	# Si el archivo NO existe, o SI ya dimos el aviso, se guarda:
	save_game(name_game)

func _on_load_pressed() -> void:
	save_button.remove_meta("avisado")

	var selected_items = item_list.get_selected_items()
	if selected_items.is_empty():
		print("Seleccione un archivo de la lista")
		return

	var name_game = item_list.get_item_text(selected_items[0])
	
	if not load_button.has_meta("avisado"):
		_show_warning(load_button)
		return # Esperamos segundo clic

	load_save(name_game)

func _on_exit_pressed() -> void:
	visible = false
