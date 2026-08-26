class_name mainInventory extends Control

@onready var itemGrid: ItemGrid = $CenterContainer/Inventory/ItemGrid

func get_slot_idx_from_cords(local_mouse_pos: Vector2) -> void:
	itemGrid.get_slot_idx_from_cords(local_mouse_pos)

func get_cords_from_idx(idx: int) -> void:
	itemGrid.get_cords_from_idx(idx)

func attempt_to_add_item(item: ItemDB) -> bool:
	var itemScene: PackedScene = load("res://Escenas/additions/item_scene.tscn").duplicate()
	var itemNode: ItemScene = itemScene.instantiate()
	itemNode.data = item
	itemGrid.add_child(itemNode)
	GameMaster.inventory["items"].append(item)

	if itemGrid.attempt_to_add_item(itemNode):
		return true
	else:
		itemNode.queue_free()
		return false