extends Node
class_name BattleLogic

@onready var parent: Battle = get_parent()
@onready var translator: BattleTranslator = $"../RichTextLabel"
@onready var main: MainGame = $"../.."

var chosen_lang = GameMaster.config["lang"]
var additional_defense: Array[int] = []
var acumulation_cord_damage: float = 0.0

func _player_turn() -> void:
	pass

#region --Funciones de defensa--
func _to_defense() -> void:
	parent.current_state = parent.STATES.DEFENSE
	parent._activated_pages(parent.STATES.DEFENSE)
	for i in range(parent.gridbtn.size()):
		var btn = parent.gridbtn[i]
		var btn_page = i + (4 * parent.page)
		if btn_page < parent.defense_options.size():
			var defense = parent.defense_options[btn_page]
			btn.text = defense.name[chosen_lang]
			btn.disabled = false
		else:
			btn.text = "---"
			btn.disabled = true

func _defend_yourself(id: int) -> void:
	var index: int = id - 1 + (4 * parent.page)
	if index < parent.defense_options.size():
		var chosen_defense = parent.defense_options[index]
		_apply_defense(chosen_defense)

	parent.end_turn.emit()

func _apply_defense(defense: DefenseDB) -> void:
	var defense_result: Array[int] = defense.get_defense()
	var duration: int = defense.duration
	var final_defense: Array[int] = defense_result
	print("Defensa aplicada (array): ", defense_result, " Duración: ", duration, " Turnos")
	for i in range(duration - 1):
		var for_multiply = defense_result[1]
		final_defense.append(for_multiply)
	print("Defensa final (array): ", final_defense, " Duración: ", duration, " Turnos")
	if duration == 1:
		if defense_result[0] <= 0.0:
			additional_defense.append(defense_result[1])
		else:
			additional_defense.append(defense_result[0])
	else:
		additional_defense.append_array(final_defense)
	print("Defensa adicional actualizada: ", additional_defense)

#endregion

#region --Funciones de ataque--
func _to_attack() -> void:
	parent.current_state = parent.STATES.ATTACK
	parent._activated_pages(parent.STATES.ATTACK)
	for i in range(parent.gridbtn.size()):
		var btn  = parent.gridbtn[i]
		var c_page = i + (4 * parent.page)
		if c_page < parent.attack_options.size():
			var attack = parent.attack_options[c_page]
			btn.text = attack.name[chosen_lang]
			btn.disabled = false
		else:
			btn.text = "---"
			btn.disabled = true

func _damage_enemy(id: int) -> void:
	print("ID del ataque seleccionado: ", id)
	var index: int = id - 1 + (4 * parent.page)

	if index < parent.attack_options.size():
		var chosen_attack: AttackDB = parent.attack_options[index]
		_apply_damage(main.current_enemy, chosen_attack, "player")

	parent.end_turn.emit()

func _apply_damage(target: Variant, attack: AttackDB, attacker: Variant = "", slot: SlotDB = null) -> void:
	var raw_damage = attack.get_damage()
	var attacker_strength: int

	if attacker is MonsterDB:
		attacker_strength = attacker.strength
	else:
		attacker_strength = GameMaster.stats.get("strength", 0) 
	print("Daño bruto: ", raw_damage, " Atacante: ", attacker.entity_name[GameMaster.config["lang"]] if is_instance_of(attacker, MonsterDB) else "Player" , " Objetivo: ", target.entity_name[GameMaster.config["lang"]] if is_instance_of(target, MonsterDB) else "Player", " Fuerza del atacante: ", attacker_strength)

	var float_damage = raw_damage * (1.0 + (attacker_strength/100.0))
	var total_damage = roundi(float_damage)
	var damage_received: int = 0
	print("Daño total calculado: ", total_damage, " Daño calculado: ", float_damage)

	if target is MonsterDB:
		damage_received = maxi(total_damage - target.defense, 0)
		target.life -= damage_received
		print("Daño emitido: ", damage_received, " Vida Restante: ", target.life, " Objetivo: ", target.entity_name[GameMaster.config["lang"]])
		if slot != null:
			translator.add_text_to_array_for_enemy(slot, damage_received, attack.type)

	else:
		var player_def = GameMaster.stats.get("endurance", 0)
		damage_received = maxi(total_damage - player_def, 0)
		if not additional_defense.is_empty():
			damage_received = maxi(damage_received - additional_defense[0], 0)
			additional_defense.pop_front()
		GameMaster.life -= damage_received
		print("Daño recibido: ", damage_received, " Vida Restante: ", GameMaster.life, " Player")

	GameMaster.emit_signal("player_action")
#endregion

#region --Funciones de Item--
func _to_item() -> void:
	parent.current_state = parent.STATES.ITEM
	parent._activated_pages(parent.STATES.ITEM)
	for i in range(parent.gridbtn.size()):
		var btn = parent.gridbtn[i]
		var c_page = i + (4 * parent.page)
		if c_page < parent.item_options.size():
			var item = parent.item_options[c_page]
			btn.text = item.name[chosen_lang]
			btn.disabled = false
		else:
			btn.text = "---"
			btn.disabled = true
#endregion
