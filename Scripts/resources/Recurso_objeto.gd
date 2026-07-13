extends Resource
class_name ItemDB
## Tipo de objeto

enum Type { HUNGER, THIRST, POTION, HEAL, DEFENSE, ARMOR }

## Nombre del objeto
@export var name: Dictionary[String, String] = {
	"ES_CL": "",
	"EN_US": ""
}
## Coste del objeto en el mercado, o lo que llegue a añadir
@export_range(-1, 100, 1, "or_greater") var value: int = 0 
## Descripción del objeto dentro del inventario
@export var Description: Dictionary[String, String] = {
	"ES_CL": "",
	"EN_US": ""
}
## Tipo de objeto e intensidad de la ayuda/efecto
@export var type: Dictionary[Type, int] = {}
## Como saldrá cuando se recoja. Se permite formato {Name} {value_type} {type} (Escoger uno de los disponibles)
@export var advices: Dictionary[String, String] = {
	"ES_CL": "",
	"EN_US": ""
}
## ¿Es un objeto consumible?
@export var consumable: bool = true
## Mensaje al consumir el objeto
@export var consume_message: Dictionary[String, String] = {
	"ES_CL": "",
	"EN_US": ""
}
