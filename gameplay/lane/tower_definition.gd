class_name TowerDefinition
extends Resource
## Prototype data for a stationary lane tower.

@export_range(1.0, 100000.0, 1.0) var max_health: float = 2000.0
@export_range(0.1, 1000.0, 0.1) var attack_damage: float = 82.0
@export_range(0.1, 100.0, 0.1) var attack_range: float = 11.0
@export_range(0.1, 20.0, 0.1) var attack_interval: float = 1.25
@export_range(0.0, 5.0, 0.01) var attack_point: float = 0.42
@export_range(0.0, 5.0, 0.01) var recovery_duration: float = 0.35
@export_range(0.1, 100.0, 0.1) var projectile_speed: float = 12.5
