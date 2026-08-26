class_name ItemScene extends AnimatedSprite2D

var data: ItemDB = null
var is_picked: bool = false
var size: Vector2:
	get():
		return Vector2(data.dimensiones.x, data.dimensiones.y) * GameMaster.system_config["slot_size"]
var anchor_point: Vector2:
	get():
		return global_position - size/2

func _ready() -> void:
	if data:
		sprite_frames = data.image

func set_initial_point(pos: Vector2) -> void:
	global_position = pos + size / 2
	anchor_point = global_position - size/2

func _process(delta: float) -> void:
	if is_picked:
		global_position = get_global_mouse_position()

func get_picked() -> void:
	add_to_group("held_item")
	is_picked = true
	z_index = 2
	anchor_point = global_position - size / 2

func place(pos: Vector2i) -> void:
	is_picked = false
	global_position = pos + Vector2i(size / 2)
	z_index = 0
	anchor_point = global_position - size / 2
	remove_from_group("held_item")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			if is_picked:
				rotate_item()

func rotate_item() -> void:
	data.is_rotated = !data.is_rotated
	data.dimensiones = Vector2i(data.dimensiones.y, data.dimensiones.x)
	var tween := create_tween()
	tween.tween_property(self, "rotation_degrees", 90 if data.is_rotated else 0, 0.3)
	await tween.finished
	tween.kill()
	anchor_point = global_position - size / 2
