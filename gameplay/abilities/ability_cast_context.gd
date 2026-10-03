class_name AbilityCastContext
extends RefCounted

var caster: Node3D
var caster_stats: ActorStats
var target: Node3D
var point: Vector3
var definition: AbilityDefinition

func _init(
		p_caster: Node3D,
		p_caster_stats: ActorStats,
		p_definition: AbilityDefinition,
		p_target: Node3D = null,
		p_point: Vector3 = Vector3.ZERO) -> void:
	caster = p_caster
	caster_stats = p_caster_stats
	definition = p_definition
	target = p_target
	point = p_point
