extends Control

@onready var selector := $Selector
@onready var grid := $GridContainer
var attack_options:= ["Punch"]
var defense_options:= ["Arm Cover"]
var special_options:= []
var item_options:= []

func _ready() -> void:
	
	_prepare_buttons()

func _prepare_buttons():
	for btn in grid.get_children():
		var extend = btn.get_meta("id")
		if not btn.pressed.is_connected(pressed_button):
			btn.pressed.connect(pressed_button.bind(extend))

func pressed_button(id: int):
	pass
