extends Resource
class_name ActionDB

@export_category("info")
@export() var name: Dictionary[String, String] = {"ES_CL": "", "EN_US": ""}
@export var wait_time: float = 3.0

func get_action_name(lang: String = GameMaster.config["lang"]) -> String:
	if name.has(lang):
		return name[lang]
	else:
		return name["ES_CL"]  # Devuelve el nombre en español por defecto si el idioma no está disponible
		# Que voy a hablar ingles como idioma nativo, no se ingles, ocupo ingles para programar porque no se puede ocupar español
