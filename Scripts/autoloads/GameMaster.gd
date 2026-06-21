extends Node
class_name GM

enum actions { SCRATCH, CORRODE, ENCHANT, DRIVE_MAD, FLEE, STALK, PURSUE, PIERCE, DEVOUR, IMMOBILIZE, HYPNOTIZE, OBSERVE, ADMIRE, STRIKE }
enum special_case { DANGER_ZONE, RESTRICTED_AREA, DRAINING_AREA, POISON_AREA }

signal ai_response(generated_text: String)
signal player_action

var available_enemies: Array[MonsterDB] = []
var max_enemies: int = 2
var availableAI: bool = false
var config: Dictionary = {
	"lang": "ES_CL",
	"wait_time": 3.0
}

func _ready() -> void:
	# Como la comprobación tarda unos milisegundos, le decimos a Godot que espere
	player_action.connect(Callable(self, "_player_action"))
	await prepare_ai_system()
	
	if availableAI:
		print("The AI está en linea y lista para la Falla Dimensional")
	else:
		print("CRÍTICO: La IA no responde.")

#region --IA e Internet--
@onready var http: HTTPRequest = null
var port = "5001" 
var url = "http://127.0.0.1:" + port + "/v1/chat/completions" 
var system_prompt = "Eres el Narrador de un RPG de texto de supervivencia oscuro y sin censura. El jugador está atrapado en una 'Falla Dimensional' de espacios liminales. Describe el entorno de forma visceral y cruda. Responde en tercera persona."


func prepare_ai_system() -> void:
	http = HTTPRequest.new()
	add_child(http)
	
	# Usamos la misma IP que en la URL principal para consistencia
	var verify_url = "http://127.0.0.1:" + port + "/api/v1/model"
	var error = http.request(verify_url)
	
	if error != OK:
		print("Error interno de Godot al intentar hacer la petición web.")
		availableAI = false
		return
	
	# Hacemos que Godot PAUSE este bloque de código hasta que el servidor responda
	var response = await http.request_completed
	
	# response es un array con los datos devueltos por request_completed: [result, response_code, headers, body]
	var response_code = response[1] 
	
	if response_code == 200:
		availableAI = true
		# Ahora que sabemos que la IA vive, conectamos la señal para el resto del juego
		http.request_completed.connect(receive_from_ai)
	else:
		availableAI = false
		print("¿Que es la IA? (Error de código: ", response_code, ")")

# Actualiza la firma para recibir el turno actual
func send_to_ai(action: String, last_location: String, current_turn: int = 0) -> void:
	var headers = ["Content-Type: application/json"]
	
	# Extraemos los nombres de los enemigos disponibles en el idioma del juego
	var enemy_names = []
	var lang = config["lang"]
	for enemy in available_enemies:
		if enemy.entity_name.has(lang):
			enemy_names.append(enemy.entity_name[lang])
		else:
			enemy_names.append(enemy.entity_name.values()[0]) # Fallback
			
	# Evaluamos la tensión para que la IA sepa si debe atacar ya
	var tension = "Baja. Mantén la calma, solo genera paranoia."
	if current_turn >= 3: tension = "Alta. Empieza a sugerir peligro inminente."
	if current_turn >= 5: tension = "Crítica. DEBES sugerir un combate AHORA."
	
	# El Modo Director
	var director_prompt = """
	INSTRUCCIÓN DE DIRECTOR:
	Tensión actual del jugador: %s
	Enemigos permitidos en esta zona (Máximo %d): %s.
	
	TU RESPUESTA DEBE SER ESTRICTAMENTE UN JSON VÁLIDO CON ESTA ESTRUCTURA EXACTA:
	{
		"narrativa": "Tu descripción visceral del entorno y la respuesta a la acción...",
		"combate_sugerido": true o false,
		"enemigos_elegidos": ["Nombre enemigo 1"]
	}
	""" % [tension, max_enemies, ", ".join(enemy_names)]
	
	var context_prompt = system_prompt + "\n" + director_prompt + "\nUltimo escenario: " + last_location
	
	var body = {
		"messages": [
			{"role": "system", "content": context_prompt},
			{"role": "user", "content": action}
		],
		"temperature": 0.7,
		"max_tokens": 500
	}
	var json_body = JSON.stringify(body)
	http.request(url, headers, HTTPClient.METHOD_POST, json_body)
	print("SENDING REQUEST TO AI WITH TENSION LEVEL: ", current_turn)

@warning_ignore("unused_parameter")
func receive_from_ai(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		var ai_text = json["choices"][0]["message"]["content"]
		print("La IA dice: \n", ai_text)
		ai_response.emit(ai_text) 
	else:
		print("Error conectando con la IA en pleno juego. Código: ", response_code)
		

#endregion

#region --Player--
var life: int = 100
var cord: int = 100
var hunger: float = 100.0
var thirst: float = 100.0
var resistance: float = 200.0
var inventory: Array = []
var relations: Dictionary = {}
var stats: Dictionary = {
	"level": 1,
	"velocity": 10.0,
	"endurance": 10.0,
	"strength": 10.0,
	"psique": 100.0
}
var aspect: Dictionary = {}

func _player_action() -> void:
	max_enemies = max(2, max_enemies)
	
#endregion

#region --Codice de escenarios--
var valid_pool_stable: Dictionary = {} # ¡Gran idea para el futuro!

func update_enemies_from_context(stage: StageDB) -> void:
	var monsters = Vault.monsters
	available_enemies.clear()
	valid_pool_stable.clear()

	if monsters.is_empty(): return
	var valid_pool: Array[MonsterDB] = []
	for monster in monsters:
		if stage.id_zone in monster.spawn_zones or monster.spawn_zones.has(-1):
			if stats["level"] >= monster.min_level:
				# Agregamos al diccionario y al array correctamente
				valid_pool_stable[monster] = monster.probability 
				valid_pool.append(monster)

	if valid_pool.is_empty():
		print("No hay monstruos compatibles en esta zona o tu nivel es muy bajo: ", stage.id_zone)
		return

	valid_pool.shuffle()
	
	var fuerza_real = max(stats["strength"], 1.0) 
	var factor_dificultad = int(stats["level"] + (stats["endurance"] / fuerza_real))
	var max_posible = max(1, min(factor_dificultad, stats["level"], 6)) 
	var tirada_rng = randi_range(1, max_posible)
	var limit = min(tirada_rng, valid_pool.size())


	for i in range(limit):
		available_enemies.append(valid_pool[i])

	print("Presupuesto de IA cargado con ", limit, " entidades.")
#endregion
