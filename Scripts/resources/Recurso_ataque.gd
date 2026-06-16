extends Resource
class_name AttackDB

@export_category("info")
@export_multiline() var name: Dictionary[String, String] = {"ES_CL": "", "EN_US": ""}
@export var unique_id: int
@export_category("damage")
@export var damage: int = 0
@export var type: GameMaster.type
@export_range(0.0, 30.0) var variance: float = 0
@export_range(0.0, 100.0) var critical_chance: float = 10
