class_name TargetDamageEffect
extends AbilityEffect

@export_range(0.0, 10000.0, 1.0) var damage: float = 0.0

func execute(context: AbilityCastContext) -> void:
	if context.target == null or not is_instance_valid(context.target):
		return
	var stats := context.target.get_node_or_null("Stats") as ActorStats
	var caster_actor := context.caster.get_node_or_null("CombatActor") as CombatActor
	var target_actor := context.target.get_node_or_null("CombatActor") as CombatActor
	if stats != null and stats.current_health > 0.0 and caster_actor != null and target_actor != null and caster_actor.is_hostile_to(target_actor):
		stats.apply_damage(damage, context.caster, &"ability")
