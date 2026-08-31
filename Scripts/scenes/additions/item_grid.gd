class_name ItemGrid extends GridContainer

@export var dimensions: Vector2i = Vector2i(1, 1)
var slot_size: Vector2
var cell_data: Array[Node] = []
var held_item_intersect: bool = false

func _ready() -> void:
	GameMaster.system_config["slot_size"] = custom_minimum_size
	create_slots()
	init_cell_data()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			# print("Presión sentida")
			var held_item = get_tree().get_first_node_in_group("held_item") as ItemScene

			if !held_item:
				var slot_idx = get_slot_idx_from_cords(get_local_mouse_position())
				print("slot_index: ", slot_idx)
				var item = cell_data[slot_idx]
				if !item:
					# print("No hay objeto")
					return
				item.get_picked()
				clear_slots_from_item(item)
			else:
				if !held_item_intersect: return

				var offset = slot_size / 2

				var local_pos = (held_item.anchor_point + offset) - global_position
				var idx = get_slot_idx_from_cords(local_pos)
				if idx < 0: return

				var items = item_in_area(idx, held_item.data.dimensiones)

				if items.size():
					if items.size() == 1:
						held_item.place(get_cords_from_idx(idx))
						print("index: ", idx," Index cords: ", get_cords_from_idx(idx))
						clear_slots_from_item(items[0])
						add_item_to_cell_data(idx, held_item)
						items[0].get_picked()
					return

				held_item.place(get_cords_from_idx(idx))
				add_item_to_cell_data(idx, held_item)

	if event is InputEventMouseMotion:
		var held_item = get_tree().get_first_node_in_group("held_item")
		if held_item:
			detect_intersect(held_item)

func detect_intersect(held_item: ItemScene) -> void:
	var h_rect = Rect2(held_item.anchor_point, held_item.texture_size)
	var g_rect = Rect2(global_position, size)
	var inter = h_rect.intersection(g_rect).size
	held_item_intersect = (inter.x * inter.y) / (held_item.texture_size.x * held_item.texture_size.y) > 0.8

func clear_slots_from_item(item: Node) -> void:
	for i in cell_data.size():
		if cell_data[i] == item:
			cell_data[i] = null

func add_item_to_cell_data(idx: int, item: ItemScene) -> void:
	for y in item.data.dimensiones.y:
		for x in item.data.dimensiones.x:
			cell_data[idx + x + y * columns] = item	

func item_in_area(idx: int, item_dimensions: Vector2i) -> Array:
	var items: Dictionary = {}
	for y in item_dimensions.y:
		for x in item_dimensions.x:
			var slot_idx = idx + x + y * columns
			var item = cell_data[slot_idx]
			if !item:
				continue
			if !items.has(item):
				items[item] = true
	return items.keys() if items.size() else []

func create_slots() -> void:
	if dimensions.y <= 0 or dimensions.x <= 0:
		print("Marque unas dimensiones correctas.") # Code error 0x01 
		queue_free()
		return

	columns = dimensions.x
	var count = dimensions.y * dimensions.x
	for i in count:
		var invSlot: ColorRect = ColorRect.new()
		invSlot.color = Color.DIM_GRAY
		invSlot.custom_minimum_size = custom_minimum_size
		invSlot.size = custom_minimum_size
		invSlot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(invSlot)
		var decoSpot: ColorRect = ColorRect.new()
		decoSpot.color = Color.WHITE
		var inner_size = custom_minimum_size - Vector2(4,4)
		decoSpot.custom_minimum_size = inner_size; decoSpot.size = inner_size
		decoSpot.position = Vector2 (2, 2)
		decoSpot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		invSlot.add_child(decoSpot)

	slot_size = custom_minimum_size
	slot_size.y += get_theme_constant("v_separation")
	slot_size.x += get_theme_constant("h_separation")

func init_cell_data() -> void:
	cell_data.resize(dimensions.x * dimensions.y)
	cell_data.fill(null)

func attempt_to_add_item(item: ItemScene) -> bool:
	var slot_idx: int = 0
	while slot_idx < cell_data.size():
		if item_fits(slot_idx, item.data.dimensiones):
			break
		slot_idx += 1
	if slot_idx >= cell_data.size():
		return false
	for y in item.data.dimensiones.y:
		for x in item.data.dimensiones.x:
			cell_data[slot_idx + x + y * columns] = item

	item.set_initial_point(get_cords_from_idx(slot_idx))
	GameMaster.inventory["positions"] = cell_data
	return true

func item_fits(idx: int, dimension: Vector2i) -> bool:
	for y in dimension.y:
		for x in dimension.x:
			var curr_idx = idx + x + y * columns
			if curr_idx >= cell_data.size():
				return false
			if cell_data[curr_idx] != null:
				return false
			@warning_ignore("integer_division")  var split = idx / columns != (idx + x) / columns
			if split:
				return false
	return true

func get_slot_idx_from_cords(local_mouse_pos: Vector2) -> int:
	if local_mouse_pos.x < 0 or local_mouse_pos.y < 0:
		return -1
	var cell_x: int = int(local_mouse_pos.x / slot_size.x)
	var cell_y: int = int(local_mouse_pos.y / slot_size.y)
	print("cords: ", Vector2i(cell_x, cell_y))
	if cell_x >= dimensions.x or cell_y >= dimensions.y:
		return -1
	var idx: int = cell_x + (cell_y * columns)
	return idx

func get_cords_from_idx(idx: int) -> Vector2i:
	print("child: ", get_child(idx), ". position: ", get_child(idx).global_position)
	return Vector2i(get_child(idx).global_position)
