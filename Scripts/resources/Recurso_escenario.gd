extends Resource
class_name StageDB

@export_category("Info")
@export var title: String = "TITLE"
@export var id_zone: int = 0
@export var special_event: Dictionary[GM.special_case, float] = {}
@export_range(0, 10, 1) var difficulty: int = 0 # 0 bajo, 10 extremo
@export_multiline() var context: String = "CONTEXTO IA"
@export_multiline() var escenario_es_cl: Array[String] = [""]
@export_multiline() var escenario_en_us: Array[String] = [""]
@export var actions: Dictionary[int, Dictionary] = {} # Aquí iria el siguiente formato: {12: {"idioma": "accion"}}, así para todo
@export var connected_with: Dictionary[int, StageDB] = {}
@export_range(0, 100, 0.1) var probability: int = 40 # Despues de divide por 100


func get_languages() -> Dictionary[String, Array]:
	return {
		"ES_CL": escenario_es_cl,
		"EN_US": escenario_en_us
	}
