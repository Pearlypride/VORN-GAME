class_name ActorReadability
extends Node3D
## Minimal world-space health bar and transient damage number presentation.

@export var stats_path: NodePath = ^"../Stats"
@export var bar_width: float = 1.2
@export var height_offset: float = 2.0
var _stats: ActorStats
var _fill: MeshInstance3D
var _bar_root: Node3D

func _ready() -> void:
	_stats = get_node_or_null(stats_path) as ActorStats
	if _stats == null:
		return
	_build_bar()
	_stats.health_changed.connect(_on_health_changed)
	_stats.damage_received.connect(_on_damage_received)
	_on_health_changed(_stats.current_health, _stats.max_health)

func _build_bar() -> void:
	_bar_root = Node3D.new()
	_bar_root.name = "WorldHealthBar"
	_bar_root.position = Vector3.UP * height_offset
	add_child(_bar_root)
	var back := MeshInstance3D.new()
	var back_mesh := BoxMesh.new()
	back_mesh.size = Vector3(bar_width, 0.11, 0.06)
	back.mesh = back_mesh
	var back_material := StandardMaterial3D.new()
	back_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	back_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	back_material.albedo_color = Color(0.08, 0.08, 0.1, 0.9)
	back.material_override = back_material
	_bar_root.add_child(back)
	_fill = MeshInstance3D.new()
	_fill.name = "HealthFill"
	var fill_mesh := BoxMesh.new()
	fill_mesh.size = Vector3(bar_width, 0.075, 0.075)
	_fill.mesh = fill_mesh
	var fill_material := StandardMaterial3D.new()
	fill_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fill_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	var identity := get_parent().get_node_or_null("CombatActor") as CombatActor
	fill_material.albedo_color = Color(0.2, 0.78, 1.0) if identity != null and identity.team == TeamRules.Team.TEAM_A else Color(1.0, 0.28, 0.2)
	_fill.material_override = fill_material
	_bar_root.add_child(_fill)

func _on_health_changed(current: float, maximum: float) -> void:
	if _fill == null:
		return
	var ratio := clampf(current / maxf(1.0, maximum), 0.0, 1.0)
	_fill.scale.x = maxf(0.001, ratio)
	_fill.position.x = (ratio - 1.0) * bar_width * 0.5
	_bar_root.visible = current > 0.0

func _on_damage_received(event: DamageEvent) -> void:
	if event == null or event.amount <= 0.0:
		return
	var number := Label3D.new()
	number.text = str(roundi(event.amount))
	number.font_size = 32
	number.modulate = Color(1.0, 0.82, 0.56)
	number.outline_size = 5
	number.position = get_parent().global_position + Vector3.UP * (height_offset + 0.2)
	var root := get_tree().current_scene if get_tree().current_scene != null else get_tree().root
	root.add_child(number)
	var tween := number.create_tween()
	tween.tween_property(number, "position:y", number.position.y + 0.65, 0.5)
	tween.parallel().tween_property(number, "modulate:a", 0.0, 0.5)
	tween.tween_callback(number.queue_free)
