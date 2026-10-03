class_name AbilityProjectile
extends Area3D

@export_range(0.1, 100.0, 0.1) var speed: float = 14.0
var direction: Vector3 = Vector3.FORWARD
var maximum_distance: float = 12.0
var damage: float = 150.0
var traveled_distance: float = 0.0
var source_actor: Node3D
var source_team: int = TeamRules.Team.NEUTRAL

func _ready() -> void:
	add_to_group("ability_projectile")
	body_entered.connect(_on_body_entered)

func configure(projectile_direction: Vector3, max_distance: float, projectile_damage: float, source: Node3D = null) -> void:
	direction = projectile_direction.normalized()
	maximum_distance = max_distance
	damage = projectile_damage
	source_actor = source
	var source_identity := source.get_node_or_null("CombatActor") as CombatActor if source != null else null
	if source_identity != null:
		source_team = source_identity.team

func _physics_process(delta: float) -> void:
	var step := speed * delta
	global_position += direction * step
	traveled_distance += step
	if traveled_distance >= maximum_distance:
		queue_free()

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("combat_target"):
		return
	var stats := body.get_node_or_null("Stats") as ActorStats
	var source_identity := source_actor.get_node_or_null("CombatActor") as CombatActor if is_instance_valid(source_actor) else null
	var target_identity := body.get_node_or_null("CombatActor") as CombatActor
	if stats == null or stats.current_health <= 0.0 or source_identity == null or target_identity == null or not source_identity.is_hostile_to(target_identity):
		return
	stats.apply_damage(damage, source_actor, DamageEvent.ABILITY)
	queue_free()
