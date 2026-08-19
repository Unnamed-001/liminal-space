extends Control
class_name StatusManager

@onready var main_game: MainGame = $".."
@onready var character = $CHARACTER
@onready var lifeBar: TextureProgressBar = $BARS/LIFE
@onready var cordBar: TextureProgressBar = $BARS/CORD
@onready var hungerBar: TextureProgressBar = $BARS/HUNGER
@onready var thirstBar: TextureProgressBar = $BARS/THIRST

func _show_stats() -> void: ## Muestra las estadísticas del jugador
	var statsLabel = $stats as RichTextLabel
	statsLabel.visible = !statsLabel.visible

	if statsLabel.visible:
		# Atenuar el fondo
		character.modulate.a = 0.2
		lifeBar.modulate.a = 0.2
		cordBar.modulate.a = 0.2
		# Rearma el Json para lectura y lo muestra en el RichTextLabel
		var formatted_text = "Estadísticas Actuales:\n\n"

		for stat_key in GameMaster.stats:
			var stat_value = GameMaster.stats[stat_key]
			# .capitalize() convierte "velocity" en "Velocity" automáticamente
			formatted_text += "- " + stat_key.capitalize() + ": " + str(stat_value) + "\n"

		statsLabel.text = formatted_text

	else:
		# Restaurar la opacidad al cerrar
		character.modulate.a = 1.0
		lifeBar.modulate.a = 1.0
		cordBar.modulate.a = 1.0

func _show_inventory() -> void: ## Muestra el inventario del jugador
	var stage = get_parent().get_node("translator") as MainTranslator
	var inventory_stage: StageDB = load("res://Recursos/Escenarios/Inventario.tres").duplicate()
	var lang: String = GameMaster.config["lang"].to_lower()
	
	# Guardamos el encabezado o texto base inicial del escenario
	var base_desc_es: String = inventory_stage.escenario_es_cl[1]
	var base_desc_en: String = inventory_stage.escenario_en_us[1]
	
	var items_text_es: String = ""
	var items_text_en: String = ""
	
	var count: int = 1
	for item in GameMaster.inventory:
		var item_name: String = item.name.get(GameMaster.config["lang"], "Item")

		# Agregamos la opción/ítem a la lista de texto con salto de línea
		items_text_es += "\n• " + item.name.get("es_cl", item_name)
		items_text_en += "\n• " + item.name.get("en_us", item_name)

		# Creamos el botón/opción interactivo para ese ítem
		var action: OptionDB = OptionDB.new()
		action.name[GameMaster.config["lang"]] = item_name
		action.id = count
		action.result = OptionDB.OptionResult.EVENT_TRIGGER
		action.target_event = "WIP"

		inventory_stage.actions.append(action)
		count += 1

	# Asignamos el texto final (Encabezado + Lista de opciones generada)
	inventory_stage.escenario_es_cl[1] = base_desc_es + items_text_es
	inventory_stage.escenario_en_us[1] = base_desc_en + items_text_en

	inventory_stage.id_zone = main_game.current_stage.id_zone
	inventory_stage.special_event = main_game.current_stage.special_event

	stage.update_stage(inventory_stage)

func _save() -> void:
	pass

func _quit() -> void:
	pass
