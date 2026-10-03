class_name BasicAttackController
extends Node3D
## Shared windup/release/recovery timing for heroes, minions, and towers.

enum State { IDLE, WINDUP, RELEASE, RECOVERY }
enum AttackType { MELEE, RANGED }

signal state_changed(state: int, progress: float, target: Node3D, time_until_next: float)
signal attack_started(target: Node3D)
signal attack_released(target: Node3D)
signal attack_finished(target: Node3D)

const PROJECTILE_SCENE := preload("res://gameplay/combat/basic_attack_projectile.tscn")
const RELEASE_FEEDBACK_DURATION := 0.08
const WINDUP_MATERIAL: Material = preload("res://gameplay/presentation/materials/attack_windup.tres")
const RELEASE_MATERIAL: Material = preload("res://gameplay/presentation/materials/attack_release.tres")
const RECOVERY_MATERIAL: Material = preload("res://gameplay/presentation/materials/attack_recovery.tres")

@export_range(0.0, 5.0, 0.01) var attack_point: float = 0.28
@export_range(0.0, 5.0, 0.01) var recovery_duration: float = 0.25
@export_range(0.1, 100.0, 0.1) var projectile_speed: float = 18.0
@export_enum("MELEE", "RANGED") var attack_type: int = AttackType.MELEE

var current_state: State = State.IDLE
var current_target: CombatActor
var _owner_actor: Node3D
var _owner_identity: CombatActor
var _stats: ActorStats
var _interval_remaining: float = 0.0
var _phase_elapsed: float = 0.0
var _windup_duration: float = 0.0
var _recovery_time: float = 0.0
var _timing_ratio: float = 1.0
var _enabled: bool = true
var _state_marker: MeshInstance3D

func _ready() -> void:
	_owner_actor = get_parent() as Node3D
	_owner_identity = _owner_actor.get_node_or_null("CombatActor") as CombatActor
	_stats = _owner_actor.get_node_or_null("Stats") as ActorStats
	if _stats != null:
		_stats.died.connect(_on_owner_died)
		_stats.health_changed.connect(_on_owner_health_changed)
	_create_state_marker()

func configure(attack_mode: int, point_time: float, recovery_time: float, projectile_velocity: float) -> void:
	attack_type = attack_mode
	attack_point = maxf(0.0, point_time)
	recovery_duration = maxf(0.0, recovery_time)
	projectile_speed = maxf(0.1, projectile_velocity)

func try_attack(target: Node3D) -> bool:
	if not _enabled or not _owner_is_alive() or not _valid_hostile_target(target):
		if current_state == State.WINDUP:
			cancel_windup()
		return false
	var identity := target.get_node_or_null("CombatActor") as CombatActor
	if _flat_distance(_owner_actor.global_position, target.global_position) > _stats.attack_range:
		return false
	if current_state == State.WINDUP:
		if current_target == identity:
			return false
		cancel_windup()
	if current_state != State.IDLE or _interval_remaining > 0.0:
		return false
	current_target = identity
	_phase_elapsed = 0.0
	var base_interval := maxf(0.05, _stats.attack_cooldown)
	var effective_interval := maxf(0.05, _stats.get_effective_attack_cooldown())
	_timing_ratio = clampf(effective_interval / base_interval, 0.1, 2.0)
	_interval_remaining = effective_interval
	_windup_duration = minf(maxf(0.01, attack_point * _timing_ratio), maxf(0.01, effective_interval - 0.01))
	_recovery_time = minf(maxf(0.0, recovery_duration * _timing_ratio), maxf(0.0, effective_interval - _windup_duration))
	_set_state(State.WINDUP)
	attack_started.emit(target)
	return true

func cancel_windup() -> bool:
	if current_state != State.WINDUP:
		return false
	_interval_remaining = 0.0
	_phase_elapsed = 0.0
	current_target = null
	_set_state(State.IDLE)
	return true

func stop_attacking() -> void:
	_enabled = false
	if current_state == State.WINDUP:
		cancel_windup()

func get_attack_state_name() -> String:
	return State.keys()[current_state]

func get_attack_point_progress() -> float:
	if current_state == State.RELEASE or current_state == State.RECOVERY:
		return 1.0
	if current_state != State.WINDUP:
		return 0.0
	return clampf(_phase_elapsed / maxf(0.01, _windup_duration), 0.0, 1.0)

func get_time_until_next_attack() -> float:
	var phase_wait := 0.0
	if current_state == State.WINDUP:
		phase_wait = maxf(0.0, _windup_duration - _phase_elapsed) + _recovery_time
	elif current_state == State.RELEASE:
		phase_wait = maxf(0.0, RELEASE_FEEDBACK_DURATION - _phase_elapsed) + _recovery_time
	elif current_state == State.RECOVERY:
		phase_wait = maxf(0.0, _recovery_time - _phase_elapsed)
	return maxf(_interval_remaining, phase_wait)

