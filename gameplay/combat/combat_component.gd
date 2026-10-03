class_name CombatComponent
extends Node
## Owns target selection and attack timing; damage is applied through ActorStats.

signal target_changed(target: Node3D)
signal attack_state_changed(remaining: float)

@export var actor_stats_path: NodePath = ^"../Stats"
var target: Node3D
var cooldown_remaining: float = 0.0
var _actor_stats: ActorStats
var _target_stats: ActorStats
var _owner_actor: CombatActor

func _ready() -> void:
	_actor_stats = get_node(actor_stats_path) as ActorStats
	_owner_actor = get_parent().get_node_or_null("CombatActor") as CombatActor
	_actor_stats.died.connect(_on_owner_died)

func _physics_process(delta: float) -> void:
	cooldown_remaining = maxf(0.0, cooldown_remaining - delta)
	if target == null:
		return
	if not is_instance_valid(target) or not is_instance_valid(_target_stats) or _target_stats.current_health <= 0.0 or not _valid_hostile(target):
		set_target(null)
		return
	var actor_position: Vector3 = get_parent().global_position
	var target_position: Vector3 = target.global_position
	var distance := Vector2(actor_position.x - target_position.x, actor_position.z - target_position.z).length()
	if distance > _actor_stats.attack_range or cooldown_remaining > 0.0:
		return
	var target_actor := target.get_node_or_null("CombatActor") as CombatActor
	_target_stats.apply_damage(_actor_stats.attack_damage, get_parent() as Node3D, &"basic")
	if _owner_actor != null and target_actor != null:
		var roster := get_tree().get_first_node_in_group("lane_combat_roster") as LaneCombatRoster
		if roster != null:
			roster.notify_hero_basic_attack(_owner_actor, target_actor, 6.0, 2.5)
	cooldown_remaining = _actor_stats.get_effective_attack_cooldown()
	attack_state_changed.emit(cooldown_remaining)

func set_target(new_target: Node3D) -> void:
	if _actor_stats.current_health <= 0.0:
		new_target = null
	var new_stats: ActorStats
	if new_target != null:
		if not is_instance_valid(new_target) or not new_target.is_inside_tree():
			new_target = null
		else:
			new_stats = new_target.get_node_or_null("Stats") as ActorStats
			if new_stats == null or new_stats.current_health <= 0.0 or not _valid_hostile(new_target):
				new_target = null
				new_stats = null
	if target == new_target:
		return
	if is_instance_valid(_target_stats) and _target_stats.died.is_connected(_on_target_died):
		_target_stats.died.disconnect(_on_target_died)
	target = new_target
	_target_stats = new_stats
	if _target_stats != null:
		_target_stats.died.connect(_on_target_died)
	target_changed.emit(target)

func get_target_stats() -> ActorStats:
	return _target_stats

func _on_target_died() -> void:
	cooldown_remaining = 0.0
	attack_state_changed.emit(0.0)
	set_target(null)

func _on_owner_died() -> void:
	cooldown_remaining = 0.0
	attack_state_changed.emit(0.0)
	set_target(null)

func _valid_hostile(candidate: Node3D) -> bool:
	if _owner_actor == null:
		return true # Preserve compatibility for isolated Phase 2 fixtures.
	var candidate_actor := candidate.get_node_or_null("CombatActor") as CombatActor
	return candidate_actor != null and _owner_actor.is_hostile_to(candidate_actor)
