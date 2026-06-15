extends Control
const max_turns: int = 5

@onready var cRect = $ColorRect
@onready var grid = $buttons/GridContainer
@onready var status = $Status
@onready var richLabel = $stage
var active_ids: Array[int] = []
var current_stage: StageDB = load("res://Recursos/Escenarios/start.tres")
var in_the_zone: int = 0
var turn: int = 0



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#region --Animacion de inicio--
	cRect.visible = true
	cRect.color = Color.WHITE
	var tween = create_tween()
	tween.tween_property(cRect, "color", Color(0.294, 0.294, 0.294, 0.0), 1.0).set_ease(Tween.EASE_IN)
	#endregion
	GameMaster.connect("ai_response", Callable(self, "Generated_stage_AI"))
	update_stage(current_stage)
	_prepare_buttons()
	update_status()

#region --Output Func--
func _prepare_buttons():
	for btn in grid.get_children():
		var my_id = btn.get_meta("id")
		print(str(my_id))
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
	# 1. Creamos un escenario fantasma en la memoria RAM
	var nuevo_escenario = StageDB.new()
	
	# Usamos el idioma dinámico que programamos antes (asumiendo que usas "ES_CL")
	var idioma_actual = GameMaster.config["Lang"] if GameMaster.get("config") else "ES_CL"
	nuevo_escenario.set("escenario_" + idioma_actual.to_lower(), texto_ia) 
	# (Nota: O simplemente puedes asignar directo si no usas la función dinámica: nuevo_escenario.escenario_es_cl = texto_ia)
	
	# 2. Aumentamos el contador de locura
	turn += 1
	print("Profundidad de la falla: ", turn, "/", max_turns)
	
	if turn >= max_turns:
		# --- SALVAVIDAS ACTIVADO (Forzar regreso a Ruta Estable) ---
		nuevo_escenario.context = "El jugador ha encontrado una anomalía estable."
		
		# Le damos solo UNA opción que lo arrastrará de vuelta a tus mecánicas reales
		nuevo_escenario.actions = {
			1: {idioma_actual: "Entrar por la Puerta Blindada (Combate inminente)"}
		}
		
		# Aquí conectas físicamente el botón a uno de tus Datapacks reales de combate
		nuevo_escenario.connected_stages = {
			1: "res://Recursos/Escenarios/Combate_Monstruo_Base.tres"
		}
		
	else:
		# --- CONTINÚA LA LOCURA ---
		nuevo_escenario.context = "El jugador sigue vagando por pasillos procedurales. Mantén la tensión."
		
		# Generamos botones "falsos" que no tienen conexión, lo que forzará 
		# a la función pressed_button a volver a llamar a la IA al hacer clic.
		nuevo_escenario.actions = {
			1: {idioma_actual: "Correr recto hacia la oscuridad"},
			2: {idioma_actual: "Revisar la extraña puerta de la izquierda"}
		}
		# NO llenamos "connected_stages", así el ciclo inestable continúa.

	# 3. Sobrescribimos el escenario en pantalla y encendemos los botones
	current_stage = nuevo_escenario
	update_stage(current_stage)
# Falta desarrollo profundo
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
#endregion
