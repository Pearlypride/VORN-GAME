class_name StatusEffectController
extends Node
## Minimal timed multiplicative modifiers, currently used only by R.

signal effects_changed

@export var actor_stats_path: NodePath = ^"../Stats"
var _stats: ActorStats
var _effects: Dictionary = {}

func _ready() -> void:
	_stats = get_node(actor_stats_path) as ActorStats

func _physics_process(delta: float) -> void:
	var expired: Array[StringName] = []
	for effect_id in _effects:
		var effect: Dictionary = _effects[effect_id]
		effect["remaining"] = maxf(0.0, effect["remaining"] - delta)
		if effect["remaining"] == 0.0:
			expired.append(effect_id)
	for effect_id in expired:
		_effects.erase(effect_id)
	if not expired.is_empty():
		_recalculate()
		effects_changed.emit()

func apply_timed_modifier(
		effect_id: StringName,
		duration: float,
		movement_speed_multiplier: float,
		attack_cooldown_multiplier: float) -> void:
	if duration <= 0.0:
		return
	_effects[effect_id] = {
		"remaining": duration,
		"movement": maxf(0.0, movement_speed_multiplier),
		"attack_cooldown": maxf(0.05, attack_cooldown_multiplier),
	}
	_recalculate()
	effects_changed.emit()

func clear_all() -> void:
	if _effects.is_empty():
		return
	_effects.clear()
	_recalculate()
	effects_changed.emit()

func has_effect(effect_id: StringName) -> bool:
	return _effects.has(effect_id)

func get_remaining(effect_id: StringName) -> float:
	if not _effects.has(effect_id):
		return 0.0
	return _effects[effect_id]["remaining"]

func _recalculate() -> void:
	var movement_multiplier := 1.0
	var cooldown_multiplier := 1.0
	for effect_id in _effects:
		var effect: Dictionary = _effects[effect_id]
		movement_multiplier *= effect["movement"]
		cooldown_multiplier *= effect["attack_cooldown"]
	_stats.set_status_multipliers(movement_multiplier, cooldown_multiplier)
