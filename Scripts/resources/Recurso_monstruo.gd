extends Resource
class_name MonsterDB

@export_category("Identificación")
@export var entity_name: Dictionary[String, String] = {"ES_CL": "Entidad Desconocida"} ## Nombre de la entidad
@export_group("Dificultad, aparición y nivel")
@export_range(0, 10, 1.0, "hide_control") var difficulty: int = 0 ## WIP
@export var spawn_zones: Array[int] = [0] ## Zonas en las que aparece la entidad
@export_range(0.01, 100, 1.0) var probability: float = 100.0 ## Probabilidad de aparición
@export_range(0, 100, 1.0, "or_greater", "hide_control") var min_level: int = 0 ## Nivel mínimo para aparecer

@export_category("Stats")
@export_range(0, 100, 1.0, "or_greater", "hide_control") var life: int = 100 ## Vida de la entidad
@export_range(-1, 100, 1.0, "or_greater", "hide_control") var cord: int = -1 ## Cordura de la entidad
@export_group("attack")
@export_range(0, 100, 1.0, "or_greater", "hide_control") var strength: int = 10 # creo que será un multiplicador?
@export_range(0, 100, 1.0, "or_greater", "hide_control") var cord_damage: float = 0.1 # Daño se hace solo con estar en combate, al completar un entero se aplica daño
@export var possible_actions: Array[SlotDB] = [] ## Acciones posibles de la entidad
@export_group("")
@export_range(0, 100, 1.0, "or_greater", "hide_control") var defense: float = 10.0 ## Defensa de la entidad
@export_range(0, 100, 1.0, "or_greater", "hide_control") var speed: float = 10.0 ## WIP

@export_category("Interacciones especiales")
@export var can_capture: bool = false ## ¿Es capturable?
@export var tamable: bool = false ## ¿Es domable?
@export var intelligent: bool = false ## ¿Es inteligente?
@export_range(0, 100, 1.0, "or_greater", "hide_control") var min_damage: float = 0.3 ## Mínimo de vida restante para "capturarlo"
@export_range(0, 100, 1.0, "or_greater", "hide_control") var min_affinity: int = 10 ## Mínimo de afinidad para "capturarlo

@export_category("Contexto")
@export_multiline() var ai_context: String = "" ## Contexto para la IA
@export var stay_variants: Dictionary[String, Array] = {
	"ES_CL": ["", "", ""],
	"EN_US": ["", "", ""]
} ## En combate
@export var start_variants: Dictionary[String, Array] = {
	"ES_CL": ["", "", ""],
	"EN_US": ["", "", ""]
} ## Al iniciar 
@export var damage_variants: Dictionary[String, Dictionary] = {
	"ES_CL": {
		"LOW": ["", "", ""],
		"MEDIUM": ["", "", ""],
		"HIGH": ["", "", ""],
		"MASTER": ["", "", ""]
		},
	"EN_US": {
		"LOW": ["", "", ""],
		"MEDIUM": ["", "", ""],
		"HIGH": ["", "", ""],
		"MASTER": ["", "", ""]
		},
}
