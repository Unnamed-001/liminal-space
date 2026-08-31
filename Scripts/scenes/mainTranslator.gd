extends RichTextLabel
class_name MainTranslator

const duration: float = 2.5

@onready var main_game: MainGame
@onready var warning: RichTextLabel = $RichTextLabel

# Sinceramente, no se si le pueda encontrar un uso...
# var advices: Array[RichTextLabel] = []

func _ready() -> void:
	var x = get_tree().get_first_node_in_group("MAIN")
	if x is MainGame:
		main_game = x

## Actualiza el texto obteniendo el texto del escenario entregado
func update_stage(stage: StageDB, force_lang: String = "") -> void:
	var current_lang: String = force_lang
	if force_lang.is_empty():
		current_lang = GameMaster.config["lang"] as String

	var langs: Dictionary[String, Array] = stage.get_languages()
	if langs.has(current_lang):
		if langs[current_lang].is_empty():
			print("Parece que se te ha olvidado escribir aquí")
			return
		text = langs[current_lang].pick_random()
	else:
		print("idioma no soportado, cambiando a idioma nativo, ESPAÑOL")
		update_stage(stage, "ES_CL")
		return

	var new_options: Dictionary[int, String] = {}

	for action in stage.actions:
		var possible_action = action.id
		new_options[possible_action] = action.name[current_lang]

	if stage.generated_by_IA:
		GameMaster.last_checkpoint = stage
	GameMaster.current_stage = stage
	main_game.update_active_buttons(new_options.keys())

	main_game.button_helper(new_options)

## Añade un objeto de manera dinámica, busca entre los datos del objeto entregado para entregar el mejor tipo de texto proveniente del objeto 
func add_object(object: ItemDB, lang: String = GameMaster.config["lang"]) -> void:
	var name_obj: String = object.name[lang]
	if name_obj.is_empty():
		name_obj = "[REDACTED]" # BROMITA

	var message: String = object.advices[lang]
	if message.is_empty():
		message = "Haz conseguido un " + name_obj + "!"

	var types_of_effects: Array[ItemDB.Type] = []
	for type in object.type:
		types_of_effects.append(type)

	var format_message: String = message.format({"name": name_obj})
	print(format_message)

	for type in types_of_effects:
		var name_in_minus: String = ItemDB.Type.keys()[type].to_lower()

		if format_message.contains(name_in_minus):
			var effect_value = object.type.get(type, 0) 

			format_message = format_message.format({
				"value_" + name_in_minus: effect_value,
			})

	add_advice(format_message)

## Añade un aviso de manera dinámica. Se borra después de un tiempo determinado
func add_advice(advice: String, lang: String = GameMaster.config["lang"]) -> void:
	var tween: Tween = create_tween()
	var warning_clone = warning.duplicate()
	warning_clone.text = advice
	add_child(warning_clone)
	print("Clon creado")

	var move_time = duration * 0.9
	var wait_time = duration * 0.1

	tween.tween_property(warning_clone, "position", Vector2.UP * 100, move_time).as_relative().set_ease(Tween.EASE_OUT)
	tween.tween_interval(wait_time)
	tween.tween_callback(warning_clone.queue_free)

	print("Clon creado, disparando timer")

func start_combat() -> void:
	pass
