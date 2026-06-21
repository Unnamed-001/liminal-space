extends Control
class_name main_game
const max_turns: int = 5

@onready var cRect = $ColorRect
@onready var grid = $buttons/GridContainer
@onready var info = $Info
@onready var status = $Status
@onready var richLabel = $stage

var enemies: Array[MonsterDB] = []
var current_enemy: MonsterDB
var active_ids: Array[int] = []
var current_stage: StageDB = load("res://Recursos/Escenarios/start.tres")
var in_the_zone: int = 0
var turn: int = 0

var flag_combat: bool = false

func _ready() -> void:
	#region --Animacion de inicio--
	cRect.visible = true
	cRect.color = Color.WHITE
	var tween = create_tween()
	tween.tween_property(cRect, "color", Color(0.294, 0.294, 0.294, 0.0), 1.0).set_ease(Tween.EASE_IN)
	#endregion
	#region --Signal connection--
	GameMaster.connect("ai_response", Callable(self, "Generated_stage_AI"))
	GameMaster.player_action.connect(Callable(self, "update_status"))
	update_stage(current_stage)
	_prepare_buttons()
	update_status()
	#endregion

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		combat()

#region --Output Func--

func _prepare_buttons():
	for btn in grid.get_children():
		var my_id = btn.get_meta("id")
		# print(str(my_id))
		if not btn.pressed.is_connected(pressed_button):
			btn.pressed.connect(pressed_button.bind(my_id))

func pressed_button(id: int) -> void:
	if not active_ids.has(id):
		print("llamada bloqueada.")
		return

	if current_stage.connected_with.has(id):
		var next_route = current_stage.connected_with[id] as StageDB
		if current_stage.id_zone == next_route.id_zone:
			in_the_zone += 1
		current_stage = next_route
		update_stage(current_stage)

		turn = 0
		var action_player = "El jugador avanzó por la ruta estable"
		GameMaster.update_enemies_from_context(next_route)
		GameMaster.send_to_ai(action_player, current_stage.context)

	else:
		if not GameMaster.availableAI: return
		richLabel.text = "[wave amp=50.0 freq=5.0 connected=1]Sumergiéndose en la Falla Dimensional...[/wave]"
		update_active_buttons([])
		var accion = "El jugador avanzó hacia lo desconocido usando la opción " + str(id) + ". Describe el nuevo entorno liminal."
		GameMaster.send_to_ai(accion, current_stage.context)
	print("Boton presionado: " + str(id))
	update_status()

func generar_escenario_ia(texto_ia: String) -> void:
	var json = JSON.parse_string(texto_ia)
	if typeof(json) != TYPE_DICTIONARY or not json.has("narrativa"):
		print("Error: La IA no devolvió un formato JSON válido. Usando texto crudo.")
		json = {
			"narrativa": texto_ia, # Usamos todo el texto como fallback
			"combate_sugerido": false,
			"enemigos_elegidos": []
		}
	
	var new_stage = StageDB.new()
	var current_lang = GameMaster.config["Lang"] if GameMaster.get("config") else "ES_CL"
	new_stage.set("escenario_" + current_lang.to_lower(), json["narrativa"]) 
	
	turn += 1
	print("Profundidad de la falla: ", turn)
	
	if json["combate_sugerido"] == true:
		var a = json["enemigos_elegidos"].size()
		print("LA IA TE QUIERE MUERTO", json["enemigos_elegidos"])
		
		new_stage.context = "El jugador ha sido emboscado por %s entidades. El combate es inminente." % a
		
		new_stage.actions = {
			18: {"ES_CL": "¡LUCHA!"}
		}
		
		new_stage.connected_with = {
			18: load("res://Recursos/Escenarios/start.tres")
		}
		
		turn = 0
	else:
		new_stage.context = "El jugador sigue por el sendero" # Falta conexto desarrollado
		
		new_stage.actions = {
			1: {"ES_CL": "NADA"} # La IA debería de poder hacer esto
		}
	current_stage = new_stage
	update_stage(current_stage)
