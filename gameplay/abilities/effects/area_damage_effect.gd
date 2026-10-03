class_name AreaDamageEffect
extends AbilityEffect

@export_range(0.0, 10000.0, 1.0) var damage: float = 90.0
@export_range(0.1, 20.0, 0.1) var radius: float = 3.0

func execute(context: AbilityCastContext) -> void:
	var roster := context.caster.get_tree().get_first_node_in_group("lane_combat_roster") as LaneCombatRoster
	var candidates: Array[CombatActor] = roster.query_nearby(context.point, radius) if roster != null else []
	var caster_actor := context.caster.get_node_or_null("CombatActor") as CombatActor
	for target_actor in candidates:
		if caster_actor == null or not caster_actor.is_hostile_to(target_actor):
			continue
		var target := target_actor.actor
		var stats := target.get_node_or_null("Stats") as ActorStats
		if stats == null or stats.current_health <= 0.0:
			continue
		var distance := Vector2(target.global_position.x - context.point.x, target.global_position.z - context.point.z).length()
		if distance <= radius:
			stats.apply_damage(damage, context.caster, &"ability")
