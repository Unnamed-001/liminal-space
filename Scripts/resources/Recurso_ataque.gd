extends ActionDB
class_name AttackDB

enum TYPE { PHYSICAL, PSICOLOGYCAL, DRAINING }

@export_category("damage")
@export var damage: int = 0 ## Intensidad o daño base de la acción
@export var type: TYPE = TYPE.PHYSICAL ## Tipo de daño de la acción
@export_range(0.0, 30.0, 0.1) var variance: float = 0 ## La variación del daño base
@export_range(0.0, 100.0, 0.1) var critical_chance: float = 10 ## Probabilidad de critico
@export var effect: EffectDB ## WIP
@export var player_dialogue: Dictionary[String, Dictionary] = {
	"ES_CL": {
		"LOW" = [""],
		"MEDIUM" = [""],
		"HIGH" = [""],
		"MASTER" = [""]
	},
	"EN_US": {
		"LOW" = [""],
		"MEDIUM" = [""],
		"HIGH" = [""],
		"MASTER" = [""]
	}
} ## Dialogo que sale al ocupar la acción, tiene maña, pero no me acuerdo

func get_damage() -> int: ## Obtiene el daño de la acción (daño hecho)
	var variant_multiplier = randf_range(1.0 - (variance / 100.0), 1.0 + (variance / 100.0))
	var final_damage: float = damage * variant_multiplier
	
	var rng = randf_range(0.0, 100.0)
	if rng < critical_chance:
		final_damage *= 2.0
		print("¡Golpe Crítico!")
		
	# 3. Devolvemos el daño redondeado a número entero
	return absi(roundi(final_damage))
