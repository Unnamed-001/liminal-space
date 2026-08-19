extends Node
class_name GM

enum actions { SCRATCH, CORRODE, ENCHANT, DRIVE_MAD, FLEE, STALK, PURSUE, PIERCE, DEVOUR, IMMOBILIZE, HYPNOTIZE, OBSERVE, ADMIRE, STRIKE }
enum special_case { DANGER_ZONE, SECURE_ZONE, RESTRICTED_AREA, DRAINING_AREA, POISON_AREA, NONE }

signal ai_response(generated_text: String)
signal player_action
signal clean_resource(enemy: MonsterDB)

@onready var http: PackedScene = preload("res://Escenas/additions/http_request.tscn")
var available_enemies: Array[MonsterDB] = []
var max_enemies: int = 2
var availableAI: bool = false
## Configuraciones del juego en tiempo real
var config: Dictionary = {
	"lang": "ES_CL",
	"wait_time": 3.0,
	"text_speed": 0.03
}
var instance_http_service: Http_service

func _ready() -> void:
	# Como la comprobación tarda unos milisegundos, le decimos a Godot que espere
	player_action.connect(_player_action)
	instance_http_service = http.instantiate()
	add_child(instance_http_service)
	await instance_http_service.prepare_ai_system()
	
	if instance_http_service.availableAI:
		print("The AI está en linea y lista para la Falla Dimensional")
	else:
		print("CRÍTICO: La IA no responde.")

#region --Player--
var life: int = 100
var cord: int = 100
var hunger: float = 100.0
var thirst: float = 100.0
var resistance: float = 200.0
var inventory: Array[ItemDB] = []
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
	var factor_dificultad = floori(stats["level"] + (stats["endurance"] / fuerza_real))
	var max_posible = max(1, min(factor_dificultad, stats["level"], 6)) 
	var tirada_rng = randi_range(1, max_posible)
	var limit = min(tirada_rng, valid_pool.size())


	for i in range(limit):
		available_enemies.append(valid_pool[i])

	print("Presupuesto de IA cargado con ", limit, " entidades.")
#endregion
#region --Escenarios--
# Datos ocupados en Main_game.gd para el control de escenarios
var in_the_zone: int = 0
var turn: int = 0
var last_zone: int = 0
var current_zone: int = 0
var stage_generated: Array[StageDB] = []

func generar_escenario_ia(texto_ia: String) -> void:
	var json = JSON.parse_string(texto_ia)
	if typeof(json) != TYPE_DICTIONARY or not json.has("actions"):
		print("Error de formato JSON de la IA. Usando fallback.")
		# Manejo de error o escenario por defecto
		return
	
	var new_stage = StageDB.new()
	new_stage.title = json.get("title", "ZONA DESCONOCIDA")
	new_stage.id_zone = json.get("id_zone", 0)
	new_stage.difficulty = json.get("difficulty", 1)
	new_stage.context = json.get("context", "")
	
	# Asignar descripciones multilingües
	var desc_dict = json.get("stage_description", {})
	if desc_dict.has("ES_CL"):
		new_stage.escenario_es_cl = [desc_dict["ES_CL"]]
	if desc_dict.has("EN_US"):
		new_stage.escenario_en_us = [desc_dict["EN_US"]]
		
	# Procesar y construir el arreglo de acciones dinámicamente
	var new_actions: Array = []
	
	for act_data in json["actions"]:
		var new_action = ActionDB.new() # O tu clase/recurso de opción
		new_action.id = act_data.get("id", 1)
		new_action.name_dict = act_data.get("name", {"ES_CL": "Avanzar"})
		new_action.strength = act_data.get("strength", 0)
		
		# Mapeamos el String del JSON al Enum de Godot
		match act_data.get("result", "AI_FALLBACK"):
			"STAGE_TRANSITION":
				new_action.result = OptionDB.OptionResult.STAGE_TRANSITION
				var path = act_data.get("target_ref", "")
				if ResourceLoader.exists(path):
					new_action.target_stage = load(path)
			
			"GIVE_ITEM":
				new_action.result = OptionDB.OptionResult.GIVE_ITEM
				var item_key = act_data.get("target_ref", "")
				# Buscamos el ítem en nuestro catálogo seguro del Vault
				if Vault.item_catalog.has(item_key):
					new_action.target_item = Vault.item_catalog[item_key]
				else:
					print("La IA intentó dar un ítem no registrado: ", item_key)
			
			"EVENT_TRIGGER":
				new_action.result = OptionDB.OptionResult.EVENT_TRIGGER
				# Lógica para eventos
				
			_: # Por defecto o "AI_FALLBACK"
				new_action.result = OptionDB.OptionResult.AI_FALLBACK
				
		new_actions.append(new_action)
	
	new_stage.actions = new_actions
	
	turn += 1
	stage_generated.append(new_stage)
#endregion
