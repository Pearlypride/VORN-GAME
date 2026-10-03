extends SceneTree
## Structural Phase 7 checks plus regression suites. Does not grade visual quality.

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
	var stats := player.get_node("Stats") as ActorStats
	var abilities := player.get_node("AbilityController") as AbilityController
	var combat := player.get_node("Combat") as CombatComponent
	var hud := arena.get_node("MobaHUD") as MobaHUD
	var debug_hud := arena.get_node("HUD") as CanvasLayer
	var normal_hud := arena.get_node("MobaHUD/NormalHUD") as Control
	var lane := arena.get_node("LaneWorld") as LaneWorld
	_check(normal_hud != null, "A: normal gameplay HUD exists")
	_check(not debug_hud.visible, "B: development HUD is hidden by default")
	hud.toggle_debug()
	var shown := debug_hud.visible
	hud.toggle_debug()
	_check(shown and not debug_hud.visible, "C: debug HUD toggle works")

	var hero_model := player.get_node("Visual/CharacterModel") as Node3D
	_check(player.hero_definition.hero_name == "KARN" and hero_model != null and hero_model.visible, "D: KARN identity and presentation are active")
	var presentation := player.get_node("ActorPresentation") as ActorPresentation
	player.move_to(player.global_position + Vector3(3.0, 0.0, 0.0))
	await create_timer(0.2).timeout
	_check(presentation.current_state == ActorPresentation.VisualState.MOVE, "E: hero presentation still mirrors locomotion")
	player.stop_command()
	player.global_position = Vector3.ZERO
	player.velocity = Vector3.ZERO

	var melee := MINION_SCENE.instantiate() as MinionActor
	melee.definition = MELEE_DEF
	var ranged := MINION_SCENE.instantiate() as MinionActor
	ranged.definition = RANGED_DEF
	arena.add_child(melee)
	arena.add_child(ranged)
	await process_frame
	await process_frame
	_check(melee.get_node("Visual/CharacterModel").has_node("ShortBlade") and ranged.get_node("Visual/CharacterModel").has_node("StaffCore"), "F: melee and ranged minion visual types differ")
	_check(lane.team_a_tower.get_node("Visual/TowerModel").has_node("EmitterCore"), "G: tower presentation includes its emitter")

	var initial_time := hud.match_seconds
	await create_timer(0.18).timeout
	_check(hud.match_seconds > initial_time, "H: match clock advances")
	var q_button := normal_hud.get_node("AbilityButtons/AbilityQ") as Button
	var w_button := normal_hud.get_node("AbilityButtons/AbilityW") as Button
	var e_button := normal_hud.get_node("AbilityButtons/AbilityE") as Button
	var r_button := normal_hud.get_node("AbilityButtons/AbilityR") as Button
	_check(q_button.text.contains("REND") and w_button.text.contains("BREAKLINE") and e_button.text.contains("WAR RING") and r_button.text.contains("REDLINE"), "I: HUD labels show the KARN kit")

	var dummy := arena.get_node("Dummy1") as Node3D
	var dummy_stats := dummy.get_node("Stats") as ActorStats
	dummy.global_position = Vector3(2.0, 0.8, 0.0)
	dummy_stats.restore_full_health()
	abilities.request_cast(&"q")
	var q_cast := abilities.confirm_target(dummy)
	_check(q_cast and root.find_child("RendSlashVFX", true, false) != null, "J: Rend successful-cast VFX path fires")
	abilities.request_cast(&"w")
	var w_cast := abilities.confirm_point(Vector3(5.0, 0.0, 0.0))
	_check(w_cast and get_nodes_in_group("ability_projectile").size() == 1, "K: Breakline launches its distinct projectile")
	abilities.request_cast(&"e")
	var e_cast := abilities.confirm_point(Vector3(2.0, 0.0, 0.0))
	_check(e_cast and root.find_child("WarRingVFX", true, false) != null, "L: War Ring VFX path fires")
	abilities.request_cast(&"r")
	_check(abilities.get_ability_state(&"r") == AbilityController.AbilityState.COOLDOWN and player.get_node("Visual/RedlineAura").visible, "M: Redline gameplay state drives its aura")

	var minimap := normal_hud.get_node("MinimapPanel/VBoxContainer/LaneMinimap") if normal_hud.has_node("MinimapPanel/VBoxContainer/LaneMinimap") else normal_hud.find_child("LaneMinimap", true, false)
	_check(minimap != null, "N: vector lane minimap node exists")
	player.move_to(Vector3(2.5, 0.0, 0.0))
	player.attack_target(arena.get_node("Dummy3") as Node3D)
	await process_frame
	_check(hud.target_panel.visible and hud.target_name.text == "DUMMY3", "O: target selection updates the selected-unit panel")
	var ability_row := normal_hud.get_node("AbilityButtons") as Control
	var hero_panel := normal_hud.get_node("HeroStatus") as Control
	_check(normal_hud.anchor_left == 0.0 and normal_hud.anchor_right == 1.0 and ability_row.anchor_right == 1.0 and hero_panel.anchor_bottom == 1.0, "P: major HUD regions use responsive anchors")

	var window := root as Window
	for viewport_size in [Vector2i(1920, 1080), Vector2i(1600, 900), Vector2i(1280, 720), Vector2i(2340, 1080)]:
		window.size = viewport_size
		await process_frame
		var ability_rect := ability_row.get_global_rect()
		var joystick_rect := (normal_hud.get_node("MovementControlPlaceholder") as Control).get_global_rect()
		_check(ability_rect.position.x >= 0.0 and ability_rect.end.x <= float(viewport_size.x) and joystick_rect.position.y >= 0.0, "P: anchored HUD remains in %dx%d bounds" % [viewport_size.x, viewport_size.y])

	melee.queue_free()
	ranged.queue_free()
	arena.queue_free()
	await process_frame
	for entry in [
		["Q", "Phase 2", "res://tests/phase2_validation.gd"],
		["R", "Phase 3", "res://tests/phase3_ability_validation.gd"],
		["S", "Phase 4", "res://tests/phase4_lane_validation.gd"],
		["T", "Phase 5", "res://tests/phase5_combat_validation.gd"],
		["U", "Phase 6", "res://tests/phase6_presentation_validation.gd"],
	]:
		_run_subprocess(entry[0], entry[1], ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", entry[2]])
	_run_subprocess("V", "headless parser/runtime smoke", ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--quit-after", "90"])
	print("PHASE7_RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
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
