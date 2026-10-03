class_name ActorReadability
extends Node3D
## World-space bars and restrained damage labels driven only by gameplay stat events.

const TEAM_A_BAR_MATERIAL: Material = preload("res://gameplay/presentation/materials/healthbar_team_a.tres")
const TEAM_B_BAR_MATERIAL: Material = preload("res://gameplay/presentation/materials/healthbar_team_b.tres")
const BACKGROUND_MATERIAL: Material = preload("res://gameplay/presentation/materials/healthbar_background.tres")
const MANA_MATERIAL: Material = preload("res://gameplay/presentation/materials/mana_bar.tres")

@export var stats_path: NodePath = ^"../Stats"
@export var bar_width: float = 1.2
@export var height_offset: float = 2.0
var _stats: ActorStats
var _fill: MeshInstance3D
var _bar_root: Node3D
var _mana_root: Node3D
var _mana_fill: MeshInstance3D
var _level_label: Label3D

func _ready() -> void:
	_stats = get_node_or_null(stats_path) as ActorStats
	if _stats == null:
		return
	_build_bar()
	_stats.health_changed.connect(_on_health_changed)
	_stats.damage_received.connect(_on_damage_received)
	_stats.mana_changed.connect(_on_mana_changed)
	_on_health_changed(_stats.current_health, _stats.max_health)
	_on_mana_changed(_stats.current_mana, _stats.max_mana)

func _build_bar() -> void:
	_bar_root = Node3D.new()
	_bar_root.name = "WorldHealthBar"
	_bar_root.position = Vector3.UP * height_offset
	add_child(_bar_root)
	var back := _make_bar_mesh("HealthBack", bar_width, 0.105, BACKGROUND_MATERIAL)
	_bar_root.add_child(back)
	_fill = _make_bar_mesh("HealthFill", bar_width, 0.074, _team_material())
	_fill.position.y = 0.01
	_bar_root.add_child(_fill)
	var identity := get_parent().get_node_or_null("CombatActor") as CombatActor
	if identity != null and identity.actor_kind == &"hero":
		_level_label = Label3D.new()
		_level_label.name = "LevelBadge"
		_level_label.text = "1"
		_level_label.font_size = 30
		_level_label.pixel_size = 0.007
		_level_label.modulate = Color("#f1c77e")
		_level_label.outline_size = 6
		_level_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_level_label.position = Vector3(-bar_width * 0.62, 0.04, 0.02)
		_bar_root.add_child(_level_label)
		var progression := get_parent().get_node_or_null("Progression") as HeroProgression
		if progression != null:
			progression.level_up.connect(_on_level_up)
		_build_mana_bar()

func _build_mana_bar() -> void:
	_mana_root = Node3D.new()
	_mana_root.name = "WorldManaBar"
	_mana_root.position = Vector3(0.0, -0.13, 0.015)
	_bar_root.add_child(_mana_root)
	_mana_root.add_child(_make_bar_mesh("ManaBack", bar_width, 0.055, BACKGROUND_MATERIAL))
	_mana_fill = _make_bar_mesh("ManaFill", bar_width, 0.035, MANA_MATERIAL)
	_mana_fill.position.y = 0.008
	_mana_root.add_child(_mana_fill)

func _make_bar_mesh(node_name: String, width: float, height: float, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = Vector3(width, height, 0.06)
	instance.mesh = mesh
	instance.material_override = material
	return instance

func configure_team(team: TeamRules.Team) -> void:
	if _fill != null:
		_fill.material_override = TEAM_A_BAR_MATERIAL if team == TeamRules.Team.TEAM_A else TEAM_B_BAR_MATERIAL

func _team_material() -> Material:
	var identity := get_parent().get_node_or_null("CombatActor") as CombatActor
	return TEAM_A_BAR_MATERIAL if identity == null or identity.team == TeamRules.Team.TEAM_A else TEAM_B_BAR_MATERIAL

func _on_health_changed(current: float, maximum: float) -> void:
	if _fill == null:
		return
	var ratio := clampf(current / maxf(1.0, maximum), 0.0, 1.0)
	_fill.scale.x = maxf(0.001, ratio)
	_fill.position.x = (ratio - 1.0) * bar_width * 0.5
	_bar_root.visible = current > 0.0

func _on_mana_changed(current: float, maximum: float) -> void:
	if _mana_fill == null:
		return
	var ratio := clampf(current / maxf(1.0, maximum), 0.0, 1.0)
	_mana_fill.scale.x = maxf(0.001, ratio)
	_mana_fill.position.x = (ratio - 1.0) * bar_width * 0.5

func _on_level_up(level: int) -> void:
	if is_instance_valid(_level_label):
		_level_label.text = str(level)

func _on_damage_received(event: DamageEvent) -> void:
	if event == null or event.amount <= 0.0:
		return
	var identity := get_parent().get_node_or_null("CombatActor") as CombatActor
	# Keep lane combat legible: floating numbers are reserved for the player hero and towers.
	if identity != null and identity.actor_kind not in [&"hero", &"tower"]:
		return
	var number := Label3D.new()
	number.text = str(roundi(event.amount))
	number.font_size = 34
	number.pixel_size = 0.009
	number.modulate = Color(1.0, 0.77, 0.58)
	number.outline_size = 7
	number.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	number.position = get_parent().global_position + Vector3.UP * (height_offset + 0.28)
	var root := get_tree().current_scene if get_tree().current_scene != null else get_tree().root
	root.add_child(number)
	var tween := number.create_tween()
	tween.tween_property(number, "position:y", number.position.y + 0.58, 0.48)
	tween.parallel().tween_property(number, "modulate:a", 0.0, 0.48)
	tween.tween_callback(number.queue_free)
