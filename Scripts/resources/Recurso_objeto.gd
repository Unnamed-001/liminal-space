extends Resource
class_name ItemDB ## Tipo de objeto

enum Type { HUNGER, THIRST, POTION, HEAL, DEFENSE, ARMOR }

@export_category("Info")
@export var name: Dictionary[String, String] = {
	"ES_CL": "",
	"EN_US": ""
}## Nombre del objeto
@export var image: Texture2D = null ## Imagen del texto
@export_range(-1, 100, 1, "or_greater") var value: int = 0 ## Coste del objeto en el mercado, o lo que llegue a añadir
@export var Description: Dictionary[String, String] = {
	"ES_CL": "",
	"EN_US": ""
} ## Descripción del objeto dentro del inventario
@export_category("Efectos")
@export var type: Dictionary[Type, int] = {} ## Tipo de objeto e intensidad de la ayuda/efecto
@export var advices: Dictionary[String, String] = {
	"ES_CL": "",
	"EN_US": ""
} ## Como saldrá cuando se recoja. Se permite formato {Name} {value_type} {type} (Escoger uno de los disponibles)
@export var consumable: bool = true ## ¿Es un objeto consumible?
@export var consume_message: Dictionary[String, String] = {
	"ES_CL": "",
	"EN_US": ""
} ## Mensaje al consumir el objeto
