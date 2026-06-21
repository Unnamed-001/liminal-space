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
@export var duration: int = 1

func get_defense() -> Array[int]:
    var variant_multiplier = randf_range(1.0 - (variance / 100.0), 1.0 + (variance / 100.0))
    var final_defense: float = defense * variant_multiplier; var perfect_defense: float = 0.0
    var rng = randf_range(0.0, 100.0)

    if rng < perfect_block_chance:
        perfect_defense = final_defense * 10.0
        print("¡Bloqueo Perfecto!")
    return [absi(roundi(perfect_defense)), absi(roundi(final_defense))]