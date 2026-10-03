class_name TargetDamageEffect
extends AbilityEffect

@export_range(0.0, 10000.0, 1.0) var damage: float = 0.0

func execute(context: AbilityCastContext) -> void:
	if context.target == null or not is_instance_valid(context.target):
		return
	var stats := context.target.get_node_or_null("Stats") as ActorStats
	if stats != null and stats.current_health > 0.0:
		stats.apply_damage(damage)
