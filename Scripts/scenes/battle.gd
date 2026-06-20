extends Control

enum STATES { MAIN, ATTACK, DEFENSE, ITEM, SPECIAL }

signal end_turn

@onready var selector := $Selector
@onready var gridbtn: Array[Button]
@onready var chosen_lang: String = GameMaster.config["lang"]
var current_state: STATES = STATES.MAIN
var page: int = 0
var current_enemy: MonsterDB

var enemies: Array[MonsterDB] = []
var attack_options:= [load("res://Recursos/Ataque/punch.tres")]
var defense_options:= [load("res://Recursos/Defensa/cover_arms.tres")]
var special_options:= []
var item_options:= []

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
			pass

func press_handler(id: int) -> void:
	match id:
		1:
			print("Attack_mode")
			_to_attack()
		2:
			print("Defense_mode")
			current_state = STATES.DEFENSE
		3:
			print("Item_mode")
			current_state = STATES.ITEM
		4:
			print("Special_mode")
			current_state = STATES.SPECIAL

func _to_attack() -> void:
	current_state = STATES.ATTACK
	
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
		var chosen_attack = attack_options[index]
		_apply_damage(current_enemy, chosen_attack)
		_restore_menu_state()

func _monsters_turn() -> void:
	for monster in enemies:
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
			print(monster.name[lang], " usó ", chosen_atk.name[lang])

			_apply_damage(monster, chosen_atk)

		await get_tree().create_timer(chosen_atk.wait_time).timeout

	print("Es el turno del jugador.")
	_restore_menu_state()

func _apply_damage(target: Variant, attack: AttackDB, attacker: Variant = "") -> void:
	var raw_damage = attack.get_damage()
	var attacker_strength: int
	
	if attacker is MonsterDB:
		attacker_strength = attacker.strength
	else:
		attacker_strength = GameMaster.stats.get("strength", 0)
	
	var float_damage = raw_damage * (1.0 + (attacker_strength/100.0))
	var total_damage = roundi(float_damage)
	
	var damage_received: int = 0
	
	if target is MonsterDB:
		damage_received = maxi(total_damage - target.defense, 0)
		target.life -= damage_received
		emit_signal("end_turn")
	else:
		var player_def = GameMaster.stats.get("endurance", 0)
		damage_received = maxi(total_damage - player_def, 0)
		GameMaster.life -= damage_received

#region --Funciones auxiliares--
func _ready() -> void:
	for child in $GridContainer.get_children():
		if child.is_class("Button"):
			gridbtn.append(child)
	end_turn.connect(Callable(self, "_monsters_turn"))
	_prepare_buttons()

func _restore_menu_state() -> void:
	current_state = STATES.MAIN

	btn1.text = "ATACAR"
	btn2.text = "DEFENDER"
	btn3.text = "OBJETO"
	btn4.text = "ESPECIAL"

	for btn in gridbtn:
		btn.disabled = false

func update_active_buttons(available: Array[int]) -> void:
	for btn in gridbtn:
		var my_id = btn.get_meta("id")
		btn.disabled = not available.has(my_id)

func _prepare_buttons() -> void:
	for btn in gridbtn:
		var extend = btn.get_meta("id")
		if not btn.pressed.is_connected(_pressed_button):
			btn.pressed.connect(_pressed_button.bind(extend))
#endregion
