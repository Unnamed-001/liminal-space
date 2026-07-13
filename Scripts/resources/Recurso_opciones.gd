extends Resource
class_name OptionDB

enum OptionResult { STAGE_TRANSITION, GIVE_ITEM, EVENT_TRIGGER, AI_FALLBACK }

@export_category("Identification")
@export_range(1, 18, 1) var id: int = 1 

@export_group("Texto")
@export var name: Dictionary[String, String] = {
    "ES_CL": "",
    "EN_US": ""
}

@export_category("Resultado")
@export var result: OptionResult = OptionResult.STAGE_TRANSITION
@export var target_stage: StageDB
@export var target_item: ItemDB
@export var target_event: String = "WIP"