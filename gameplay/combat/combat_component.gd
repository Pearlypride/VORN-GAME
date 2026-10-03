class_name CombatComponent
extends Node
## Owns a selected attack target and delegates attack timing to BasicAttackController.

signal target_changed(target: Node3D)
signal attack_state_changed(remaining: float)

@export var actor_stats_path: NodePath = ^"../Stats"
@export var attack_controller_path: NodePath = ^"../BasicAttackController"
var target: Node3D
var cooldown_remaining: float:
	get:
		return _attacks.get_interval_remaining() if is_instance_valid(_attacks) else 0.0
	set(value):
		if is_instance_valid(_attacks):
			_attacks.set_interval_remaining(value)
var _actor_stats: ActorStats
var _target_stats: ActorStats
var _owner_actor: CombatActor
var _attacks: BasicAttackController

func _ready() -> void:
	_actor_stats = get_node(actor_stats_path) as ActorStats
	_attacks = get_node_or_null(attack_controller_path) as BasicAttackController
	_owner_actor = get_parent().get_node_or_null("CombatActor") as CombatActor
	_actor_stats.died.connect(_on_owner_died)

func _physics_process(_delta: float) -> void:
	if target == null:
		return
	if not is_instance_valid(target) or not is_instance_valid(_target_stats) or _target_stats.current_health <= 0.0 or not _valid_hostile(target):
		set_target(null)
		return
	var actor_position: Vector3 = get_parent().global_position
	var target_position: Vector3 = target.global_position
	var distance := Vector2(actor_position.x - target_position.x, actor_position.z - target_position.z).length()
	if distance > _actor_stats.attack_range:
		if _attacks != null:
			_attacks.cancel_windup()
		return
	if _attacks != null and _attacks.try_attack(target):
		attack_state_changed.emit(_attacks.get_time_until_next_attack())
		if _owner_actor != null:
			var target_actor := target.get_node_or_null("CombatActor") as CombatActor
			var roster := get_tree().get_first_node_in_group("lane_combat_roster") as LaneCombatRoster
			if roster != null and target_actor != null:
				roster.notify_hero_basic_attack(_owner_actor, target_actor, 6.0, 2.5)

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
	if _attacks != null:
		_attacks.cancel_windup()
	if is_instance_valid(_target_stats) and _target_stats.died.is_connected(_on_target_died):
		_target_stats.died.disconnect(_on_target_died)
	target = new_target
	_target_stats = new_stats
	if _target_stats != null:
		_target_stats.died.connect(_on_target_died)
	target_changed.emit(target)

func get_target_stats() -> ActorStats:
	return _target_stats

func get_attack_controller() -> BasicAttackController:
	return _attacks

func _on_target_died() -> void:
	set_target(null)

func _on_owner_died() -> void:
	set_target(null)

func _valid_hostile(candidate: Node3D) -> bool:
	if _owner_actor == null:
		return true
	var candidate_actor := candidate.get_node_or_null("CombatActor") as CombatActor
	return candidate_actor != null and _owner_actor.is_hostile_to(candidate_actor)
