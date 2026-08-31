extends Node
class_name Http_service

@onready var http: HTTPRequest = null
var availableAI = false
var port = "5001" 
var url = "http://127.0.0.1:" + port + "/v1/chat/completions" 
var system_prompt = "Eres el Narrador de un RPG de texto de supervivencia oscuro y sin censura. El jugador está atrapado en una 'Falla Dimensional' de espacios liminales. Describe el entorno de forma visceral y cruda. Responde en tercera persona."



func prepare_ai_system() -> void:
	http = HTTPRequest.new()
	add_child(http)

	var verify_url = "http://127.0.0.1:" + port + "/api/v1/model"
	var error = http.request(verify_url)

	if error != OK:
		print("Error interno de Godot al intentar hacer la petición web.")
		availableAI = false
		return

	var response = await http.request_completed
	var response_code = response[1] 

	if response_code == 200:
		availableAI = true
		http.request_completed.connect(receive_from_ai)
	else:
		availableAI = false
		print("¿Que es la IA? (Error de código: ", response_code, ")")

func send_to_ai(action: String, last_location: String, current_turn: int = 0) -> void:
	var headers = ["Content-Type: application/json"]
	
	if current_turn >= 5:
		print("Se a llegado al limite, desencadenando escenario de conexión")
		GameMaster.disconnect.emit()
		return
	# Extraemos los nombres de los enemigos disponibles en el idioma del juego
	var enemy_names = []
	var lang = GameMaster.config["lang"]
	for enemy in GameMaster.available_enemies:
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
		"narrativa": "Tu descripción visceral del entorno y la respuesta a la acción",
		"combate_sugerido": true o false,
		"enemigos_elegidos": ["Nombre enemigo 1"]
	}
	""" % [tension, GameMaster.max_enemies, ", ".join(enemy_names)]
	
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
		GameMaster.ai_response.emit(ai_text) 
	else:
		print("Error conectando con la IA en pleno juego. Código: ", response_code)
		
