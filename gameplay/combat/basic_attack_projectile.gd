class_name BasicAttackProjectile
extends Area3D
## Tracking basic-attack projectile. A dead/removed target makes it expire without damage.

const HERO_MATERIAL: Material = preload("res://gameplay/presentation/materials/projectile_hero.tres")
const MINION_MATERIAL: Material = preload("res://gameplay/presentation/materials/projectile_minion.tres")
const TOWER_MATERIAL: Material = preload("res://gameplay/presentation/materials/projectile_tower.tres")

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

func _ready() -> void:
	add_to_group("basic_attack_projectile")
	_visual = $Visual as MeshInstance3D
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
		&"minion":
			_visual.material_override = MINION_MATERIAL
			_visual.scale = Vector3.ONE * 1.0
		_:
			_visual.material_override = HERO_MATERIAL
			_visual.scale = Vector3.ONE * 1.15

func _physics_process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= lifetime or not is_instance_valid(target_actor) or not target_actor.is_alive():
		queue_free()
		return
	var target_position := target_actor.world_position() + Vector3.UP * 0.7
	var offset := target_position - global_position
	var distance := offset.length()
	var travel := speed * delta
	if distance <= maxf(impact_radius, travel):
		_impact()
		return
	if distance > 0.001:
		global_position += offset / distance * travel

func _impact() -> void:
	if not is_instance_valid(target_actor) or not target_actor.is_alive():
		queue_free()
		return
	if not TeamRules.are_hostile(source_team, target_actor.team):
		queue_free()
		return
	var source := source_actor if is_instance_valid(source_actor) else null
	target_actor.receive_damage(damage, source, damage_category)
	queue_free()
