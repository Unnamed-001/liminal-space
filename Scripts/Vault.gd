extends Node
class_name Storage

const SAVE_PATH = "user://Breach_failure.json"

var context: Dictionary = {
	"player": {
		"life": 100,
		"cord": 100,
		"hunger": 100.0,
		"thirst": 100.0,
		"resistance": 200.0,
		"inventory": [],
		"relations": {},
		"aspect": {},
		"stats": {
			"level": 1,
			"velocity": 10.0,
			"endurance": 10.0,
			"strength": 10.0,
			"psique": 100.0
		}
	},
	"current_stage_path": "res://Recursos/Escenarios/start.tres",
	"precharged_stage": [StageDB]
}

func _save_in_disk() -> void:
	_sync_with_gm()
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_str = JSON.stringify(context, "\t")
		file.store_string(json_str)
		file.close()
		print("saved")
	else:
		print("❌ Error crítico: Las leyes de la física impiden escribir en el disco.")

func load_from_disk() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		print("No existen registros de su llegada")
		return false
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_str = file.get_as_text()
		file.close()
		var json = JSON.new()
		var error = json.parse(json_str)
		if error == OK:
			context = json.data
			_apply_to_gm()
			print("Brecha cargada correctamente")
			return true
	
	push_error("Corrupted archive")
	return false

func _sync_with_gm() -> void:
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

func _apply_to_gm() -> void:
	GameMaster.life                = context["player"]["life"]
	GameMaster.cord                = context["player"]["cord"]
	GameMaster.hunger              = context["player"]["hunger"]
	GameMaster.thirst              = context["player"]["thirst"]
	GameMaster.inventory           = context["player"]["inventory"]
	GameMaster.relations           = context["player"]["relations"]
	GameMaster.resistance          = context["player"]["resistance"]
	GameMaster.aspect              = context["player"]["aspect"]
	GameMaster.stats["level"]      = context["player"]["stats"]["level"]
	GameMaster.stats["velocity"]   = context["player"]["stats"]["velocity"]
	GameMaster.stats["endurance"]  = context["player"]["stats"]["endurance"]
	GameMaster.stats["strength"]   = context["player"]["stats"]["strength"]
	GameMaster.stats["psique"]     = context["player"]["stats"]["psique"]
