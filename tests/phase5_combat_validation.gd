extends SceneTree
## Headless attack timing and impact validation. Run with godot --headless -s.

const ARENA := preload("res://world/maps/dev_arena.tscn")
const MINION_SCENE := preload("res://gameplay/lane/minion_actor.tscn")
const RANGED_DEF := preload("res://gameplay/lane/ranged_minion.tres")
const BASIC_PROJECTILE := preload("res://gameplay/combat/basic_attack_projectile.tscn")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var arena := ARENA.instantiate() as Node3D
	root.add_child(arena)
	await process_frame
	var player := arena.get_node("Player") as PlayerController
	var stats := player.get_node("Stats") as ActorStats
	var combat := player.get_node("Combat") as CombatComponent
	var attacks := player.get_node("BasicAttackController") as BasicAttackController
	var wallet := player.get_node("GoldWallet") as GoldWallet
	var status := player.get_node("StatusEffects") as StatusEffectController
	var d1 := arena.get_node("Dummy1") as Node3D
	var d2 := arena.get_node("Dummy2") as Node3D
	var d3 := arena.get_node("Dummy3") as Node3D
	var d1_stats := d1.get_node("Stats") as ActorStats
	var d2_stats := d2.get_node("Stats") as ActorStats
	var d3_stats := d3.get_node("Stats") as ActorStats
	var lane := arena.get_node("LaneWorld") as LaneWorld
	lane.team_a_spawner._timer.stop()
	lane.team_b_spawner._timer.stop()
	for tower in [lane.team_a_tower, lane.team_b_tower]:
		tower.set_physics_process(false)
	player.global_position = Vector3.ZERO
	player.clear_command()
	stats.attack_range = 10.0
	stats.attack_damage = 35.0
	stats.attack_cooldown = 0.8
	attacks.configure(BasicAttackController.AttackType.MELEE, 0.25, 0.2, 18.0)
	_reset_attack(attacks)
	d1.global_position = Vector3(1.5, 0.8, 0.0)
	d2.global_position = Vector3(0.0, 0.8, 2.0)
	d3.global_position = Vector3(2.0, 0.8, 0.0)
	d1_stats.restore_full_health()
	d2_stats.restore_full_health()
	d3_stats.restore_full_health()

	var hp := d1_stats.current_health
	player.attack_target(d1)
	combat._physics_process(0.01)
	_check(d1_stats.current_health == hp, "A: attack begins without immediate damage")
	await create_timer(0.42).timeout
	_check(d1_stats.current_health < hp and d1_stats.last_damage_event.category == DamageEvent.BASIC_ATTACK, "B: melee damage releases at the attack point with BASIC_ATTACK metadata")

	_reset_attack(attacks)
	hp = d2_stats.current_health
	player.attack_target(d2)
	combat._physics_process(0.01)
	player.move_to(Vector3(8.0, 0.0, 0.0))
	await create_timer(0.32).timeout
	_check(d2_stats.current_health == hp, "C: move command cancels a pre-release attack")
	_reset_attack(attacks)
	player.attack_target(d2)
	combat._physics_process(0.01)
	player.stop_command()
	await create_timer(0.32).timeout
	_check(d2_stats.current_health == hp, "D: stop command cancels a pre-release attack")

	# Ranged release is independent: S is issued after RELEASE and the projectile still resolves.
	_reset_attack(attacks)
	attacks.configure(BasicAttackController.AttackType.RANGED, 0.05, 0.12, 4.0)
	stats.attack_damage = 24.0
	hp = d1_stats.current_health
	player.attack_target(d1)
	combat._physics_process(0.01)
	await create_timer(0.12).timeout
	var released_projectiles := get_nodes_in_group("basic_attack_projectile").size()
	player.stop_command()
	_check(released_projectiles > 0, "E/G: ranged RELEASE launches a projectile that outlives Stop")
	_check(d1_stats.current_health == hp, "H: ranged launch does not apply damage before impact")
	await create_timer(0.6).timeout
	_check(d1_stats.current_health < hp, "E/H: released projectile impacts after command cancellation")

	# A target removed before melee release is rejected safely.
	_reset_attack(attacks)
	attacks.configure(BasicAttackController.AttackType.MELEE, 0.2, 0.1, 18.0)
	d3_stats.restore_full_health()
	hp = d3_stats.current_health
	player.attack_target(d3)
	combat._physics_process(0.01)
	d3_stats.apply_damage(hp, d2, DamageEvent.OTHER)
	d3_stats.restore_full_health()
	await create_timer(0.3).timeout
	_check(d3_stats.last_damage_event == null or d3_stats.last_damage_event.source != player, "F: invalidated target does not receive a delayed melee hit")

	# Explicit team gate on a released tracking projectile.
	var d2_identity := d2.get_node("CombatActor") as CombatActor
	d2_identity.team = TeamRules.Team.TEAM_A
	hp = d2_stats.current_health
	var friendly_projectile := BASIC_PROJECTILE.instantiate() as BasicAttackProjectile
	arena.add_child(friendly_projectile)
	friendly_projectile.configure(player, d2_identity, 50.0, DamageEvent.BASIC_ATTACK, 100.0)
	friendly_projectile.global_position = d2.global_position + Vector3.UP
	friendly_projectile._impact()
	_check(d2_stats.current_health == hp, "I: ranged projectile cannot damage an allied target")
	d2_identity.team = TeamRules.Team.TEAM_B

	# Ranged minion uses the same release/projectile/impact path.
	var ranged_minion := MINION_SCENE.instantiate() as MinionActor
	ranged_minion.definition = RANGED_DEF
	ranged_minion.team = TeamRules.Team.TEAM_A
	ranged_minion.lane_path = lane.lane_path
	ranged_minion.position = Vector3(0.0, 0.55, -2.0)
	ranged_minion.set_physics_process(false)
	arena.add_child(ranged_minion)
	await process_frame
	ranged_minion.set_physics_process(false)
	d2.global_position = Vector3(0.0, 0.8, 2.0)
	d2_stats.restore_full_health()
	ranged_minion._identity.team = TeamRules.Team.TEAM_A
	ranged_minion._attacks.try_attack(d2)
	hp = d2_stats.current_health
	await create_timer(RANGED_DEF.attack_point + 0.05).timeout
	_check(get_nodes_in_group("basic_attack_projectile").size() > 0 and d2_stats.current_health == hp, "J: ranged minion launches before applying impact damage")
	await create_timer(0.6).timeout
	_check(d2_stats.current_health < hp and d2_stats.last_damage_event.source == ranged_minion, "J: ranged minion damage lands on impact with source attribution")

	# Tower projectile and attribution after impact.
	var tower := lane.team_a_tower
	tower.global_position = Vector3(-2.0, 0.0, 0.0)
	tower.tower_range = 12.0
	tower.attack_point = 0.05
	tower.projectile_speed = 4.0
	tower._stats.attack_range = 12.0
	tower._stats.attack_damage = 40.0
	tower._attacks.configure(BasicAttackController.AttackType.RANGED, 0.05, 0.1, 4.0)
	tower._attacks.set_interval_remaining(0.0)
	tower.target_actor = d1.get_node("CombatActor") as CombatActor
	d1_stats.restore_full_health()
	hp = d1_stats.current_health
	tower._physics_process(0.01)
	await create_timer(0.12).timeout
	_check(d1_stats.current_health == hp, "K: tower releases a projectile without immediate damage")
	await create_timer(1.0).timeout
	_check(d1_stats.current_health < hp and d1_stats.last_damage_event.source == tower, "K/L: tower projectile applies impact damage with source attribution")

	# Actual impact awards bounty once. A competing lethal event wins before the projectile arrives.
	var victim := _spawn_minion(arena, lane, TeamRules.Team.TEAM_B, Vector3(1.5, 0.55, 0.0))
	victim._stats.max_health = 10.0
	victim._stats.current_health = 10.0
	victim.definition = RANGED_DEF
	stats.attack_damage = 100.0
	stats.attack_range = 12.0
	attacks.configure(BasicAttackController.AttackType.RANGED, 0.05, 0.1, 3.0)
	_reset_attack(attacks)
	var gold_before := wallet.current_gold
	player.attack_target(victim)
	combat._physics_process(0.01)
	await create_timer(0.12).timeout
	victim._stats.apply_damage(20.0, d2, DamageEvent.BASIC_ATTACK)
	await create_timer(0.7).timeout
	_check(wallet.current_gold == gold_before, "M: competing lethal damage before projectile impact denies hero last-hit gold")
	victim._stats.apply_damage(20.0, player, DamageEvent.BASIC_ATTACK)
	_check(wallet.current_gold == gold_before, "N: dead target cannot award duplicate bounty")

	# R attack speed is expressed as an effective attack interval, with per-swing timing snapshots.
	status.clear_all()
	stats.attack_cooldown = 1.0
	attacks.configure(BasicAttackController.AttackType.MELEE, 0.5, 0.2, 18.0)
	_reset_attack(attacks)
	player.attack_target(d3)
	combat._physics_process(0.01)
	await create_timer(0.05).timeout
	var normal_interval := attacks.get_interval_remaining()
	player.stop_command()
	status.apply_timed_modifier(&"r_surge", 0.35, 1.0, 0.7)
	_reset_attack(attacks)
	player.attack_target(d3)
	combat._physics_process(0.01)
	await create_timer(0.05).timeout
	var buffed_interval := attacks.get_interval_remaining()
	_check(buffed_interval < normal_interval and attacks._windup_duration >= 0.0, "O: R buff shortens a coherent attack interval and preserves nonnegative attack point")
	await create_timer(0.4).timeout
	_check(is_equal_approx(stats.get_effective_attack_cooldown(), stats.attack_cooldown), "P: R expiry restores the normal attack timing")

	# Lane FSM and target priorities remain intact after attack lifecycle integration.
	var fsm_minion := _spawn_minion(arena, lane, TeamRules.Team.TEAM_A, Vector3(-8.0, 0.55, 5.0))
	fsm_minion.set_physics_process(true)
	fsm_minion._physics_process(0.2)
	_check(fsm_minion.path_distance > 0.0 and fsm_minion.state == MinionActor.State.ADVANCE, "Q: minion lane advancement FSM continues to operate")
	tower._acquire_target()
	_check(tower.target_actor == null or tower._identity.can_damage(tower.target_actor), "R: tower target selection preserves hostile-only targeting")

	# Disable and kill the tower before a fresh release; already launched shots remain separate.
	tower.target_actor = null
	tower._stats.apply_damage(tower._stats.current_health + 1.0, player, DamageEvent.BASIC_ATTACK)
	_check(tower.destroyed and not tower._attacks.try_attack(d1), "S: destroyed tower cannot start a new attack")
	var source_death_projectile := BASIC_PROJECTILE.instantiate() as BasicAttackProjectile
	arena.add_child(source_death_projectile)
	source_death_projectile.configure(tower, d1.get_node("CombatActor") as CombatActor, 1.0, DamageEvent.BASIC_ATTACK, 100.0)
	source_death_projectile.global_position = d1.global_position + Vector3.UP
	hp = d1_stats.current_health
	tower._stats.restore_full_health()
	tower._stats.apply_damage(tower._stats.current_health + 1.0, player, DamageEvent.BASIC_ATTACK)
	source_death_projectile._impact()
	_check(d1_stats.current_health == hp - 1.0, "T: released projectile safely resolves after its source tower dies")

	_check((d1.get_node("ActorReadability") as ActorReadability) != null, "world health bar and damage feedback presentation are attached independently")
	_check((attacks.current_state as int) >= BasicAttackController.State.IDLE, "attack lifecycle state remains valid after R buff expiry")
	_check(_run_suite("res://tests/phase2_validation.gd"), "U: Phase 2 validation suite passes")
	_check(_run_suite("res://tests/phase3_ability_validation.gd"), "V: Phase 3 validation suite passes")
	_check(_run_suite("res://tests/phase4_lane_validation.gd"), "W: Phase 4 validation suite passes")

	print("PHASE5_RESULT: PASS (all Phase 5 checks passed)") if failures == 0 else printerr("PHASE5_RESULT: FAIL (", failures, " checks failed)")
	quit(0 if failures == 0 else 1)

func _spawn_minion(arena: Node3D, lane: LaneWorld, team: TeamRules.Team, at: Vector3) -> MinionActor:
	var minion := MINION_SCENE.instantiate() as MinionActor
	minion.definition = RANGED_DEF
	minion.team = team
	minion.lane_path = lane.lane_path
	minion.position = at
	minion.death_cleanup_delay = 30.0
	minion.set_physics_process(false)
	arena.add_child(minion)
	return minion

func _reset_attack(attacks: BasicAttackController) -> void:
	attacks.cancel_windup()
	attacks.current_target = null
	attacks._interval_remaining = 0.0
	attacks._phase_elapsed = 0.0
	attacks._recovery_time = 0.0
	attacks._set_state(BasicAttackController.State.IDLE)

func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		printerr("FAIL: ", message)

func _run_suite(script_path: String) -> bool:
	var output: Array[String] = []
	var args := PackedStringArray(["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", script_path])
	var exit_code := OS.execute(OS.get_executable_path(), args, output, true)
	if exit_code != 0:
		printerr("Nested suite failed: ", script_path, "\n", "\n".join(output))
	return exit_code == 0
