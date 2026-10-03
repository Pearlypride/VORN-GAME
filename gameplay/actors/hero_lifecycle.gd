class_name HeroLifecycle
extends Node
## Development death and respawn loop. Cooldowns continue while dead; resources reset on respawn.

signal hero_died
signal hero_respawned

@export_range(0.1, 30.0, 0.1) var respawn_delay: float = 2.5
@onready var _player: PlayerController = get_parent() as PlayerController
@onready var _stats: ActorStats = get_node("../Stats") as ActorStats
@onready var _combat: CombatComponent = get_node("../Combat") as CombatComponent
@onready var _abilities: AbilityController = get_node("../AbilityController") as AbilityController
@onready var _status_effects: StatusEffectController = get_node("../StatusEffects") as StatusEffectController
@onready var _visual: Node3D = get_node("../Visual") as Node3D
@onready var _collision: CollisionShape3D = get_node("../CollisionShape3D") as CollisionShape3D
var _spawn_position: Vector3
var _respawn_pending: bool = false

func _ready() -> void:
	_spawn_position = _player.global_position
	_stats.died.connect(_on_hero_died)

func _on_hero_died() -> void:
	if _respawn_pending:
		return
	_respawn_pending = true
	_player.clear_command()
	_combat.set_target(null)
	_abilities.cancel_targeting()
	_status_effects.clear_all()
	_collision.set_deferred("disabled", true)
	hero_died.emit()
	var timer := get_tree().create_timer(respawn_delay)
	timer.timeout.connect(_respawn)

func _respawn() -> void:
	_player.global_position = _spawn_position
	_player.velocity = Vector3.ZERO
	_stats.restore_full_resources()
	_visual.show()
	_collision.set_deferred("disabled", false)
	_player.clear_command()
	_respawn_pending = false
	hero_respawned.emit()
