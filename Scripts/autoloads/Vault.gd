extends Node
class_name Storage
const EXTENSION = ".liminal"

const RES_MONS_PATH = "res://Recursos/Monstruos/"
const SAVE_PATH = "user://Breach_failure" + EXTENSION


var monsters: Array[MonsterDB]

var context: Dictionary = {
	"config": {
		"lang": "ES_CL",
		"wait_time": 3.0
	},
	"player": {
		"life": 100,
		"cord": 100,
		"hunger": 100.0,
		"thirst": 100.0,
		"resistance": 200.0,
		"inventory": {
			"items": [],
			"positions": []
		},
		"relations": {},
		"aspect": {},
		"stats": {
			"level": 1,
			"velocity": 10.0,
			"endurance": 10.0,
			"strength": 10.0,
			"psique": 100.0
		},
		"events": {}
	},
	"current_stage_path": "res://Recursos/Escenarios/start.tres",
	"precharged_stage": [] # Aquí iría las escenas creadas por la IA
}

func _ready() -> void:
	monsters = loads_monsters(RES_MONS_PATH)

func _save_in_disk(path: String, confirm: bool = false) -> bool:
	var full_path = "user://" + path
	_sync_with_gm()

	if FileAccess.file_exists(full_path) and !confirm:
		return false
	var file = FileAccess.open(full_path, FileAccess.WRITE)

	if file:
		file.store_var(context)
		file.close()
		return true
	return false

func load_from_disk(path) -> bool:
	var full_path = "user://" + path

	if !FileAccess.file_exists(full_path):
		print("No existe registro de su llegada.")
		return false

	var file = FileAccess.open(full_path, FileAccess.READ)
	if file:
		var loaded_data = file.get_var()
		file.close()

		if typeof(loaded_data) == TYPE_DICTIONARY:
			context = loaded_data
			_apply_to_gm()
			print("Brecha cargada correctamente")
			return true

	push_error("ARCHIVO IRRESOLUBLE") #0x02
	return false

func _sync_with_gm() -> void:
	# Fácil: Guardar desde GM al Dictionary Context
	context["config"]["lang"]                = GameMaster.config["lang"]
	context["config"]["wait_time"]           = GameMaster.config["wait_time"]
	context["player"]["life"]                = GameMaster.life
	context["player"]["cord"]                = GameMaster.cord
	context["player"]["hunger"]              = GameMaster.hunger
	context["player"]["thirst"]              = GameMaster.thirst
	context["player"]["inventory"]           = GameMaster.inventory
	context["player"]["relations"]           = GameMaster.relations
	context["player"]["resistance"]          = GameMaster.resistance
	context["player"]["aspect"]              = GameMaster.aspect
	context["player"]["stats"]["level"]      = GameMaster.stats["level"]
	context["player"]["stats"]["velocity"]   = GameMaster.stats["velocity"]
	context["player"]["stats"]["endurance"]  = GameMaster.stats["endurance"]
	context["player"]["stats"]["strength"]   = GameMaster.stats["strength"]
	context["player"]["stats"]["psique"]     = GameMaster.stats["psique"]
	
	# Difícil: Guardar las rutas como strings en el JSON
	context["current_stage_path"] = GameMaster.current_stage.resource_path
	
	context["player"]["events"].clear() # Limpiar antes de guardar
	for event_scene in GameMaster.events.keys():
		var scene_path = event_scene.resource_path
		var duration = GameMaster.events[event_scene]
		context["player"]["events"][scene_path] = duration

func _apply_to_gm() -> void:
	# Fácil: Cargar desde Dictionary Context al GM
	GameMaster.config["lang"]              = context["config"]["lang"]
	GameMaster.config["wait_time"]         = context["config"]["wait_time"]
	GameMaster.life                        = context["player"]["life"]
	GameMaster.cord                        = context["player"]["cord"]
	GameMaster.hunger                      = context["player"]["hunger"]
	GameMaster.thirst                      = context["player"]["thirst"]
	GameMaster.inventory                   = context["player"]["inventory"]
	GameMaster.relations                   = context["player"]["relations"]
	GameMaster.resistance                  = context["player"]["resistance"]
	GameMaster.aspect                      = context["player"]["aspect"]
	GameMaster.stats["level"]              = context["player"]["stats"]["level"]
	GameMaster.stats["velocity"]           = context["player"]["stats"]["velocity"]
	GameMaster.stats["endurance"]          = context["player"]["stats"]["endurance"]
	GameMaster.stats["psique"]             = context["player"]["stats"]["psique"]
	GameMaster.stats["strength"]           = context["player"]["stats"]["strength"]
	
	# Difícil: Cargar los recursos (load) usando las rutas guardadas en el JSON
	var stage_path = context["current_stage_path"]
	if ResourceLoader.exists(stage_path):
		GameMaster.current_stage = load(stage_path)
	else:
		push_error("No se pudo cargar el escenario: " + stage_path)

	GameMaster.events.clear()
	var player_events = context["player"]["events"]
	for path in player_events.keys():
		if ResourceLoader.exists(path):
			var scene: PackedScene = load(path) # Aquí se carga el EventScene/PackedScene
			var duration = player_events[path]
			GameMaster.events[scene] = duration
		else:
			push_warning("No se encontró el evento guardado: " + path)

func loads_monsters(path: String) -> Array[MonsterDB]:
	var dir = DirAccess.open(path); var m: Array[MonsterDB] = []
	if dir:
		dir.list_dir_begin()
		var filename = dir.get_next()
		while filename != "":
			if not dir.current_is_dir() and filename.ends_with(".tres"):
				# Se utiliza path_join para asegurar una ruta válida
				var monster = load(path.path_join(filename)) as MonsterDB
				if monster:
					m.append(monster)
			filename = dir.get_next()
		
		# Se imprime la variable local 'm' en lugar de 'monsters'
		print("Base de datos cargada: ", m.size(), " entidades.")

	return m
