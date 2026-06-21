extends Control

enum ACTION { ATTACK, DEFENSE, ITEM, SPECIAL }
enum STATES { MAIN, ATTACK, DEFENSE, ITEM, SPECIAL }

signal end_turn

#region --Nodos--
@onready var selector:= $Selector
@onready var gridbtn: Array[Button]
@onready var chosen_lang: String = GameMaster.config["lang"]
@onready var main: Control = $".."
@onready var child_btn
#endregion
var current_state: STATES = STATES.MAIN
var total: int = 0
var page: int = 0
var additional_defense: Array[float] = [0.0]

var attack_options: Array[AttackDB] = [load("res://Recursos/Ataque/punch.tres")]
var defense_options: Array[DefenseDB] = [load("res://Recursos/Defensa/cover_arms.tres")]
var item_options: Array[ItemDB] = []
var special_options: Array[Resource] = []


@onready var btn1: Button = $GridContainer/Button1
@onready var btn2: Button = $GridContainer/Button2
@onready var btn3: Button = $GridContainer/Button3
@onready var btn4: Button = $GridContainer/Button4

func _pressed_button(id: int) -> void:
	match current_state:
		STATES.MAIN:
			press_handler(id)
		STATES.ATTACK:
			_damage_enemy(id)
		STATES.DEFENSE:
			_defend_yourself(id)

func press_handler(id: int) -> void:
	match id:
		1:
			print("Attack_mode")
			_to_attack()
		2:
			print("Defense_mode")
			_to_defense()
		3:
			print("Item_mode")
			current_state = STATES.ITEM
		4:
			print("Special_mode")
			current_state = STATES.SPECIAL
	selector.visible = true

func _monsters_turn() -> void:
	for btn in gridbtn:
		btn.text = "Waiting..."
		btn.disabled = true

	for monster: MonsterDB in main.enemies:
		var total_weight: float = 0.0
		for attack in monster.possible_attacks:
			total_weight += monster.possible_attacks[attack]
		
		var rng = randf_range(0.0, total_weight)
		var chosen_atk: AttackDB = null
		var current_weight: float = 0
		
		for attack in monster.possible_attacks:
			current_weight += monster.possible_attacks[attack]
			if rng <= current_weight:
				chosen_atk = attack
				break

		if chosen_atk != null:
			var lang = GameMaster.config["lang"]
			print(monster.entity_name[lang], " usó ", chosen_atk.name[lang])

			_apply_damage("player", chosen_atk, monster)

		await get_tree().create_timer(chosen_atk.wait_time).timeout

	print("Es el turno del jugador.")
	_restore_menu_state()

#region --Funciones de defensa--
func _to_defense() -> void:
	current_state = STATES.DEFENSE
	_activated_pages(ACTION.DEFENSE)
	for i in range(gridbtn.size()):
		var btn = gridbtn[i]
		var btn_page = i + (4 * page)
		if btn_page < defense_options.size():
			var defense = defense_options[btn_page]
			btn.text = defense.name[chosen_lang]
			btn.disabled = false
		else:
			btn.text = "---"
			btn.disabled = true

func _defend_yourself(id: int) -> void:
	var index: int = id - 1 + (4 * page)
	if index < defense_options.size():
		var chosen_defense = defense_options[index]
		_apply_defense(chosen_defense)
		emit_signal("end_turn")

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
	current_state = STATES.ATTACK
	_activated_pages(ACTION.ATTACK)
	for i in range(gridbtn.size()):
		var btn  = gridbtn[i]
		var c_page = i + (4 * page)
		if c_page < attack_options.size():
			var attack = attack_options[c_page]
			btn.text = attack.name[chosen_lang]
			btn.disabled = false
		else:
			btn.text = "---"
			btn.disabled = true

func _damage_enemy(id: int) -> void:
	var index: int = id - 1 + (4 * page)
	
	if index < attack_options.size():
		var chosen_attack: AttackDB = attack_options[index]
		_apply_damage(main.current_enemy, chosen_attack, "player")
		emit_signal("end_turn")

func _apply_damage(target: Variant, attack: AttackDB, attacker: Variant = "") -> void:
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
	current_state = STATES.ITEM
	_activated_pages(ACTION.ITEM)
	for i in range(gridbtn.size()):
		var btn = gridbtn[i]
		var c_page = i + (4 * page)
		if c_page < item_options.size():
			var item = item_options[c_page]
			btn.text = item.name[chosen_lang]
			btn.disabled = false
		else:
			btn.text = "---"
			btn.disabled = true
#endregion

#region --Funciones auxiliares--
func _ready() -> void:
	for child in $GridContainer.get_children():
		if child.is_class("Button"):
			gridbtn.append(child)
	end_turn.connect(_monsters_turn)
	await get_tree().physics_frame

	child_btn = selector.find_children("*", "Button", true)
	for btn in child_btn:
		if btn.is_class("Button"):
			if btn.get_meta("page"):
				btn.disabled = true
				btn.get_parent().modulate.a = 0.0 
	_prepare_buttons()

func _restore_menu_state() -> void:
	current_state = STATES.MAIN

	btn1.text = "ATACAR"
	btn2.text = "DEFENDER"
	btn3.text = "OBJETO"
	btn4.text = "ESPECIAL"

	for btn in gridbtn:
		btn.disabled = false

	selector.visible = false

func update_active_buttons(available: Array[int]) -> void:
	for btn in gridbtn:
		var my_id = btn.get_meta("id")
		btn.disabled = not available.has(my_id)

func _prepare_buttons() -> void:
	for btn in gridbtn:
		var extend = btn.get_meta("id")
		if not btn.pressed.is_connected(_pressed_button):
			btn.pressed.connect(_pressed_button.bind(extend))

func _activated_pages(act: ACTION) -> void:
	total = 0
	match act:
		ACTION.ATTACK:
			if attack_options.size() > 4:
				total = ceil(attack_options.size() / 4.0) - 1
		ACTION.DEFENSE:
			if defense_options.size() > 4:
				total = ceil(defense_options.size() / 4.0) - 1
		ACTION.ITEM:
			if item_options.size() > 4:
				total = ceil(item_options.size() / 4.0) - 1
		ACTION.SPECIAL:
			if special_options.size() > 4:
				total = ceil(special_options.size() / 4.0) - 1

	if total >= 1:
		for btn in child_btn:
			if btn.is_class("Button"):
				if btn.get_meta("page"):
					btn.disabled = false
					btn.get_parent().modulate.a = 1.0
	else:
		for btn in child_btn:
			if btn.is_class("Button"):
				if btn.get_meta("page"):
					btn.disabled = true
					btn.get_parent().modulate.a = 0.0 

func _next_page() -> void:
	if page < total - 1:
		page += 1
	else:
		page = 0

func _previous_page() -> void:
	if page > 0:
		page -= 1
	else:
		page = total - 1
#endregion
