extends Resource
class_name MonsterDB

@export_category("Identificación")
@export var entity_name: Dictionary = {"ES_MX": "Entidad Desconocida"}
@export_range(1, 100, 1.0, "or_greater") var id_entity: int = 1

@export_category("Stats")
@export var life: int = 100
@export_group("attack")
@export var physical_attack: int = 10
@export var cord_damage: float = 0.1 # Daño se hace solo con estar en combate, al completar un entero se aplica daño
@export_group("")
@export var defense: float = 10.0
@export var speed: float = 10.0

@export_category("Interacciones especiales")
@export var tamable: bool = false
@export var intelligent: bool = false
@export var min_damage: float = 0.3 # minimo 30 de vida restante para "capturarlo"
@export var min_affinity: int = 10

@export_category("Contexto para IA")
@export_multiline() var context: String = ""
