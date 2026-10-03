class_name CombatActor
extends Node
## Small identity/health facade composed onto heroes, minions, towers and dummies.

@export var team: TeamRules.Team = TeamRules.Team.NEUTRAL
@export var stats_path: NodePath = ^"../Stats"
@export var actor_kind: StringName = &"unit"
var actor: Node3D
var stats: ActorStats

func _ready() -> void:
	actor = get_parent() as Node3D
	stats = get_node_or_null(stats_path) as ActorStats
	if actor != null:
		actor.add_to_group("combat_actor")
		actor.add_to_group("combat_target") # Compatibility with Phase 2/3 targeting.
	var roster := get_tree().get_first_node_in_group("lane_combat_roster") as LaneCombatRoster
	if roster != null:
		roster.register_actor(self)

func _exit_tree() -> void:
	var roster := get_tree().get_first_node_in_group("lane_combat_roster") as LaneCombatRoster
	if roster != null:
		roster.unregister_actor(self)

func is_alive() -> bool:
	return is_instance_valid(stats) and stats.current_health > 0.0

func world_position() -> Vector3:
	return actor.global_position if is_instance_valid(actor) else Vector3.ZERO

func is_hostile_to(other: CombatActor) -> bool:
	return other != null and TeamRules.are_hostile(team, other.team)

func can_damage(other: CombatActor) -> bool:
	return is_alive() and other != null and other.is_alive() and is_hostile_to(other)

func receive_damage(amount: float, source: Node3D, category: StringName = &"basic") -> void:
	if is_alive():
		stats.apply_damage(amount, source, category)