#endregion

#region --Input Func--
func update_status() -> void:
	$Status/BARS/LIFE.value = GameMaster.life
	$Status/BARS/CORD.value = GameMaster.cord
	$Status/BARS/HUNGER.value = GameMaster.hunger
	$Status/BARS/THIRST.value = GameMaster.thirst

func update_active_buttons(IDs: Array[int]) -> void:
	active_ids = IDs
	for btn in grid.get_children():
		var my_id = btn.get_meta("id")
		if active_ids.has(my_id):
			btn.disabled = false
			btn.modulate.a = 1.0
		else:
			btn.disabled = true
			btn.modulate.a = 0.0

func update_stage(stage: StageDB, force_lang: String = "") -> void:
	var current_lang = force_lang
	if force_lang.is_empty():
		current_lang = GameMaster.config["lang"] as String

	var langs = stage.get_languages()
	if langs.has(current_lang):
		if langs[current_lang].is_empty():
			print("ESCRIBE ALGO IDIOTA")
			return
		richLabel.text = langs[current_lang]
	else:
		print("idioma no soportado")
		update_stage(stage, "ES_CL")
		return

	var new_options: Array[int] = []
	new_options.assign(stage.actions.keys())
	update_active_buttons(new_options)

	for btn in grid.get_children():
		var my_id = btn.get_meta("id")
		
		if new_options.has(my_id):
			var actions_text_dict = stage.actions[my_id]
			if actions_text_dict.has(current_lang):
				btn.text = actions_text_dict[current_lang]

func _show_stats() -> void:
	var statsLabel = $Status/stats as RichTextLabel
	statsLabel.visible = !statsLabel.visible
	
	if statsLabel.visible:
		# Atenuar el fondo
		$Status/CHARACTER.modulate.a = 0.2
		$Status/BARS/LIFE.modulate.a = 0.2
		$Status/BARS/CORD.modulate.a = 0.2
		
		# Construir un string limpio sin formato JSON
		var formatted_text = "Estadísticas Actuales:\n\n"
		
		for stat_key in GameMaster.stats:
			var stat_value = GameMaster.stats[stat_key]
			# .capitalize() convierte "velocity" en "Velocity" automáticamente
			formatted_text += "- " + stat_key.capitalize() + ": " + str(stat_value) + "\n"
			
		statsLabel.text = formatted_text
		
	else:
		# Restaurar la opacidad al cerrar
		$Status/CHARACTER.modulate.a = 1.0
		$Status/BARS/LIFE.modulate.a = 1.0
		$Status/BARS/CORD.modulate.a = 1.0

func combat() -> void:
	GameMaster.update_enemies_from_context(current_stage)

	var total_weight := 0.0; var max_enemies = GameMaster.max_enemies
	for enemy in GameMaster.valid_pool_stable:
		total_weight += GameMaster.valid_pool_stable[enemy]
	var rng_monster = randf_range(0.0, total_weight)
	var rng_count = randi_range(1, max_enemies)
	var current_weight := 0.0

	for enemy in GameMaster.valid_pool_stable:
		current_weight += GameMaster.valid_pool_stable[enemy]
		if rng_monster <= current_weight:
			enemies.append(enemy)
			if enemies.size() >= rng_count:
				break

	var size_viewport = get_viewport_rect().size.y
	if not flag_combat:
		current_enemy = enemies[0]
		info.position.y += size_viewport
		richLabel.position.y += size_viewport
		status.position.y += size_viewport
		$Camera2D.position.y += size_viewport
		flag_combat = true
		$Info.show_enemy_status()
	else:
		info.position.y -= size_viewport
		richLabel.position.y -= size_viewport
		status.position.y -= size_viewport
		$Camera2D.position.y -= size_viewport
		flag_combat = false
		$Info.hide_enemy_status()
#endregion
