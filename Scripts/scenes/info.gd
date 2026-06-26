extends Control

@onready var main: MainGame = $".."
@onready var enemy_selector: HBoxContainer = $Enemy_selector
@onready var bars: VBoxContainer = $Bars

# Guardamos la posición local, no la global, para evitar bugs si se mueve la ventana
var home_pos: Vector2 
var index: int = 0
var lifes: Dictionary[MonsterDB, Array] = {} # Identificador de vida total de cada enemigo, para evitar que si se cambia y se devuelva tener la barra completa


func _ready() -> void:
	# Guardamos la posición original al cargar la escena
	home_pos = bars.position 
	
	# Sintaxis limpia y moderna de Godot 4 para conectar señales
	GameMaster.player_action.connect(update_status)
	GameMaster.connect("clean_resource", _on_clean_resource)

func show_enemy_status() -> void:
	print("Mostrando estado del enemigo: ", main.current_enemy.entity_name, ". Enemigos en la batalla: ", main.enemies.size())
	var enemy_names: Array[String] = []
	for enemy: MonsterDB in main.enemies:
		enemy_names.append(enemy.entity_name[GameMaster.config["lang"]])
	print("Enemigos: ", enemy_names)
	bars.visible = true

	for enemy: MonsterDB in main.enemies:
		if not lifes.has(enemy):
			lifes[enemy] = [enemy.life, enemy.cord]

	if main.enemies.size() > 1:
		enemy_selector.visible = true
		bars.position.y = home_pos.y + enemy_selector.size.y
	else:
		enemy_selector.visible = false
		bars.position = home_pos
	update_status()

func hide_enemy_status() -> void:
	lifes.clear()
	enemy_selector.visible = false
	bars.position = home_pos
	bars.visible = false

func update_status() -> void:
	if main.current_enemy:
		bars.get_node("LIFE").max_value = lifes[main.current_enemy][0]
		bars.get_node("LIFE").value = main.current_enemy.life
		if lifes[main.current_enemy][1] <= 0:
			bars.get_node("CORD").visible = false
		else:
			bars.get_node("CORD").visible = true
			bars.get_node("CORD").max_value = lifes[main.current_enemy][1]
			bars.get_node("CORD").value = main.current_enemy.cord

func _on_clean_resource(enemy: MonsterDB) -> void:
	if lifes.has(enemy):
		lifes.erase(enemy)


#region -- Navegación de Enemigos --
func _to_front() -> void:
	if main.enemies.is_empty(): return # Defensa extra por si no hay enemigos
	
	index += 1
	# Si nos pasamos del último enemigo, volvemos al primero (Bucle)
	if index >= main.enemies.size():
		index = 0
		
	main.current_enemy = main.enemies[index]
	print("Cambiado a: ", main.enemies[index].entity_name[GameMaster.config["lang"]])
	update_status() # Llama a actualizar la vista al cambiar de objetivo

func _to_end() -> void:
	if main.enemies.is_empty(): return 
	
	index -= 1
	# Si bajamos de cero, vamos al último enemigo de la lista
	if index < 0:
		index = main.enemies.size() - 1
		
	main.current_enemy = main.enemies[index]
	print("Cambiado a: ", main.enemies[index].entity_name[GameMaster.config["lang"]])
	update_status() # Llama a actualizar la vista al cambiar de objetivo
#endregion
