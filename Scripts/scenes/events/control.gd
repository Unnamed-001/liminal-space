class_name EventScene extends Control

var duration: int = 1

func enter_to_event() -> void:
	pass

func update_event() -> void:
	pass

func exit_from_event() -> void:
	if GameMaster.events.find_key(self):
		GameMaster.events.erase(self)