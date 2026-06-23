extends Resource
class_name SlotDB

@export var action: ActionDB
@export_range(0.0, 100.0, 1.0) var probability: float = 1.0

@export_category("dialogue")
@export var dialogue: Dictionary[String, Array] = {
	"ES_CL": ["", "", ""],
	"EN_US": ["", "", ""]
}
