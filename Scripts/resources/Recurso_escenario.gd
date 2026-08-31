extends Resource
class_name StageDB

@export_category("Info")
@export var title: String = "TITLE" ## Titulo del escenario (sin uso)
@export var id_zone: int = 0 ## Id de la zona, sirve para saber que zonas comparten algún efecto o evento
@export var special_event: Dictionary[GM.special_case, int] = {} ## Tipo de eventos especiales que puede tener el escenario
@export_range(0, 10, 1) var difficulty: int = 0 ## 0 bajo, 10 extremo (WIP)
@export_multiline() var context: String = "CONTEXTO IA" ## Contexto del escenario, para la IA
@export_multiline() var escenario_es_cl: Array[String] = [""] ## Escenario en español
@export_multiline() var escenario_en_us: Array[String] = [""] ## Escenario en ingles
@export var actions: Array[OptionDB] = [] ## Opciones disponibles
@export_range(0, 100, 0.1) var probability: int = 40 # Despues de divide por 100 ## WIP
var generated_by_IA: bool = false

func get_languages() -> Dictionary[String, Array]: ## Obtiene los idiomas del escenario actual
	return {
		"ES_CL": escenario_es_cl,
		"EN_US": escenario_en_us
	}
