class_name LaneWorld
extends Node3D
## Owns lane services and map scaffolding; unit AI only queries the cached roster.

const MINION_SCENE := preload("res://gameplay/lane/minion_actor.tscn")
const TOWER_SCENE := preload("res://gameplay/lane/tower_actor.tscn")
const MELEE_DEFINITION := preload("res://gameplay/lane/melee_minion.tres")
const RANGED_DEFINITION := preload("res://gameplay/lane/ranged_minion.tres")
const SPAWNER_SCRIPT := preload("res://gameplay/lane/wave_spawner.gd")

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
	roster = LaneCombatRoster.new()
	roster.name = "CombatRoster"
	add_child(roster)
	lane_path = LanePath.new()
	lane_path.name = "LanePath"
	add_child(lane_path)
	team_a_tower = _create_tower("TeamATower", TeamRules.Team.TEAM_A, Vector3(-22.0, 0.0, 0.0), Color(0.14, 0.45, 0.9))
	team_b_tower = _create_tower("TeamBTower", TeamRules.Team.TEAM_B, Vector3(22.0, 0.0, 0.0), Color(0.9, 0.24, 0.2))
	team_a_spawner = _create_spawner("TeamAWaves", TeamRules.Team.TEAM_A)
	team_b_spawner = _create_spawner("TeamBWaves", TeamRules.Team.TEAM_B)
	_build_lane_strips()

func _create_tower(tower_name: String, team: TeamRules.Team, at: Vector3, tint: Color) -> TowerActor:
	var tower := TOWER_SCENE.instantiate() as TowerActor
	tower.name = tower_name
	tower.team = team
	tower.position = at
	add_child(tower)
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	(tower.get_node("Visual") as MeshInstance3D).material_override = material
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
		var strip := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(17.0, 0.035, 11.5)
		strip.mesh = mesh
		strip.position = Vector3(-21.5 if side == 0 else 21.5, 0.015, 0.0)
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.12, 0.28, 0.45) if side == 0 else Color(0.43, 0.15, 0.14)
		strip.material_override = material
		add_child(strip)
	var lane := MeshInstance3D.new()
	var lane_mesh := BoxMesh.new()
	lane_mesh.size = Vector3(39.0, 0.025, 8.0)
	lane.mesh = lane_mesh
	lane.position = Vector3(0.0, 0.025, 0.0)
	var lane_material := StandardMaterial3D.new()
	lane_material.albedo_color = Color(0.26, 0.28, 0.27)
	lane.material_override = lane_material
	add_child(lane)
