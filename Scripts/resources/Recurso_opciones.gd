extends Resource
class_name OptionDB

enum OptionResult { STAGE_TRANSITION, GIVE_ITEM, EVENT_TRIGGER, AI_FALLBACK }

@export_category("Identification")
@export_range(1, 18, 1) var id: int = 1 ## Donde se coloca la opción

@export_group("Texto")
@export var name: Dictionary[String, String] = {
    "ES_CL": "",
    "EN_US": ""
} ## Nombre de la opción

@export_category("Resultado")
@export var result: OptionResult = OptionResult.STAGE_TRANSITION ## Tipo de resultado
@export var target_stage: StageDB ## Si es una transición a otro escenario, carga el escenario aquí
@export var target_item: ItemDB ## Si es una obtención de un objeto, carga el objeto aquí.
@export var target_event: String = "WIP" ## WIP