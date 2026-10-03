class_name MinionDefinition
extends Resource

enum MinionType { MELEE, RANGED }

@export var display_name: String = "Melee Minion"
@export var minion_type: MinionType = MinionType.MELEE
@export_range(1.0, 10000.0, 1.0) var max_health: float = 450.0
@export_range(0.1, 30.0, 0.1) var movement_speed: float = 2.6
@export_range(0.1, 1000.0, 0.1) var attack_damage: float = 18.0
@export_range(0.1, 30.0, 0.1) var attack_range: float = 1.8
@export_range(0.1, 20.0, 0.1) var attack_cooldown: float = 1.3
@export_range(0.0, 5.0, 0.01) var attack_point: float = 0.3
@export_range(0.0, 5.0, 0.01) var recovery_duration: float = 0.3
@export_range(0.1, 100.0, 0.1) var projectile_speed: float = 15.0
@export_range(0.0, 10000.0, 1.0) var gold_bounty: float = 22.0
@export_range(0.0, 10000.0, 1.0) var xp_reward: float = 35.0
@export var tint: Color = Color(0.25, 0.65, 0.95)
