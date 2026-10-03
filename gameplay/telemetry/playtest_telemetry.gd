class_name PlaytestTelemetry
extends Node
## Local-only counters for the manual prototype playtest.

var last_hit_count: int = 0
var average_attack_interval: float = 0.0
var attack_samples: int = 0
var _interval_total: float = 0.0
var _last_release_msec: int = -1
var _last_gold: int = 0
var _stats: ActorStats
var _wallet: GoldWallet
var _attacks: BasicAttackController
var _progression: HeroProgression
var _lane_world: LaneWorld

func _ready() -> void:
	var owner_actor := get_parent()
	_stats = owner_actor.get_node_or_null("Stats") as ActorStats
	_wallet = owner_actor.get_node_or_null("GoldWallet") as GoldWallet
	_attacks = owner_actor.get_node_or_null("BasicAttackController") as BasicAttackController
	_progression = owner_actor.get_node_or_null("Progression") as HeroProgression
	if _wallet != null:
		_last_gold = _wallet.current_gold
		_wallet.gold_changed.connect(_on_gold_changed)
	if _attacks != null:
		_attacks.attack_released.connect(_on_attack_released)
	var scene := get_tree().current_scene
	if scene != null:
		_lane_world = scene.get_node_or_null("LaneWorld") as LaneWorld

func get_summary() -> String:
	var move_speed := _stats.get_effective_movement_speed() if _stats != null else 0.0
	var wave := 0
	if _lane_world != null and _lane_world.team_a_spawner != null:
		wave = _lane_world.team_a_spawner.wave_number
	var level := _progression.level if _progression != null else 1
	var gold := _wallet.current_gold if _wallet != null else 0
	var interval_text := "—" if attack_samples == 0 else "%.2fs" % average_attack_interval
	return "Playtest · last hits %d · avg attack %s · move %.1f · wave %d · gold %d · level %d" % [last_hit_count, interval_text, move_speed, wave, gold, level]

func _on_gold_changed(current: int, _total: int) -> void:
	if current > _last_gold:
		last_hit_count += 1
	_last_gold = current

func _on_attack_released(_target: Node3D) -> void:
	var now := Time.get_ticks_msec()
	if _last_release_msec >= 0:
		_interval_total += float(now - _last_release_msec) / 1000.0
		attack_samples += 1
		average_attack_interval = _interval_total / float(attack_samples)
	_last_release_msec = now
