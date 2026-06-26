extends Control
class_name Battle

enum STATES { MAIN, ATTACK, DEFENSE, ITEM, SPECIAL }

signal end_turn
signal start_turn

#region --Nodos--
@onready var selector:= $Selector
@onready var gridbtn: Array[Button] = []
@onready var chosen_lang: String = GameMaster.config["lang"]
@onready var main: MainGame = $".."
@onready var child_btn = []
@onready var logic: BattleLogic = $Logic
@onready var translator: BattleTranslator = $RichTextLabel
#endregion

var current_state: STATES = STATES.MAIN
var total: int = 0
var page: int = 0

var additional_defense: Array[float] = [0.0]

var attack_options: Array[AttackDB] = [load("res://Recursos/Ataque/punch.tres").duplicate()]
var defense_options: Array[DefenseDB] = [load("res://Recursos/Defensa/cover_arms.tres").duplicate()]
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
			logic._damage_enemy(id)
		STATES.DEFENSE:
			logic._defend_yourself(id)

func press_handler(id: int) -> void:
	if main.enemies.is_empty():
		main.combat()
		return
	match id:
		1:
			print("Attack_mode")
			logic._to_attack()
		2:
			print("Defense_mode")
			logic._to_defense()
		3:
			print("Item_mode")
			current_state = STATES.ITEM
		4:
			print("Special_mode")
			current_state = STATES.SPECIAL
	selector.visible = true

func _monsters_turn() -> void:
	for i in range(main.enemies.size() - 1, -1, -1):
		if main.enemies[i].life <= 0:
			main.enemies.remove_at(i)

	for monster: MonsterDB in main.enemies:
		var total_weight: float = 0.0
		for slot in monster.possible_actions:
			total_weight += slot.probability
		
		var rng = randf_range(0.0, total_weight)
		var chosen_atk: AttackDB = null
		var current_weight: float = 0
		var chosen_slot: SlotDB = null

		for slot in monster.possible_actions:
			current_weight += slot.probability
			if rng <= current_weight:
				if slot.action is AttackDB:
					chosen_atk = slot.action
					chosen_slot = slot
				break

		if chosen_atk != null:
			var lang = GameMaster.config.get("lang", "ES_CL")
			print(monster.entity_name.get(lang, "Entidad"), " usó ", chosen_atk.name.get(lang, "Ataque"))

			# Esto solo inyecta el texto en chosen_text de tu Translator
			logic._apply_damage("player", chosen_atk, monster, chosen_slot)

	if not translator.chosen_text.is_empty():
		print("Traduciendo ataques...", Time.get_ticks_msec())
		if translator.is_typing:
			await translator.finish_typing
		else:
			await translator._update()

	# 5. Finalizar el turno
	if main.enemies.is_empty():
		print("¡Has ganado la batalla!")
	
	print("Es el turno del jugador.", Time.get_ticks_msec())
	_restore_menu_state()

#region --Funciones auxiliares--
func _ready() -> void:
	for child in $GridContainer.get_children():
		if child.is_class("Button"):
			gridbtn.append(child)
	end_turn.connect(_monsters_turn)
	await get_tree().physics_frame

	child_btn = selector.find_children("*", "Button", true)
	for btn: Button in child_btn:
		if btn.has_meta("page") and btn.get_meta("page"):
			btn.disabled = true
			btn.get_parent().modulate.a = 0.0 
	_prepare_buttons()

func _restore_menu_state(emit: bool = true) -> void:
	if main.enemies.is_empty():
		for btn in gridbtn:
			btn.text = "Continue" if GameMaster.config["lang"] == "ES_CL" else "Continuar"
			btn.disabled = false
		return

	current_state = STATES.MAIN

	btn1.text = "ATACAR"
	btn2.text = "DEFENDER"
	btn3.text = "OBJETO"
	btn4.text = "ESPECIAL"

	for btn in gridbtn:
		btn.disabled = false

	selector.visible = false
	if emit:
		emit_signal("start_turn")

func update_active_buttons(available: Array[int]) -> void:
	for btn in gridbtn:
		var my_id = btn.get_meta("id")
		btn.disabled = not available.has(my_id)

func _prepare_buttons() -> void:
	for btn in gridbtn:
		var extend = btn.get_meta("id")
		if not btn.pressed.is_connected(_pressed_button):
			btn.pressed.connect(_pressed_button.bind(extend))
			btn.pressed.connect(Callable(logic, "_player_turn"))

func _activated_pages(act: STATES) -> void:
	total = 0
	match act:
		STATES.ATTACK:
			if attack_options.size() > 4:
				total = ceil(attack_options.size() / 4.0) - 1
		STATES.DEFENSE:
			if defense_options.size() > 4:
				total = ceil(defense_options.size() / 4.0) - 1
		STATES.ITEM:
			if item_options.size() > 4:
				total = ceil(item_options.size() / 4.0) - 1
		STATES.SPECIAL:
			if special_options.size() > 4:
				total = ceil(special_options.size() / 4.0) - 1

	if total >= 1:
		for btn in child_btn:
			if btn.is_class("Button"):
				if btn.get_meta("page"):
					btn.disabled = false
					btn.get_parent().modulate.a = 1.0
	else:
		for btn: Button in child_btn:
			if btn.is_class("Button"):
				if btn.has_meta("page") and btn.get_meta("page"):
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
