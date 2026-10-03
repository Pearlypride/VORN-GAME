class_name AbilityProjectile
extends Area3D

const BREAKLINE_MATERIAL: Material = preload("res://gameplay/presentation/materials/vfx_breakline.tres")
const IMPACT_MATERIAL: Material = preload("res://gameplay/presentation/materials/impact_flash.tres")

@export_range(0.1, 100.0, 0.1) var speed: float = 14.0
var direction: Vector3 = Vector3.FORWARD
var maximum_distance: float = 12.0
var damage: float = 150.0
var traveled_distance: float = 0.0
var source_actor: Node3D
var source_team: int = TeamRules.Team.NEUTRAL
var _trail: MeshInstance3D

func _ready() -> void:
	add_to_group("ability_projectile")
	body_entered.connect(_on_body_entered)
	var visual := $Visual as MeshInstance3D
	visual.material_override = BREAKLINE_MATERIAL
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.25, 0.16, 0.9)
	_trail = MeshInstance3D.new()
	_trail.name = "BreaklineWake"
	_trail.mesh = mesh
	_trail.material_override = BREAKLINE_MATERIAL
	_trail.position.z = 0.55
	add_child(_trail)
	_orient_visual()

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
	_orient_visual()
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
	_spawn_impact(global_position)
	queue_free()

func _orient_visual() -> void:
	if direction.length_squared() > 0.001:
		look_at(global_position + direction, Vector3.UP)

func _spawn_impact(at: Vector3) -> void:
	var flash := MeshInstance3D.new()
	flash.name = "BreaklineImpact"
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.14
	mesh.outer_radius = 0.2
	flash.mesh = mesh
	flash.material_override = IMPACT_MATERIAL
	flash.rotation_degrees.x = 90.0
	var scene := get_tree().current_scene
	(scene if scene != null else get_tree().root).add_child(flash)
	flash.global_position = at
	var tween := flash.create_tween()
	tween.tween_property(flash, "scale", Vector3(2.3, 2.3, 2.3), 0.2)
	tween.parallel().tween_property(flash, "transparency", 1.0, 0.2)
	tween.tween_callback(flash.queue_free)
