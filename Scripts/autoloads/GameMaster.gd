extends Node
class_name GM

enum actions { SCRATCH, CORRODE, ENCHANT, DRIVE_MAD, FLEE, STALK, PURSUE, PIERCE, DEVOUR, IMMOBILIZE, HYPNOTIZE, OBSERVE, ADMIRE, STRIKE }
enum special_case { DANGER_ZONE, RESTRICTED_AREA, DRAINING_AREA, POISON_AREA, NONE }

signal ai_response(generated_text: String)
signal player_action
signal clean_resource(enemy: MonsterDB)

@onready var http: PackedScene = preload("res://Escenas/additions/http_request.tscn")
var available_enemies: Array[MonsterDB] = []
var max_enemies: int = 2
var availableAI: bool = false
var config: Dictionary = {
	"lang": "ES_CL",
	"wait_time": 3.0,
	"text_speed": 0.03
}
var instance_http_service: Http_service

func _ready() -> void:
	# Como la comprobación tarda unos milisegundos, le decimos a Godot que espere
	player_action.connect(Callable(self, "_player_action"))
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
	var factor_dificultad = floori(stats["level"] + (stats["endurance"] / fuerza_real))
	var max_posible = max(1, min(factor_dificultad, stats["level"], 6)) 
	var tirada_rng = randi_range(1, max_posible)
	var limit = min(tirada_rng, valid_pool.size())


	for i in range(limit):
		available_enemies.append(valid_pool[i])

	print("Presupuesto de IA cargado con ", limit, " entidades.")
#endregion