func get_interval_remaining() -> float:
	return _interval_remaining

func set_interval_remaining(value: float) -> void:
	_interval_remaining = maxf(0.0, value)

func _physics_process(delta: float) -> void:
	_interval_remaining = maxf(0.0, _interval_remaining - delta)
	if current_state == State.IDLE:
		return
	_phase_elapsed += delta
	if current_state == State.WINDUP and _phase_elapsed >= _windup_duration:
		_release_attack()
	elif current_state == State.RELEASE and _phase_elapsed >= RELEASE_FEEDBACK_DURATION:
		_set_state(State.RECOVERY)
		_phase_elapsed = 0.0
	elif current_state == State.RECOVERY and _phase_elapsed >= _recovery_time:
		var finished_target := current_target.actor if is_instance_valid(current_target) else null
		current_target = null
		_set_state(State.IDLE)
		attack_finished.emit(finished_target)

func _release_attack() -> void:
	var target_node := current_target.actor if is_instance_valid(current_target) else null
	if not _owner_is_alive() or not _valid_hostile_target(target_node):
		_set_state(State.RECOVERY)
		_phase_elapsed = 0.0
		return
	if _flat_distance(_owner_actor.global_position, target_node.global_position) > _stats.attack_range:
		_set_state(State.RECOVERY)
		_phase_elapsed = 0.0
		return
	if attack_type == AttackType.RANGED:
		var projectile := PROJECTILE_SCENE.instantiate() as BasicAttackProjectile
		projectile.configure(_owner_actor, current_target, _stats.attack_damage, DamageEvent.BASIC_ATTACK, projectile_speed)
		var scene := get_tree().current_scene
		(scene if scene != null else get_tree().root).add_child(projectile)
		projectile.global_position = _owner_actor.global_position + Vector3.UP * 1.0
	else:
		current_target.receive_damage(_stats.attack_damage, _owner_actor, DamageEvent.BASIC_ATTACK)
	attack_released.emit(target_node)
	_set_state(State.RELEASE)
	_phase_elapsed = 0.0

func _valid_hostile_target(target: Node3D) -> bool:
	if target == null or not is_instance_valid(target) or not target.is_inside_tree() or _owner_identity == null or not _owner_identity.is_alive():
		return false
	var target_identity := target.get_node_or_null("CombatActor") as CombatActor
	return target_identity != null and _owner_identity.can_damage(target_identity)

func _owner_is_alive() -> bool:
	return is_instance_valid(_stats) and _stats.current_health > 0.0 and is_instance_valid(_owner_identity) and _owner_identity.is_alive()

func _on_owner_died() -> void:
	# Death terminates every presentation/attack phase; a recovery ring must not
	# remain visible while the owner is dead or hidden.
	current_target = null
	_interval_remaining = 0.0
	_phase_elapsed = 0.0
	_set_state(State.IDLE)
	_enabled = false

func _on_owner_health_changed(current: float, _maximum: float) -> void:
	if current <= 0.0 or _enabled:
		return
	_enabled = true
	current_target = null
	_interval_remaining = 0.0
	_phase_elapsed = 0.0
	_set_state(State.IDLE)

func _set_state(new_state: State) -> void:
	current_state = new_state
	_update_marker()
	state_changed.emit(current_state, get_attack_point_progress(), current_target.actor if is_instance_valid(current_target) else null, get_time_until_next_attack())

func _create_state_marker() -> void:
	_state_marker = MeshInstance3D.new()
	_state_marker.name = "AttackStateMarker"
	var ring := TorusMesh.new()
	ring.inner_radius = 0.46
	ring.outer_radius = 0.52
	_state_marker.mesh = ring
	_state_marker.rotation_degrees.x = 90.0
	_state_marker.position = Vector3(0.0, 0.035, 0.0)
	_state_marker.visible = false
	add_child(_state_marker)
	_update_marker()

func _update_marker() -> void:
	if _state_marker == null:
		return
	_state_marker.visible = current_state != State.IDLE
	match current_state:
		State.WINDUP:
			_state_marker.material_override = WINDUP_MATERIAL
		State.RELEASE:
			_state_marker.material_override = RELEASE_MATERIAL
		State.RECOVERY:
			_state_marker.material_override = RECOVERY_MATERIAL

func _flat_distance(first: Vector3, second: Vector3) -> float:
	return Vector2(first.x - second.x, first.z - second.z).length()
