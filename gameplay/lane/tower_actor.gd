class_name TowerActor
extends StaticBody3D

@export var team: TeamRules.Team = TeamRules.Team.TEAM_A
@export_range(1.0, 100000.0, 1.0) var tower_health: float = 2200.0
@export_range(0.1, 1000.0, 0.1) var tower_damage: float = 90.0
@export_range(0.1, 100.0, 0.1) var tower_range: float = 11.0
@export_range(0.1, 20.0, 0.1) var tower_attack_cooldown: float = 1.2
@export_range(0.1, 3.0, 0.05) var acquisition_interval: float = 0.25
@export_range(0.1, 10.0, 0.1) var hero_aggro_duration: float = 2.5
var destroyed: bool = false
var target_actor: CombatActor
var aggro_target: CombatActor
var aggro_remaining: float = 0.0
var _identity: CombatActor
var _stats: ActorStats
var _roster: LaneCombatRoster
var _scan_left: float = 0.0
var _attack_left: float = 0.0

func _ready() -> void:
	_identity = $CombatActor as CombatActor
	_stats = $Stats as ActorStats
	_identity.team = team
	_identity.actor_kind = &"tower"
	_stats.max_health = tower_health
	_stats.current_health = tower_health
	_stats.attack_damage = tower_damage
	_stats.attack_range = tower_range
	_stats.attack_cooldown = tower_attack_cooldown
	_stats.died.connect(_on_died)
	_roster = get_tree().get_first_node_in_group("lane_combat_roster") as LaneCombatRoster

func _physics_process(delta: float) -> void:
	if destroyed:
		return
	_scan_left -= delta
	_attack_left = maxf(0.0, _attack_left - delta)
	aggro_remaining = maxf(0.0, aggro_remaining - delta)
	if aggro_remaining <= 0.0:
		aggro_target = null
	if _scan_left <= 0.0:
		_scan_left = acquisition_interval
		_acquire_target()
	if is_instance_valid(target_actor) and _identity.can_damage(target_actor):
		if _flat_distance(global_position, target_actor.world_position()) > tower_range:
			target_actor = null
		elif _attack_left <= 0.0:
			target_actor.receive_damage(tower_damage, self, &"basic")
			_attack_left = tower_attack_cooldown
	else:
		target_actor = null

func _acquire_target() -> void:
	if _roster == null:
		return
	if aggro_remaining > 0.0 and is_instance_valid(aggro_target) and _identity.can_damage(aggro_target):
		target_actor = aggro_target
		return
	var candidates := _roster.query_nearby(global_position, tower_range)
	var best_priority := 99
	var best_distance := INF
	target_actor = null
	for candidate in candidates:
		if not _identity.can_damage(candidate):
			continue
		var priority := 0 if candidate.actor_kind == &"minion" else (1 if candidate.actor_kind == &"hero" else 99)
		if priority >= 99:
			continue
		var distance := _flat_distance(global_position, candidate.world_position())
		if priority < best_priority or (priority == best_priority and distance < best_distance):
			best_priority = priority
			best_distance = distance
			target_actor = candidate

func notify_hero_aggro(attacker: CombatActor) -> void:
	if destroyed or attacker == null or attacker.actor_kind != &"hero" or not _identity.is_hostile_to(attacker):
		return
	if _flat_distance(global_position, attacker.world_position()) <= tower_range:
		aggro_target = attacker
		aggro_remaining = hero_aggro_duration

func _on_died() -> void:
	destroyed = true
	target_actor = null
	set_physics_process(false)
	$Visual.hide()
	$CollisionShape3D.set_deferred("disabled", true)

func _flat_distance(first: Vector3, second: Vector3) -> float:
	return Vector2(first.x - second.x, first.z - second.z).length()
