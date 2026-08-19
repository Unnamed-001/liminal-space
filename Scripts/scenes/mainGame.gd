extends Control
class_name MainGame
const max_turns: int = 5
const min_probability: float = 10

@onready var cRect = $ColorRect
@onready var grid = $buttons/GridContainer
@onready var info = $Info
@onready var status = $Status
@onready var translator: MainTranslator = $stage

var enemies: Array[MonsterDB] = [] ## Enemigos activos actualmente
var current_enemy: MonsterDB ## Objetivo
var active_ids: Array[int] = [] ## Botones disponibles
var current_stage: StageDB = load("res://Recursos/Escenarios/start.tres") ## Escenario actual

var combat_probability: float = min_probability
var flag_combat: bool = false ## Esta en combate

func _ready() -> void:
	#region --Animacion de inicio--
	cRect.visible = true
	cRect.color = Color.WHITE
	var tween = create_tween()
	tween.tween_property(cRect, "color", Color(0.294, 0.294, 0.294, 0.0), 1.0).set_ease(Tween.EASE_IN)
	#endregion
	#region --Signal connection--
	GameMaster.player_action.connect(Callable(self, "update_status"))
	translator.update_stage(current_stage)
	_prepare_buttons()
	update_status()
	#endregion

#region --Output Func--

func _prepare_buttons():
	for btn in grid.get_children():
		var my_id = btn.get_meta("id")
		# print(str(my_id))
		if not btn.pressed.is_connected(pressed_button):
			btn.pressed.connect(pressed_button.bind(my_id))

func pressed_button(id: int) -> void:
	if not active_ids.has(id):
		print("llamada bloqueada.")
		return
	GameMaster.player_action.emit()

	for action in current_stage.actions:
		if action.id == id:
			match action.result:
				OptionDB.OptionResult.STAGE_TRANSITION:
					if action.target_stage:
						current_stage = action.target_stage
						translator.update_stage(current_stage, GameMaster.config["lang"])
					else:
						printerr("Error: No se ha definido un escenario de destino para la opción seleccionada.")

				OptionDB.OptionResult.GIVE_ITEM:
					if action.target_item:
						translator.add_object(action.target_item)
						GameMaster.inventory.append(action.target_item)

						current_stage.actions.erase(action)
						active_ids.erase(id)
						update_active_buttons(active_ids)
					else:
						printerr("Error: No se ha definido un item de destino para la opción seleccionada.")

				OptionDB.OptionResult.EVENT_TRIGGER:
					pass # WIP

				OptionDB.OptionResult.AI_FALLBACK:
					pass # WIP
			break

	print("Boton presionado: " + str(id))
	update_status()
#endregion

#region --Input Func--
func update_status() -> void:
	$Status/BARS/LIFE.value = GameMaster.life
	$Status/BARS/CORD.value = GameMaster.cord
	$Status/BARS/HUNGER.value = GameMaster.hunger
	$Status/BARS/THIRST.value = GameMaster.thirst

	_update_current_zone()

func update_active_buttons(IDs: Array[int]) -> void:
	active_ids = IDs
	for btn in grid.get_children():
		var my_id = btn.get_meta("id")
		if active_ids.has(my_id):
			btn.disabled = false
			btn.modulate.a = 1.0
		else:
			btn.disabled = true
			btn.modulate.a = 0.0

func button_helper(input: Dictionary) -> void:
	for btn in grid.get_children():
		var my_id = btn.get_meta("id")
		if input.has(my_id):
			var actions_text_dict = input[my_id]
			btn.text = actions_text_dict

#endregion
#region --Stage Func--
func _update_current_zone() -> void:
	var csse: Dictionary[GM.special_case, int] = current_stage.special_event
	var rng: float = randi_range(0, 100)
	var enabled: bool = true

	GameMaster.current_zone = current_stage.id_zone

	if GameMaster.last_zone != GameMaster.current_zone:
		GameMaster.last_zone = GameMaster.current_zone
		GameMaster.turn = 0
	else:
		GameMaster.turn += 1

	if csse.has(GM.special_case.NONE):
		combat_probability = min_probability
		enabled = false

	if csse.has(GM.special_case.DANGER_ZONE) and enabled:
		combat_probability = min(combat_probability + csse[GM.special_case.DANGER_ZONE], 100)

	if csse.has(GM.special_case.RESTRICTED_AREA) and enabled:
		pass # no se que añadir aquí

	if csse.has(GM.special_case.POISON_AREA) and enabled:
		GameMaster.life = maxi(0, GameMaster.life - csse[GM.special_case.POISON_AREA])

	if csse.has(GM.special_case.DRAINING_AREA) and enabled:
		GameMaster.thirst = maxi(0, GameMaster.thirst - csse[GM.special_case.DRAINING_AREA] * 2)
		GameMaster.hunger = maxi(0, GameMaster.hunger - csse[GM.special_case.DRAINING_AREA])

	if csse.has(GM.special_case.SECURE_ZONE) and enabled:
		combat_probability = -1

	if rng < combat_probability:
		combat()
#endregion
#region --Combat--
func combat() -> void:
	GameMaster.update_enemies_from_context(current_stage)

	# Limpiar lista previa de enemigos
	enemies.clear()

	var total_weight := 0.0
	var max_enemies = GameMaster.max_enemies

	if GameMaster.valid_pool_stable.is_empty():
		print("No hay enemigos configurados para este escenario.")
		return
	
	# 1. Calculamos el peso total una sola vez
	for enemy in GameMaster.valid_pool_stable:
		total_weight += GameMaster.valid_pool_stable[enemy]

	if total_weight <= 0.0:
		print("Peso total de enemigos es cero.")
		return
	
	# 2. Decidimos cuántos enemigos habrá en total
	var rng_count = randi_range(1, max_enemies)

	# 3. Hacemos un "tiro de dados" INDEPENDIENTE por cada enemigo que necesitamos
	for i in range(rng_count):
		var rng_monster = randf_range(0.0, total_weight)
		var current_weight := 0.0
		
		for enemy in GameMaster.valid_pool_stable:
			current_weight += GameMaster.valid_pool_stable[enemy]
			if rng_monster <= current_weight:
				# Duplicamos el recurso para que tenga su propia vida
				enemies.append(enemy.duplicate())
				break

	if enemies.size() == 0:
		print("No se pudieron generar enemigos.")
		return

	translator.start_combat()
	var size_viewport = get_viewport_rect().size.y
	if not flag_combat:
		current_enemy = enemies[0]
		info.position.y += size_viewport
		status.position.y += size_viewport
		$Camera2D.position.y += size_viewport
		flag_combat = true
		$Info.show_enemy_status()
		$Battle/RichTextLabel.start_combat()
	else:
		info.position.y -= size_viewport
		status.position.y -= size_viewport
		$Camera2D.position.y -= size_viewport
		flag_combat = false
		$Info.hide_enemy_status()
#endregion
