class_name HeroProgression
extends Node

signal progression_changed(level: int, current_xp: float, required_xp: float)
signal level_up(new_level: int)

@export var hero_definition: HeroDefinition
@export_range(0.0, 100.0, 0.5) var xp_radius: float = 10.0
@export_range(1.0, 10000.0, 1.0) var base_xp_to_level: float = 100.0
@export_range(0.0, 10000.0, 1.0) var xp_step_per_level: float = 75.0
var level: int = 1
var current_xp: float = 0.0
var _stats: ActorStats

func _ready() -> void:
	_stats = get_parent().get_node("Stats") as ActorStats

func xp_required() -> float:
	return base_xp_to_level + float(level - 1) * xp_step_per_level

func grant_xp(amount: float) -> void:
	if amount <= 0.0 or not is_instance_valid(_stats) or _stats.current_health <= 0.0 or level >= 6:
		return
	current_xp += amount
	while level < 6 and current_xp >= xp_required():
		current_xp -= xp_required()
		level += 1
		if hero_definition != null:
			_stats.apply_level_growth(hero_definition.health_per_level, hero_definition.mana_per_level, hero_definition.attack_damage_per_level, hero_definition.health_regeneration_per_level, hero_definition.mana_regeneration_per_level)
		level_up.emit(level)
	progression_changed.emit(level, current_xp, xp_required())

func is_in_xp_range(position: Vector3) -> bool:
	return _stats != null and _stats.current_health > 0.0 and get_parent().global_position.distance_to(position) <= xp_radius
