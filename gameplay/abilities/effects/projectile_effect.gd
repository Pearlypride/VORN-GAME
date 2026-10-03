class_name ProjectileEffect
extends AbilityEffect

@export_range(0.0, 10000.0, 1.0) var damage: float = 150.0
@export var projectile_scene: PackedScene

func execute(context: AbilityCastContext) -> void:
	if projectile_scene == null:
		return
	var direction := context.point - context.caster.global_position
	direction.y = 0.0
	if direction.length_squared() < 0.001:
		direction = -context.caster.global_basis.z
		direction.y = 0.0
	if direction.length_squared() < 0.001:
		direction = Vector3.FORWARD
	var projectile := projectile_scene.instantiate() as AbilityProjectile
	if projectile == null:
		return
	projectile.configure(direction.normalized(), context.definition.cast_range, damage)
	var tree := context.caster.get_tree()
	var projectile_parent: Node = tree.current_scene if tree.current_scene != null else tree.root
	projectile_parent.add_child(projectile)
	projectile.global_position = context.caster.global_position + direction.normalized() * 0.8 + Vector3.UP * 0.05
