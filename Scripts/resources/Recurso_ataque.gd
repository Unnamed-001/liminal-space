extends ActionDB
class_name AttackDB

enum TYPE { PHYSICAL, PSICOLOGYCAL, DRAINING }

@export_category("info")
@export var unique_id: int
@export_category("damage")
@export var damage: int = 0
@export var type: TYPE = TYPE.PHYSICAL
@export_range(0.0, 30.0, 0.1) var variance: float = 0
@export_range(0.0, 100.0, 0.1) var critical_chance: float = 10
@export var effect: EffectDB
@export var player_dialogue: Dictionary[String, Dictionary] = {
	"ES_CL": {
		"LOW" = [""],
		"MEDIUM" = [""],
		"HIGH" = [""],
		"MASTER" = [""]
	},
	"EN_US": {}
}

func get_damage() -> int:
	var variant_multiplier = randf_range(1.0 - (variance / 100.0), 1.0 + (variance / 100.0))
	var final_damage: float = damage * variant_multiplier
	
	var rng = randf_range(0.0, 100.0)
	if rng < critical_chance:
		final_damage *= 2.0
		print("¡Golpe Crítico!")
		
	# 3. Devolvemos el daño redondeado a número entero
	return absi(roundi(final_damage))
