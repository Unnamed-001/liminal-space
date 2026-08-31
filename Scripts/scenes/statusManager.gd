class_name StatusManager extends Control

@onready var character = $CHARACTER
@onready var lifeBar: TextureProgressBar = $BARS/LIFE
@onready var cordBar: TextureProgressBar = $BARS/CORD
@onready var hungerBar: TextureProgressBar = $BARS/HUNGER
@onready var thirstBar: TextureProgressBar = $BARS/THIRST
@onready var camera: Camera2D = $"..".get_node("Camera2D")

var marks: Node2D
var main_game: MainGame
var pause_menu: PauseMenu

func _ready() -> void:
	var x = get_tree().get_first_node_in_group("MAIN")
	if x is MainGame:
		main_game = x
		marks = main_game.get_node("marks")
		pause_menu = main_game.get_node("PauseMenu")


func _show_stats() -> void: ## Muestra las estadísticas del jugador
	var statsLabel = $stats as RichTextLabel
	statsLabel.visible = !statsLabel.visible

	if statsLabel.visible:
		# Atenuar el fondo
		character.modulate.a = 0.2
		lifeBar.modulate.a = 0.2
		cordBar.modulate.a = 0.2
		var formatted_text = "Estadísticas Actuales:\n\n"

		for stat_key in GameMaster.stats:
			var stat_value = GameMaster.stats[stat_key]
			# .capitalize() convierte "velocity" en "Velocity" automáticamente
			formatted_text += "- " + stat_key.capitalize() + ": " + str(stat_value) + "\n"

		statsLabel.text = formatted_text

	else:
		# Restaurar la opacidad al cerrar
		character.modulate.a = 1.0
		lifeBar.modulate.a = 1.0
		cordBar.modulate.a = 1.0

func _show_inventory() -> void: ## Muestra el inventario del jugador
	var inventory_pos: Marker2D = marks.get_node("inventoryPos"); var home_pos: Marker2D = marks.get_node("homePos")
	# print("Ubicación inventario: ", Vector2i(inventory_pos.global_position), " Ubicación casa: ", Vector2i(home_pos.global_position))
	

	if camera.global_position.distance_to(inventory_pos.global_position) < 5.0:
		camera.global_position = home_pos.global_position
		print("A casa. Ubicación actual: ", Vector2i(camera.global_position), " Ubicación inventario: ", Vector2i(inventory_pos.global_position))
		global_position.y = home_pos.global_position.y - size.y / 2
	else: 
		camera.global_position = inventory_pos.global_position
		global_position.y = inventory_pos.global_position.y - size.y / 2
		print("Al inventario. Ubicación actual: ", Vector2i(camera.global_position), " Ubicación inventario: ", Vector2i(inventory_pos.global_position))

func _show_pause_menu() -> void:
	pause_menu.show_menu()
