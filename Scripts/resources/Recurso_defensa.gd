extends Resource
class_name DefenseDB

@export_category("info")
@export_multiline() var name: Dictionary[String, String] = {"ES_CL": "", "EN_US": ""}
@export var unique_id: int
@export_category("defense")
@export var defense: int = 0
@export var effect: EffectDB
@export_range(30.0, 100.0, 0.1) var variance: float = 30.0
@export_range(0.0, 100.0, 0.1) var perfect_block_chance: float = 10