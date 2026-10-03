class_name BasicAttackProjectile
extends Area3D
## Tracking basic-attack projectile. A dead/removed target makes it expire without damage.

const HERO_MATERIAL: Material = preload("res://gameplay/presentation/materials/projectile_hero.tres")
const MINION_MATERIAL: Material = preload("res://gameplay/presentation/materials/projectile_minion.tres")
const TOWER_MATERIAL: Material = preload("res://gameplay/presentation/materials/projectile_tower.tres")
const IMPACT_MATERIAL: Material = preload("res://gameplay/presentation/materials/impact_flash.tres")

@export_range(0.1, 100.0, 0.1) var impact_radius: float = 0.45
@export_range(0.5, 30.0, 0.1) var lifetime: float = 6.0
var source_actor: Node3D
var target_actor: CombatActor
var source_team: int = TeamRules.Team.NEUTRAL
var damage: float = 0.0
var damage_category: StringName = DamageEvent.BASIC_ATTACK
var speed: float = 18.0
var projectile_style: StringName = &"hero"
var _elapsed: float = 0.0
var _visual: MeshInstance3D
var _trail: MeshInstance3D

func _ready() -> void:
	add_to_group("basic_attack_projectile")
	_visual = $Visual as MeshInstance3D
	_create_trail()
	_apply_style()

func configure(source: Node3D, target: CombatActor, amount: float, category: StringName, projectile_speed: float) -> void:
	source_actor = source
	target_actor = target
	damage = amount
	damage_category = category
	speed = maxf(0.1, projectile_speed)
	var source_identity := source.get_node_or_null("CombatActor") as CombatActor if source != null else null
	if source_identity != null:
		source_team = source_identity.team
		projectile_style = source_identity.actor_kind
	if is_node_ready():
		_apply_style()

func _apply_style() -> void:
	if _visual == null:
		return
	match projectile_style:
		&"tower":
			_visual.material_override = TOWER_MATERIAL
			_visual.scale = Vector3.ONE * 1.5
			if _trail != null:
				_trail.material_override = TOWER_MATERIAL
		&"minion":
			_visual.material_override = MINION_MATERIAL
			_visual.scale = Vector3.ONE * 1.0
			if _trail != null:
				_trail.material_override = MINION_MATERIAL
		_:
			_visual.material_override = HERO_MATERIAL
			_visual.scale = Vector3.ONE * 1.15
			if _trail != null:
				_trail.material_override = HERO_MATERIAL

func _physics_process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= lifetime or not is_instance_valid(target_actor) or not target_actor.is_alive():
		queue_free()
		return
	var target_position := target_actor.world_position() + Vector3.UP * 0.7
	var offset := target_position - global_position
	var distance := offset.length()
	if distance > 0.001:
		look_at(global_position + offset.normalized(), Vector3.UP)
	var travel := speed * delta
	if distance <= maxf(impact_radius, travel):
		_impact()
		return
	if distance > 0.001:
		global_position += offset / distance * travel

func _create_trail() -> void:
	_trail = MeshInstance3D.new()
	_trail.name = "ProjectileTrail"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.085, 0.085, 0.58)
	_trail.mesh = mesh
	_trail.position.z = 0.34
	add_child(_trail)

func _spawn_impact(at: Vector3) -> void:
	var flash := MeshInstance3D.new()
	flash.name = "ProjectileImpact"
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.18
	mesh.outer_radius = 0.25
	flash.mesh = mesh
	flash.material_override = IMPACT_MATERIAL
	flash.rotation_degrees.x = 90.0
	var scene := get_tree().current_scene
	(scene if scene != null else get_tree().root).add_child(flash)
	flash.global_position = at + Vector3.UP * 0.08
	var tween := flash.create_tween()
	tween.tween_property(flash, "scale", Vector3(2.6, 2.6, 2.6), 0.22)
	tween.parallel().tween_property(flash, "transparency", 1.0, 0.22)
	tween.tween_callback(flash.queue_free)

func _impact() -> void:
	if not is_instance_valid(target_actor) or not target_actor.is_alive():
		queue_free()
		return
	if not TeamRules.are_hostile(source_team, target_actor.team):
		queue_free()
		return
	var source := source_actor if is_instance_valid(source_actor) else null
	target_actor.receive_damage(damage, source, damage_category)
	_spawn_impact(target_actor.world_position())
	queue_free()
