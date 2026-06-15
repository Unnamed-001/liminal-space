extends Control


func _on_start_pressed() -> void:
	var tween = create_tween()
	tween.tween_property($Flash, "color", Color(1,1,1,1), 1.0).set_ease(Tween.EASE_IN)
	await tween.finished
	get_tree().change_scene_to_file("res://Escenas/MainGame.tscn")

func _on_quit_pressed() -> void: get_tree().quit()
