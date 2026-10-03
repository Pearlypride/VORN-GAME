class_name WaveSpawner
extends Node

@export var team: TeamRules.Team = TeamRules.Team.TEAM_A
@export var lane_path: LanePath
@export var minion_scene: PackedScene
@export var melee_definition: MinionDefinition
@export var ranged_definition: MinionDefinition
@export_range(0.1, 120.0, 0.1) var spawn_interval: float = 18.0
@export_range(0.0, 30.0, 0.1) var first_wave_delay: float = 2.0
@export_range(0.0, 5.0, 0.05) var unit_spacing: float = 0.35
@export_range(1, 8, 1) var melee_count: int = 3
@export_range(0, 8, 1) var ranged_count: int = 1
var wave_number: int = 0
var _timer: Timer
var _spawn_epoch: int = 0

func _ready() -> void:
	_timer = Timer.new()
	_timer.one_shot = true
	add_child(_timer)
	_timer.timeout.connect(_on_wave_timer)
	_timer.start(first_wave_delay)

func spawn_wave_now() -> Array[MinionActor]:
	wave_number += 1
	var spawned: Array[MinionActor] = []
	_spawn_epoch += 1
	var epoch := _spawn_epoch
	var units: Array[MinionDefinition] = []
	for index in melee_count:
		units.append(melee_definition)
	for index in ranged_count:
		units.append(ranged_definition)
	for index in units.size():
		if units[index] == null or minion_scene == null:
			continue
		var minion := minion_scene.instantiate() as MinionActor
		minion.configure(units[index], team, lane_path, float(index) * 0.8)
		get_parent().get_parent().add_child(minion)
		spawned.append(minion)
		if unit_spacing > 0.0 and index < units.size() - 1:
			await get_tree().create_timer(unit_spacing).timeout
			if epoch != _spawn_epoch:
				break
	return spawned

func force_next_wave() -> void:
	spawn_wave_now()

func _on_wave_timer() -> void:
	spawn_wave_now()
	_timer.start(spawn_interval)
