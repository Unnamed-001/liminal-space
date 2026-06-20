extends Resource
class_name AttackDB

enum TYPE { PHYSICAL, PSICOLOGYCAL, DRAINING }

@export_category("info")
@export() var name: Dictionary[String, String] = {"ES_CL": "", "EN_US": ""}
@export var unique_id: int
@export var wait_time: float = 3.0
@export_category("damage")
@export var damage: int = 0
@export var type: TYPE = TYPE.PHYSICAL
@export_range(0.0, 30.0, 0.1) var variance: float = 0
@export_range(0.0, 100.0, 0.1) var critical_chance: float = 10
@export var effect: EffectDB

func get_damage() -> int:
	var variant_multiplier = randf_range(1.0 - variance, 1.0 + variance)
	var final_damage: float = damage * variant_multiplier
	
	var rng = randf_range(0.0, 100.0)
	if rng < critical_chance:
		final_damage *= 2.0
		print("¡Golpe Crítico!")
		
	# 3. Devolvemos el daño redondeado a número entero
	return roundi(final_damage)
