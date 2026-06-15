extends Node
class_name GM

enum special_case { DANGER_ZONE, RESTRICTED_AREA, DRAINING_AREA, POISION_AREA }

signal ai_response(generated_text: String)

var available_enemies: Array[MonsterDB] = []
var max_enemies: int = 2
var availableAI: bool = false
var config: Dictionary = {
	"lang": "ES_CL"
}

func _ready() -> void:
	# Como la comprobación tarda unos milisegundos, le decimos a Godot que espere
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

func send_to_ai(action: String, last_location: String) -> void:
	var headers = ["Content-Type: application/json"]
	
	# Combinamos el context dentro del rol 'system' para que la API no colapse
	var context_prompt = system_prompt + " Ultimo escenario del jugador: " + last_location
	
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
	print("SENDING REQUEST TO AI...")

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

func _player_action():
	max_enemies = max(2, max_enemies)
	
#endregion

#region --Codice de escenarios--
func update_enemies_from_context(stage: StageDB) -> void:
	pass
#endregion
