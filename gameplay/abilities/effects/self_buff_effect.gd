class_name SelfBuffEffect
extends AbilityEffect

@export_range(0.1, 60.0, 0.1) var duration: float = 6.0
@export_range(1.0, 5.0, 0.05) var movement_speed_multiplier: float = 1.3
@export_range(0.1, 1.0, 0.05) var attack_cooldown_multiplier: float = 0.7

func execute(context: AbilityCastContext) -> void:
	var status_effects := context.caster.get_node_or_null("StatusEffects") as StatusEffectController
	if status_effects != null:
		status_effects.apply_timed_modifier(
			&"r_surge",
			duration,
			movement_speed_multiplier,
			attack_cooldown_multiplier)
