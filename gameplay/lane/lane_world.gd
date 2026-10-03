class_name LaneWorld
extends Node3D
## Owns lane services and map scaffolding; unit AI only queries the cached roster.

const MINION_SCENE := preload("res://gameplay/lane/minion_actor.tscn")
const TOWER_SCENE := preload("res://gameplay/lane/tower_actor.tscn")
const MELEE_DEFINITION := preload("res://gameplay/lane/melee_minion.tres")
const RANGED_DEFINITION := preload("res://gameplay/lane/ranged_minion.tres")
const DEFAULT_TOWER_DEFINITION := preload("res://gameplay/lane/tower_prototype.tres")
const SPAWNER_SCRIPT := preload("res://gameplay/lane/wave_spawner.gd")
const LANE_STONE: Material = preload("res://gameplay/presentation/materials/lane_stone.tres")
const TEAM_A_LANE: Material = preload("res://gameplay/presentation/materials/lane_team_a.tres")
const TEAM_B_LANE: Material = preload("res://gameplay/presentation/materials/lane_team_b.tres")
const RIDGE_MATERIAL: Material = preload("res://gameplay/presentation/materials/rock_dark.tres")

@export var tuning: LaneTuning
@export var tower_definition: TowerDefinition
@export_range(1.0, 120.0, 0.1) var wave_interval: float = 18.0
@export_range(0.0, 30.0, 0.1) var first_wave_delay: float = 2.0
@export_range(0.0, 5.0, 0.05) var unit_spacing: float = 0.35
@export_range(1, 8, 1) var melee_per_wave: int = 3
@export_range(0, 8, 1) var ranged_per_wave: int = 1
var roster: LaneCombatRoster
var lane_path: LanePath
var team_a_spawner: WaveSpawner
var team_b_spawner: WaveSpawner
var team_a_tower: TowerActor
var team_b_tower: TowerActor

func _ready() -> void:
	name = "LaneWorld"
	if tuning != null:
		wave_interval = tuning.wave_interval
		first_wave_delay = tuning.first_wave_delay
		unit_spacing = tuning.minion_spacing
		var progression := get_node_or_null("../Player/Progression") as HeroProgression
		if progression != null:
			progression.xp_radius = tuning.xp_radius
	if tower_definition == null:
		tower_definition = DEFAULT_TOWER_DEFINITION
	roster = LaneCombatRoster.new()
	roster.name = "CombatRoster"
	add_child(roster)
	lane_path = LanePath.new()
	lane_path.name = "LanePath"
	add_child(lane_path)
	team_a_tower = _create_tower("TeamATower", TeamRules.Team.TEAM_A, Vector3(-22.0, 0.0, 0.0))
	team_b_tower = _create_tower("TeamBTower", TeamRules.Team.TEAM_B, Vector3(22.0, 0.0, 0.0))
	team_a_spawner = _create_spawner("TeamAWaves", TeamRules.Team.TEAM_A)
	team_b_spawner = _create_spawner("TeamBWaves", TeamRules.Team.TEAM_B)
	_build_lane_strips()

func _create_tower(tower_name: String, team: TeamRules.Team, at: Vector3) -> TowerActor:
	var tower := TOWER_SCENE.instantiate() as TowerActor
	tower.name = tower_name
	tower.team = team
	tower.definition = tower_definition
	tower.position = at
	add_child(tower)
	return tower

func _create_spawner(spawner_name: String, team: TeamRules.Team) -> WaveSpawner:
	var spawner_node := Node.new()
	spawner_node.set_script(SPAWNER_SCRIPT)
	var spawner := spawner_node as WaveSpawner
	spawner.name = spawner_name
	spawner.team = team
	spawner.lane_path = lane_path
	spawner.minion_scene = MINION_SCENE
	spawner.melee_definition = MELEE_DEFINITION
	spawner.ranged_definition = RANGED_DEFINITION
	spawner.spawn_interval = wave_interval
	spawner.first_wave_delay = first_wave_delay
	spawner.unit_spacing = unit_spacing
	spawner.melee_count = melee_per_wave
	spawner.ranged_count = ranged_per_wave
	add_child(spawner)
	return spawner

func _build_lane_strips() -> void:
	for side in 2:
		var platform := MeshInstance3D.new()
		var platform_mesh := CylinderMesh.new()
		platform_mesh.top_radius = 3.3
		platform_mesh.bottom_radius = 3.55
		platform_mesh.height = 0.045
		platform.mesh = platform_mesh
		platform.position = Vector3(-22.0 if side == 0 else 22.0, -0.025, 0.0)
		platform.material_override = TEAM_A_LANE if side == 0 else TEAM_B_LANE
		platform.name = "TeamTowerApproach"
		add_child(platform)
	_add_team_label("TEAM A", Vector3(-17.0, 0.18, -4.7), Color(0.42, 0.78, 1.0))
	_add_team_label("TEAM B", Vector3(17.0, 0.18, -4.7), Color(1.0, 0.53, 0.42))
	var lane := MeshInstance3D.new()
	var lane_mesh := BoxMesh.new()
	lane_mesh.size = Vector3(39.0, 0.025, 8.0)
	lane.mesh = lane_mesh
	lane.position = Vector3(0.0, 0.025, 0.0)
	lane.material_override = LANE_STONE
	var edge_mesh := BoxMesh.new()
	edge_mesh.size = Vector3(39.0, 0.11, 0.18)
	for side in [-1.0, 1.0]:
		var edge := MeshInstance3D.new()
		edge.name = "LaneEdge"
		edge.mesh = edge_mesh
		edge.position = Vector3(0.0, 0.055, side * 4.1)
		edge.material_override = RIDGE_MATERIAL
		add_child(edge)
	add_child(lane)
	var center_material := StandardMaterial3D.new()
	center_material.albedo_color = Color(0.62, 0.57, 0.38)
	for index in 7:
		var dash := MeshInstance3D.new()
		var dash_mesh := BoxMesh.new()
		dash_mesh.size = Vector3(1.0, 0.035, 0.075)
		dash.mesh = dash_mesh
		dash.position = Vector3(-15.0 + float(index) * 5.0, 0.052, 0.0)
		dash.material_override = center_material
		add_child(dash)
	var team_a_marker := StandardMaterial3D.new()
	team_a_marker.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	team_a_marker.albedo_color = Color(0.25, 0.66, 1.0, 0.82)
	team_a_marker.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var team_b_marker := StandardMaterial3D.new()
	team_b_marker.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	team_b_marker.albedo_color = Color(1.0, 0.35, 0.28, 0.82)
	team_b_marker.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for index in 3:
		_add_direction_chevron(Vector3(-15.0 + float(index) * 5.0, 0.07, -3.2), 1.0, team_a_marker)
		_add_direction_chevron(Vector3(15.0 - float(index) * 5.0, 0.07, 3.2), -1.0, team_b_marker)

func _add_direction_chevron(at: Vector3, direction: float, material: Material) -> void:
	for side in [-1.0, 1.0]:
		var segment := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.62, 0.035, 0.085)
		segment.mesh = mesh
		segment.position = at + Vector3(direction * 0.12, 0.0, float(side) * 0.22)
		segment.rotation.y = -float(side) * 0.64 if direction > 0.0 else PI + float(side) * 0.64
		segment.material_override = material
		add_child(segment)

func _add_team_label(label_text: String, at: Vector3, tint: Color) -> void:
	var label := Label3D.new()
	label.text = label_text
	label.font_size = 64
	label.pixel_size = 0.006
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = tint
	label.outline_size = 8
	label.position = at
	add_child(label)
