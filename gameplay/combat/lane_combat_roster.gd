class_name LaneCombatRoster
extends Node
## Cached actor registry used by timed AI queries; avoids repeated scene-tree searches.

@export_range(0.1, 2.0, 0.05) var query_interval: float = 0.25
var _actors: Array[CombatActor] = []

func _ready() -> void:
	add_to_group("lane_combat_roster")

func register_actor(actor: CombatActor) -> void:
	if actor != null and not _actors.has(actor):
		_actors.append(actor)

func unregister_actor(actor: CombatActor) -> void:
	_actors.erase(actor)

func query_nearby(position: Vector3, radius: float) -> Array[CombatActor]:
	var found: Array[CombatActor] = []
	var radius_squared := radius * radius
	for actor in _actors:
		if not is_instance_valid(actor) or not actor.is_alive():
			continue
		var offset := actor.world_position() - position
		offset.y = 0.0
		if offset.length_squared() <= radius_squared:
			found.append(actor)
	return found

func notify_hero_basic_attack(attacker: CombatActor, victim: CombatActor, radius: float, duration: float) -> void:
	if attacker == null or victim == null or attacker.actor_kind != &"hero" or victim.actor_kind != &"hero":
		return
	for candidate in query_nearby(attacker.world_position(), radius):
		if candidate.actor_kind == &"minion" and TeamRules.same_team(candidate.team, victim.team):
			var minion := candidate.actor as MinionActor
			minion.hero_aggro_radius = radius
			minion.hero_aggro_duration = duration
			minion.set_hero_aggro(attacker)
	for candidate in query_nearby(attacker.world_position(), 100.0):
		if candidate.actor_kind == &"tower" and TeamRules.same_team(candidate.team, victim.team):
			(candidate.actor as TowerActor).notify_hero_aggro(attacker)
