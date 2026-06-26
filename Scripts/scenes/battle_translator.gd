extends RichTextLabel
class_name BattleTranslator

@onready var main: MainGame = $"../.."

signal finish_typing

var chosen_text: Array = []
var is_typing: bool = false

func _ready() -> void:
	clear()
	get_parent().connect("start_turn", _update)

func start_combat() -> void:
	var lang: String = GameMaster.config["lang"]
	for enemy in main.enemies:
		# Usamos un fallback seguro por si el diccionario de inicio no tiene la clave
		var available_variants: Array = enemy.start_variants.get(lang, enemy.start_variants.get("ES_CL", []))
		
		# Evita un crash si olvidaste ponerle texto al monstruo
		if not available_variants.is_empty():
			var selected_phrase: String = available_variants.pick_random()
			chosen_text.append(selected_phrase)

	_update()

func add_text_to_array_for_enemy(slot: SlotDB, damage_dealt: int, type: AttackDB.TYPE, attacker: MonsterDB) -> void:
	var lang: String = GameMaster.config.get("lang", "ES_CL")
	var available_phrases: Array = slot.dialogue.get(lang, slot.dialogue.get("ES_CL", []))

	var selected_phrase: String = "El ataque te impacta." 
	if not available_phrases.is_empty():
		selected_phrase = available_phrases.pick_random()

	var format_phrase: String = selected_phrase.format({
		"damage": str(damage_dealt), 
		"type": get_text_for_type(type)
	})

	chosen_text.append_array([format_phrase, 0, attacker.stay_variants[lang].pick_random()])

func add_text_to_array_for_player(attack: AttackDB, damage_dealt: int, target: MonsterDB) -> void:
	var lang: String = GameMaster.config["lang"]
	
	var level: StringName = _get_level_for_player(attack, damage_dealt)
	var dialoge_chosen: Dictionary = attack.player_dialogue.get(lang, attack.player_dialogue.get("ES_CL", {}))
	var varian_chosen: Dictionary = target.damage_variants.get(lang, target.damage_variants.get("ES_CL", {}))
	
	var action_text: String = ""
	var reaction_text: String = ""
	
	if dialoge_chosen.has(level) and not dialoge_chosen[level].is_empty():
		action_text = dialoge_chosen[level].pick_random()
		
	if varian_chosen.has(level) and not varian_chosen[level].is_empty():
		reaction_text = varian_chosen[level].pick_random()
	
	# 1. FUSIONAMOS la frase en un solo String
	var combined_phrase: String = action_text + " " + reaction_text + " Le haz hecho {damage} de {type}"
	
	# 2. Aplicamos el BBCode (temblor, color)
	
	# 3. Formateamos las matemáticas
	var format_phrase: String = combined_phrase.format({
		"damage": str(damage_dealt),
		"type": get_text_for_type(attack.type)
	})
	
	# 4. Lo guardamos correctamente
	chosen_text.append(format_phrase)

func get_text_for_type(type: AttackDB.TYPE) -> String:
	var lang: String = GameMaster.config["lang"]
	var type_phrase: String = ""

	match type:
		AttackDB.TYPE.PHYSICAL:
			type_phrase = "physical damage" if lang == "EN_US" else "daño físico"
		AttackDB.TYPE.PSICOLOGYCAL:
			type_phrase = "psychological damage" if lang == "EN_US" else "daño psicológico"
		# ¡Inyectamos BBCode automáticamente para hacer vibrar el texto!
		# selected_phrase = "[shake rate=20.0 level=5 connected=1]" + selected_phrase + "[/shake]"
		AttackDB.TYPE.DRAINING:
			type_phrase = "draining damage" if lang == "EN_US" else "daño drenante"
		# Opcional: inyectar un color rojizo u ondulación para el drenaje
		# selected_phrase = "[color=crimson]" + selected_phrase + "[/color]"
	return type_phrase

func _get_level_for_player(attack: AttackDB, damage_dealt: int) -> StringName:
	var base_damage: float = float(attack.damage)
	var dealt_float: float = float(damage_dealt)
	var variance_decimal: float = attack.variance / 100.0
	
	var min_damage: float = base_damage * (1.0 - variance_decimal)
	var max_damage: float = base_damage * (1.0 + variance_decimal)
	
	if dealt_float > max_damage:
		return &"MASTER"
	if attack.variance <= 0.0:
		return &"MEDIUM"

	var percentile: float = (dealt_float - min_damage) / (max_damage - min_damage)
	
	if percentile < 0.33:
		return &"LOW"
	if percentile > 0.66:
		return &"HIGH"
	return &"MEDIUM"

func _update(stop: float = 0.0) -> void:
	if is_typing or chosen_text.is_empty():
		return

	is_typing = true
	clear()
	visible_characters = 0 # Ocultamos todo al principio
	var duration

	# Extraemos la velocidad, o usamos 0.03 como respaldo seguro
	var speed: float = GameMaster.config.get("text_speed", 0.03)

	while not chosen_text.is_empty():
		var t = chosen_text.pop_front()
		if not t is String:
			break
		var start_chars = get_total_character_count()
		append_text(t + "\n\n")
		var target_chars = get_total_character_count()

		duration = (target_chars - start_chars) * speed

		if duration > 0:
			var tween = create_tween()
			tween.tween_property(self, "visible_characters", target_chars, duration)
			await tween.finished

	
			await get_tree().create_timer(0.4).timeout
	is_typing = false
	finish_typing.emit()
