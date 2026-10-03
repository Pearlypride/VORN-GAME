class_name HeroDefinition
extends Resource
## Small data asset for one playable hero prototype.

@export var hero_name: String = "VORN_TEST_HERO"
@export_range(1.0, 10000.0, 1.0) var max_health: float = 1000.0
@export_range(0.0, 10000.0, 1.0) var max_mana: float = 500.0
@export_range(0.0, 1000.0, 0.1) var health_regeneration: float = 2.0
@export_range(0.0, 1000.0, 0.1) var mana_regeneration: float = 8.0
@export_range(0.0, 1000.0, 0.1) var movement_speed: float = 5.5
@export_range(0.0, 1000.0, 0.1) var attack_damage: float = 20.0
@export_range(0.0, 100.0, 0.1) var attack_range: float = 2.2
@export_range(0.05, 30.0, 0.05) var attack_cooldown: float = 0.8
@export_range(0.0, 10000.0, 1.0) var health_per_level: float = 90.0
@export_range(0.0, 10000.0, 1.0) var mana_per_level: float = 35.0
@export_range(0.0, 1000.0, 0.1) var attack_damage_per_level: float = 4.0
@export_range(0.0, 1000.0, 0.1) var health_regeneration_per_level: float = 0.2
@export_range(0.0, 1000.0, 0.1) var mana_regeneration_per_level: float = 0.5
@export var abilities: Array[AbilityDefinition] = []
