class_name MinionActor
extends CharacterBody3D

enum State { ADVANCE, COMBAT, DEAD }

@export var definition: MinionDefinition
@export var team: TeamRules.Team = TeamRules.Team.TEAM_A
@export var lane_path: LanePath
@export var initial_path_distance: float = 0.0
@export_range(1.0, 100.0, 1.0) var acquisition_range: float = 7.5
@export_range(0.1, 60.0, 0.1) var death_cleanup_delay: float = 1.2
@export_range(0.1, 100.0, 0.1) var hero_aggro_duration: float = 2.5
@export_range(0.1, 100.0, 0.1) var hero_aggro_radius: float = 6.0
var state: State = State.ADVANCE
var path_distance: float = 0.0
var target_actor: CombatActor
var aggro_target: CombatActor
var aggro_remaining: float = 0.0
var _stats: ActorStats
var _identity: CombatActor
var _roster: LaneCombatRoster
var _attacks: BasicAttackController
var _scan_timer: float = 0.0
var _death_handled: bool = false

func _ready() -> void:
	_stats = $Stats as ActorStats
	_identity = $CombatActor as CombatActor
	_attacks = $BasicAttackController as BasicAttackController
	_roster = get_tree().get_first_node_in_group("lane_combat_roster") as LaneCombatRoster
	path_distance = initial_path_distance
	if definition != null:
		_stats.max_health = definition.max_health
		_stats.restore_full_health()
		_stats.movement_speed = definition.movement_speed
		_stats.attack_damage = definition.attack_damage
		_stats.attack_range = definition.attack_range
		_stats.attack_cooldown = definition.attack_cooldown
		var attack_mode := BasicAttackController.AttackType.RANGED if definition.minion_type == MinionDefinition.MinionType.RANGED else BasicAttackController.AttackType.MELEE
		_attacks.configure(attack_mode, definition.attack_point, definition.recovery_duration, definition.projectile_speed)
	_identity.team = team
	_identity.actor_kind = &"minion"
	($ActorReadability as ActorReadability).configure_team(team)
	_stats.died.connect(_on_died)

func configure(unit_definition: MinionDefinition, unit_team: TeamRules.Team, path: LanePath, start_distance: float = 0.0) -> void:
	definition = unit_definition
	team = unit_team
	lane_path = path
	initial_path_distance = start_distance
	if lane_path != null:
		position = lane_path.position_for_team(team, start_distance) + Vector3.UP * 0.55

func set_hero_aggro(attacker: CombatActor) -> void:
	if state == State.DEAD or attacker == null or TeamRules.same_team(attacker.team, team) or attacker.actor_kind != &"hero":
		return
	var offset := attacker.world_position() - global_position
	offset.y = 0.0
	if offset.length() <= hero_aggro_radius:
		aggro_target = attacker
		aggro_remaining = hero_aggro_duration

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	aggro_remaining = maxf(0.0, aggro_remaining - delta)
	if (aggro_remaining <= 0.0 or not is_instance_valid(aggro_target) or not aggro_target.is_alive()):
		if is_instance_valid(aggro_target) and target_actor == aggro_target:
			target_actor = null
			_scan_timer = 0.0
		aggro_target = null
	_scan_timer -= delta
	if _scan_timer <= 0.0:
		_scan_timer = _roster.query_interval if _roster != null else 0.25
		_update_target()
	if target_actor != null and target_actor.is_alive():
		state = State.COMBAT
		_combat_tick(delta)
	else:
		target_actor = null
		state = State.ADVANCE
		_advance(delta)

func _update_target() -> void:
	var previous_target := target_actor
	if aggro_remaining > 0.0 and is_instance_valid(aggro_target) and _identity.can_damage(aggro_target):
		target_actor = aggro_target
		if previous_target != target_actor:
			_attacks.cancel_windup()
		state = State.COMBAT
		return
	var candidates: Array[CombatActor] = _roster.query_nearby(global_position, acquisition_range) if _roster != null else []
	var best: CombatActor
	var best_priority := 99
	var best_distance := INF
	for candidate in candidates:
		if candidate == _identity or not _identity.can_damage(candidate):
			continue
		var priority := _target_priority(candidate)
		if priority >= 99:
			continue
		var distance := _flat_distance(global_position, candidate.world_position())
		if priority < best_priority or (priority == best_priority and distance < best_distance):
			best = candidate
			best_priority = priority
			best_distance = distance
	target_actor = best
	if previous_target != target_actor:
		_attacks.cancel_windup()
	state = State.COMBAT if target_actor != null else State.ADVANCE

func _target_priority(candidate: CombatActor) -> int:
	if candidate.actor_kind == &"minion":
		return 0
	if candidate.actor_kind == &"hero":
		return 1
	if candidate.actor_kind == &"tower":
		return 2
	return 99

func _combat_tick(delta: float) -> void:
	if not _identity.can_damage(target_actor):
		_attacks.cancel_windup()
		target_actor = null
		return
	var offset := target_actor.world_position() - global_position
	offset.y = 0.0
	var distance := offset.length()
	if distance > _stats.attack_range:
		_attacks.cancel_windup()
		var direction := offset.normalized()
		velocity.x = direction.x * _stats.movement_speed
		velocity.z = direction.z * _stats.movement_speed
		$Visual.look_at(global_position + direction, Vector3.UP)
		move_and_slide()
	else:
		$Visual.look_at(target_actor.world_position(), Vector3.UP)
		_attacks.try_attack(target_actor.actor)

func _advance(delta: float) -> void:
	if lane_path == null:
		velocity = Vector3.ZERO
		return
	path_distance = minf(lane_path.length(), path_distance + _stats.movement_speed * delta)
	var destination := lane_path.position_for_team(team, path_distance) + Vector3.UP * 0.55
	var offset := destination - global_position
	offset.y = 0.0
	if offset.length() > 0.05:
		var direction := offset.normalized()
		velocity.x = direction.x * _stats.movement_speed
		velocity.z = direction.z * _stats.movement_speed
		$Visual.look_at(global_position + direction, Vector3.UP)
		move_and_slide()

func _on_died() -> void:
	if _death_handled:
		return
	_death_handled = true
	state = State.DEAD
	target_actor = null
	_attacks.stop_attacking()
	aggro_target = null
	velocity = Vector3.ZERO
	set_physics_process(false)
	$CollisionShape3D.set_deferred("disabled", true)
	var killer := _stats.last_damage_source as Node3D
	var killer_actor := killer.get_node_or_null("CombatActor") as CombatActor if is_instance_valid(killer) else null
	if definition != null and killer_actor != null and TeamRules.are_hostile(killer_actor.team, team):
		var wallet := killer.get_node_or_null("GoldWallet") as GoldWallet
		if wallet != null:
			wallet.award(roundi(definition.gold_bounty))
	_award_nearby_xp()
	get_tree().create_timer(death_cleanup_delay).timeout.connect(queue_free)

func _award_nearby_xp() -> void:
	if definition == null or _roster == null:
		return
	for candidate in _roster.query_nearby(global_position, 100.0):
		if candidate.actor_kind != &"hero" or not TeamRules.are_hostile(candidate.team, team):
			continue
		var progression := candidate.actor.get_node_or_null("Progression") as HeroProgression
		if progression != null and progression.is_in_xp_range(global_position):
			progression.grant_xp(definition.xp_reward)

func _flat_distance(first: Vector3, second: Vector3) -> float:
	return Vector2(first.x - second.x, first.z - second.z).length()
