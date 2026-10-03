class_name AreaDamageEffect
extends AbilityEffect

@export_range(0.0, 10000.0, 1.0) var damage: float = 90.0
@export_range(0.1, 20.0, 0.1) var radius: float = 3.0

func execute(context: AbilityCastContext) -> void:
	for actor in context.caster.get_tree().get_nodes_in_group("combat_target"):
		if not is_instance_valid(actor) or not actor is Node3D:
			continue
		var target := actor as Node3D
		var stats := target.get_node_or_null("Stats") as ActorStats
		if stats == null or stats.current_health <= 0.0:
			continue
		var distance := Vector2(target.global_position.x - context.point.x, target.global_position.z - context.point.z).length()
		if distance <= radius:
			stats.apply_damage(damage)
