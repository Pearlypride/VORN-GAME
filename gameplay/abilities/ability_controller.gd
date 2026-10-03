class_name AbilityController
extends Node
## Owns per-hero cooldown state and validates semantic cast commands.

enum AbilityState { READY, TARGETING, COOLDOWN }

signal targeting_changed(ability_id: StringName)
signal ability_state_changed(ability_id: StringName)
signal ability_cast(ability_id: StringName, target: Node3D, point: Vector3)

var current_targeting_ability: StringName = &""
var _caster: Node3D
var _stats: ActorStats
var _runtime: Dictionary = {}

func initialize(definition: HeroDefinition, caster: Node3D, stats: ActorStats) -> void:
	_caster = caster
	_stats = stats
	_runtime.clear()
	for ability in definition.abilities:
		if ability == null or ability.ability_id == &"":
			continue
		_runtime[ability.ability_id] = {"definition": ability, "cooldown_remaining": 0.0}

func _physics_process(delta: float) -> void:
	for ability_id in _runtime:
		var runtime: Dictionary = _runtime[ability_id]
		var previous: float = runtime["cooldown_remaining"]
		if previous > 0.0:
			runtime["cooldown_remaining"] = maxf(0.0, previous - delta)
			if runtime["cooldown_remaining"] == 0.0:
				ability_state_changed.emit(ability_id)

func request_cast(ability_id: StringName) -> bool:
	if not _runtime.has(ability_id):
		return false
	if current_targeting_ability == ability_id:
		cancel_targeting()
		return true
	var runtime: Dictionary = _runtime[ability_id]
	var definition := runtime["definition"] as AbilityDefinition
	if not _can_begin(runtime):
		return false
	if definition.cast_type == AbilityDefinition.CastType.SELF:
		return _execute(runtime, null, _caster.global_position)
	current_targeting_ability = ability_id
	targeting_changed.emit(current_targeting_ability)
	ability_state_changed.emit(ability_id)
	return true

func confirm_target(target: Node3D) -> bool:
	var runtime := _get_targeting_runtime()
	if runtime.is_empty():
		return false
	var definition := runtime["definition"] as AbilityDefinition
	if definition.cast_type != AbilityDefinition.CastType.TARGETED or not _is_valid_enemy(target):
		return false
	if _flat_distance(_caster.global_position, target.global_position) > definition.cast_range:
		return false
	return _execute(runtime, target, target.global_position)

func confirm_point(point: Vector3) -> bool:
	var runtime := _get_targeting_runtime()
	if runtime.is_empty():
		return false
	var definition := runtime["definition"] as AbilityDefinition
	if definition.cast_type != AbilityDefinition.CastType.POINT and definition.cast_type != AbilityDefinition.CastType.AREA:
		return false
	if _flat_distance(_caster.global_position, point) > definition.cast_range:
		return false
	return _execute(runtime, null, point)

func cancel_targeting() -> void:
	if current_targeting_ability == &"":
		return
	var previous := current_targeting_ability
	current_targeting_ability = &""
	targeting_changed.emit(&"")
	ability_state_changed.emit(previous)

func get_ability_definition(ability_id: StringName) -> AbilityDefinition:
	if not _runtime.has(ability_id):
		return null
	return _runtime[ability_id]["definition"] as AbilityDefinition

func get_cooldown_remaining(ability_id: StringName) -> float:
	if not _runtime.has(ability_id):
		return 0.0
	return _runtime[ability_id]["cooldown_remaining"]

func get_ability_state(ability_id: StringName) -> AbilityState:
	if ability_id == current_targeting_ability:
		return AbilityState.TARGETING
	if get_cooldown_remaining(ability_id) > 0.0:
		return AbilityState.COOLDOWN
	return AbilityState.READY

func get_ability_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for key in _runtime.keys():
		ids.append(key)
	return ids

func is_targeting() -> bool:
	return current_targeting_ability != &""

func _get_targeting_runtime() -> Dictionary:
	if not is_targeting() or not _runtime.has(current_targeting_ability):
		return {}
	return _runtime[current_targeting_ability]

func _can_begin(runtime: Dictionary) -> bool:
	if not is_instance_valid(_caster) or not is_instance_valid(_stats) or _stats.current_health <= 0.0:
		return false
	if runtime["cooldown_remaining"] > 0.0:
		return false
	var definition := runtime["definition"] as AbilityDefinition
	return _stats.current_mana >= definition.mana_cost

func _execute(runtime: Dictionary, target: Node3D, point: Vector3) -> bool:
	if not _can_begin(runtime):
		return false
	var definition := runtime["definition"] as AbilityDefinition
	if definition.effect == null or not _stats.spend_mana(definition.mana_cost):
		return false
	runtime["cooldown_remaining"] = definition.cooldown
	var context := AbilityCastContext.new(_caster, _stats, definition, target, point)
	definition.effect.execute(context)
	var used_ability := definition.ability_id
	if current_targeting_ability == used_ability:
		current_targeting_ability = &""
		targeting_changed.emit(&"")
	ability_cast.emit(used_ability, target, point)
	ability_state_changed.emit(used_ability)
	return true

func _is_valid_enemy(target: Node3D) -> bool:
	if target == null or not is_instance_valid(target) or not target.is_inside_tree() or not target.is_in_group("combat_target"):
		return false
	var target_stats := target.get_node_or_null("Stats") as ActorStats
	return target_stats != null and target_stats.current_health > 0.0

func _flat_distance(first: Vector3, second: Vector3) -> float:
	return Vector2(first.x - second.x, first.z - second.z).length()
