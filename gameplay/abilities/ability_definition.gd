class_name AbilityDefinition
extends Resource

enum CastType { TARGETED, POINT, AREA, SELF }

@export var ability_id: StringName
@export var display_name: String = "Ability"
@export var cast_type: CastType = CastType.TARGETED
@export_range(0.0, 1000.0, 0.1) var mana_cost: float = 0.0
@export_range(0.0, 300.0, 0.1) var cooldown: float = 0.0
@export_range(0.0, 100.0, 0.1) var cast_range: float = 0.0
@export var effect: AbilityEffect
