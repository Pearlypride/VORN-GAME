extends SceneTree
## Structural presentation checks plus the earlier phase suites. Does not judge visual quality.

const ARENA := preload("res://world/maps/dev_arena.tscn")
const MINION_SCENE := preload("res://gameplay/lane/minion_actor.tscn")
const MELEE_DEF := preload("res://gameplay/lane/melee_minion.tres")
const RANGED_DEF := preload("res://gameplay/lane/ranged_minion.tres")
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var arena := ARENA.instantiate() as Node3D
	root.add_child(arena)
	await process_frame
	await process_frame
	var player := arena.get_node("Player") as PlayerController
	var presentation := player.get_node("ActorPresentation") as ActorPresentation
	var stats := player.get_node("Stats") as ActorStats
	var attacks := player.get_node("BasicAttackController") as BasicAttackController
	var abilities := player.get_node("AbilityController") as AbilityController
	var feedback := arena.get_node("AbilityTargetingFeedback") as Node3D
	var lane := arena.get_node("LaneWorld") as LaneWorld
	lane.team_a_spawner._timer.stop()
	lane.team_b_spawner._timer.stop()
	for tower in [lane.team_a_tower, lane.team_b_tower]:
		tower.set_physics_process(false)

	_check(presentation.current_state == ActorPresentation.VisualState.IDLE, "A: presentation enters IDLE")
	player.move_to(player.global_position + Vector3(12.0, 0.0, 0.0))
	await create_timer(0.18).timeout
	_check(presentation.current_state == ActorPresentation.VisualState.MOVE, "B: MOVE exposed during movement")
	player.stop_command()
	player.global_position = Vector3.ZERO
	player.velocity = Vector3.ZERO

	var target := arena.get_node("Dummy1") as Node3D
	var target_stats := target.get_node("Stats") as ActorStats
	target.global_position = Vector3(1.5, 0.8, 0.0)
	target_stats.restore_full_health()
	stats.attack_range = 8.0
	attacks.configure(BasicAttackController.AttackType.MELEE, 0.20, 0.14, 12.0)
	player.attack_target(target)
	player.get_node("Combat")._physics_process(0.016)
	_check(presentation.current_state == ActorPresentation.VisualState.ATTACK_WINDUP, "C: attack windup exposed")
	attacks._physics_process(0.21)
	_check(presentation.current_state == ActorPresentation.VisualState.ATTACK_RELEASE, "D: attack release exposed")
	attacks._physics_process(0.081)
	_check(presentation.current_state == ActorPresentation.VisualState.ATTACK_RECOVERY, "E: recovery exposed")

	var source := target
	stats.apply_damage(1.0, source, DamageEvent.OTHER)
	_check(presentation.current_state == ActorPresentation.VisualState.HIT, "F: damage event reaches presentation")
	var lifecycle := player.get_node("HeroLifecycle") as HeroLifecycle
	lifecycle.respawn_delay = 0.25
	stats.apply_damage(stats.current_health, source, DamageEvent.OTHER)
	_check(presentation.current_state == ActorPresentation.VisualState.DEATH, "G: death state exposed")
	var health_bar := player.get_node("ActorReadability/WorldHealthBar") as Node3D
	_check(not health_bar.visible, "L: attack/death feedback is not left visible after death")
	_check(not attacks.get_node("AttackStateMarker").visible, "L: attack indicator clears on death")
	await create_timer(0.38).timeout
	_check(presentation.current_state == ActorPresentation.VisualState.IDLE and stats.current_health > 0.0, "H: respawn restores IDLE presentation")

	var progression := player.get_node("Progression") as HeroProgression
	var level_before := progression.level
	progression.grant_xp(progression.xp_required())
	_check(progression.level == level_before + 1 and player.get_node("Visual").has_node("LevelUpPulse"), "I: level-up event drives feedback")

	var range_ring := feedback.get_node("CastRangeRing") as MeshInstance3D
	player.global_position = Vector3.ZERO
	abilities.request_cast(&"q")
	await process_frame
	_check(range_ring.visible, "J: targeting indicator appears and clears on cast")
	var cast_target := arena.get_node("Dummy2") as Node3D
	cast_target.global_position = Vector3(2.0, 0.8, 0.0)
	(cast_target.get_node("Stats") as ActorStats).restore_full_health()
	var cast_succeeded := abilities.confirm_target(cast_target)
	await process_frame
	_check(cast_succeeded and not range_ring.visible, "J: cast clears targeting indicators")
	abilities.request_cast(&"w")
	await process_frame
	var aim_line := feedback.get_node("AimLine") as MeshInstance3D
	abilities.cancel_targeting()
	await process_frame
	_check(not range_ring.visible and not aim_line.visible, "K: cancel clears targeting indicators")

	var model := player.get_node("Visual/CharacterModel")
	var rig_adapter := model as KarnRigAdapter
	var rig_valid := rig_adapter != null and rig_adapter.has_clip(&"IDLE") and rig_adapter.has_clip(&"ATTACK_1")
	var primitive_valid := model.has_node("Torso") and model.has_node("Head") and model.has_node("WeaponPivot/WeaponHead")
	_check(rig_valid or primitive_valid, "M: humanoid KARN model or primitive fallback exists")
	var melee := MINION_SCENE.instantiate() as MinionActor
	melee.definition = MELEE_DEF
	melee.name = "Phase6Melee"
	var ranged := MINION_SCENE.instantiate() as MinionActor
	ranged.definition = RANGED_DEF
	ranged.name = "Phase6Ranged"
	arena.add_child(melee)
	arena.add_child(ranged)
	await process_frame
	await process_frame
	_check(melee.get_node("Visual/CharacterModel").has_node("ShortBlade") and ranged.get_node("Visual/CharacterModel").has_node("StaffCore"), "N: melee and ranged minion silhouettes differ")
	var tower_model := lane.team_a_tower.get_node("Visual/TowerModel") as Node3D
	_check(tower_model.has_node("Emitter") and tower_model.has_node("UpperPlatform"), "O: tower presentation has raised emitter")

	melee.queue_free()
	ranged.queue_free()
	arena.queue_free()
	await process_frame

	for entry in [
		["P", "Phase 2", "res://tests/phase2_validation.gd"],
		["Q", "Phase 3", "res://tests/phase3_ability_validation.gd"],
		["R", "Phase 4", "res://tests/phase4_lane_validation.gd"],
		["S", "Phase 5", "res://tests/phase5_combat_validation.gd"],
	]:
		_run_subprocess(entry[0], entry[1], ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", entry[2]])
	_run_subprocess("T", "headless parser/runtime smoke", ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--quit-after", "60"])
	print("PHASE6_RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)

func _run_subprocess(letter: String, label: String, arguments: PackedStringArray) -> void:
	var output: Array[String] = []
	var exit_code := OS.execute(OS.get_executable_path(), arguments, output, true)
	var transcript := "\n".join(output)
	var clean := exit_code == 0 and not transcript.contains("SCRIPT ERROR") and not transcript.contains("ERROR:") and not transcript.contains("Parse Error")
	_check(clean, "%s: %s" % [letter, label])
	if not clean:
		push_error("%s subprocess exit=%d output:\n%s" % [label, exit_code, transcript])
