extends SceneTree
## Deterministic headless coverage of the one-lane prototype systems.

const ARENA := preload("res://world/maps/dev_arena.tscn")
const MINION_SCENE := preload("res://gameplay/lane/minion_actor.tscn")
const MELEE := preload("res://gameplay/lane/melee_minion.tres")
const RANGED := preload("res://gameplay/lane/ranged_minion.tres")
const PROJECTILE := preload("res://gameplay/abilities/projectile.tscn")
var failures := 0
var arena: Node3D
var lane: LaneWorld
var player: PlayerController
var player_stats: ActorStats
var player_identity: CombatActor
var wallet: GoldWallet
var progression: HeroProgression
var abilities: AbilityController
var dummies: Array[Node3D]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	arena = ARENA.instantiate() as Node3D
	root.add_child(arena)
	await process_frame
	lane = arena.get_node("LaneWorld") as LaneWorld
	player = arena.get_node("Player") as PlayerController
	player_stats = player.get_node("Stats") as ActorStats
	player_identity = player.get_node("CombatActor") as CombatActor
	wallet = player.get_node("GoldWallet") as GoldWallet
	progression = player.get_node("Progression") as HeroProgression
	abilities = player.get_node("AbilityController") as AbilityController
	dummies = [arena.get_node("Dummy1"), arena.get_node("Dummy2"), arena.get_node("Dummy3")]
	lane.team_a_spawner._timer.stop()
	lane.team_b_spawner._timer.stop()

	_check(player_identity.team == TeamRules.Team.TEAM_A and TeamRules.are_hostile(TeamRules.Team.TEAM_A, TeamRules.Team.TEAM_B), "A: Team A identifies Team B as hostile")
	_check(not TeamRules.are_hostile(TeamRules.Team.TEAM_A, TeamRules.Team.TEAM_A), "B: same-team units are not hostile")
	var waves_a := await lane.team_a_spawner.spawn_wave_now()
	var waves_b := await lane.team_b_spawner.spawn_wave_now()
	_check(waves_a.size() == 4 and waves_b.size() == 4, "C: both wave spawners create 3 melee + 1 ranged")
	_check(waves_a[0].team == TeamRules.Team.TEAM_A and waves_b[0].team == TeamRules.Team.TEAM_B, "C: wave spawners preserve their faction")
	for unit_index in (waves_a + waves_b).size():
		var unit := (waves_a + waves_b)[unit_index]
		unit.set_physics_process(false)
		unit.position = Vector3(100.0 + float(unit_index), 0.55, 20.0)
	_check(lane.team_a_spawner.wave_number == lane.team_b_spawner.wave_number, "C: wave numbers are synchronized")

	var advancing_a := await _spawn_minion(TeamRules.Team.TEAM_A, MELEE, Vector3(-9, 0.55, 5))
	var advancing_b := await _spawn_minion(TeamRules.Team.TEAM_B, MELEE, Vector3(9, 0.55, 5))
	advancing_a._advance(0.2)
	advancing_b._advance(0.2)
	var a_path_end := lane.lane_path.position_for_team(TeamRules.Team.TEAM_A, advancing_a.path_distance)
	var b_path_end := lane.lane_path.position_for_team(TeamRules.Team.TEAM_B, advancing_b.path_distance)
	_check(advancing_a.path_distance > 0.0 and advancing_b.path_distance > 0.0 and a_path_end.x > lane.lane_path.team_a_start.x and b_path_end.x < lane.lane_path.team_b_start.x, "D/E: both teams advance along the lane toward the opposing base")
	advancing_a.position = Vector3(-33, 0.55, 12)
	advancing_b.position = Vector3(-34, 0.55, 12)

	var melee := await _spawn_minion(TeamRules.Team.TEAM_A, MELEE, Vector3(-5, 0.55, 2))
	var melee_target := await _spawn_minion(TeamRules.Team.TEAM_B, MELEE, Vector3(-3.5, 0.55, 2))
	melee._update_target()
	_check(melee.target_actor == melee_target._identity, "F: opposing minions acquire one another")
	melee.attack_cooldown_remaining = 0.0
	var melee_hp := melee_target._stats.current_health
	melee._combat_tick(0.1)
	_check(melee_target._stats.current_health < melee_hp, "G: melee minion attacks in melee range")
	melee_target.position = Vector3(-30, 0.55, 12)

	var ranged := await _spawn_minion(TeamRules.Team.TEAM_A, RANGED, Vector3(2, 0.55, 2))
	var ranged_target := await _spawn_minion(TeamRules.Team.TEAM_B, MELEE, Vector3(7, 0.55, 2))
	ranged._update_target()
	var ranged_hp := ranged_target._stats.current_health
	ranged._combat_tick(0.1)
	_check(ranged.target_actor == ranged_target._identity and ranged_target._stats.current_health < ranged_hp, "H: ranged minion attacks from longer range")
	ranged_target.position = Vector3(-31, 0.55, 12)

	melee_target._stats.apply_damage(99999.0, player, &"test")
	_check(melee_target.state == MinionActor.State.DEAD and melee_target.velocity == Vector3.ZERO, "I: dead minion stops movement and combat")
	var replacement := await _spawn_minion(TeamRules.Team.TEAM_B, MELEE, Vector3(-3.2, 0.55, 2.2))
	melee._update_target()
	_check(melee.target_actor == replacement._identity, "J: minion reacquires after target death")
	replacement.position = Vector3(-32, 0.55, 12)
	var lane_winner := await _spawn_minion(TeamRules.Team.TEAM_A, MELEE, lane.lane_path.position_for_team(TeamRules.Team.TEAM_A, lane.lane_path.length() - 4.0) + Vector3.UP * 0.55)
	lane_winner.acquisition_range = 10.0
	lane_winner._update_target()
	_check(lane_winner.target_actor == lane.team_b_tower._identity, "J: surviving wave can acquire the opposing tower after clearing lane units")
	lane_winner.position = lane.team_b_tower.global_position + Vector3(-1.5, 0.55, 0.0)
	var enemy_tower_health := lane.team_b_tower._stats.current_health
	lane_winner._combat_tick(0.1)
	_check(lane.team_b_tower._stats.current_health < enemy_tower_health, "J: minion basic attack damages enemy tower")

	var gold_target := await _spawn_minion(TeamRules.Team.TEAM_B, MELEE, Vector3(-4, 0.55, -3))
	var gold_before := wallet.current_gold
	player.global_position = gold_target.global_position + Vector3(-1.2, 0.35, 0.0)
	player_stats.attack_range = 2.5
	player_stats.attack_damage = 99999.0
	player_stats.attack_cooldown = 0.1
	player.attack_target(gold_target)
	(player.get_node("Combat") as CombatComponent)._physics_process(0.01)
	_check(wallet.current_gold == gold_before + roundi(MELEE.gold_bounty), "K: hero basic last hit awards minion gold")
	var no_gold_target := await _spawn_minion(TeamRules.Team.TEAM_B, MELEE, Vector3(-4, 0.55, -4))
	no_gold_target._stats.apply_damage(99999.0, dummies[0], &"basic")
	_check(wallet.current_gold == gold_before + roundi(MELEE.gold_bounty), "L: non-player last hit awards no hero gold")

	player.global_position = Vector3(-4, 0.9, -2)
	var xp_target := await _spawn_minion(TeamRules.Team.TEAM_B, MELEE, Vector3(-2.5, 0.55, -2))
	var xp_before := progression.current_xp
	var level_before_xp := progression.level
	xp_target._stats.apply_damage(99999.0, dummies[0], &"basic")
	_check(progression.current_xp > xp_before or progression.level > level_before_xp, "M: living nearby hero gains proximity XP without last hit")
	player.global_position = Vector3(0, 0.9, -2)
	var distant := await _spawn_minion(TeamRules.Team.TEAM_B, MELEE, Vector3(-20, 0.55, -2))
	progression.xp_radius = 5.0
	xp_before = progression.current_xp
	distant._stats.apply_damage(99999.0, dummies[0], &"basic")
	_check(progression.current_xp == xp_before, "N: hero outside XP radius gains none")
	player_stats.current_health = 0.0
	var dead_hero_xp := await _spawn_minion(TeamRules.Team.TEAM_B, MELEE, Vector3(1, 0.55, -2))
	xp_before = progression.current_xp
	dead_hero_xp._stats.apply_damage(99999.0, dummies[0], &"basic")
	_check(progression.current_xp == xp_before, "O: dead hero gains no XP")
	player_stats.current_health = player_stats.max_health

	progression.level = 1
	progression.current_xp = 0.0
	var max_hp_before := player_stats.max_health
	var damage_before := player_stats.attack_damage
	var current_hp_before := player_stats.current_health - 100.0
	player_stats.current_health = current_hp_before
	progression.grant_xp(progression.xp_required())
	_check(progression.level == 2, "P: hero levels at configured XP threshold")
	_check(player_stats.max_health > max_hp_before and player_stats.attack_damage > damage_before, "Q: level growth increases hero stats")
	_check(player_stats.current_health == current_hp_before, "Q: level-up preserves absolute current HP")
	player_stats.current_health = player_stats.max_health

	for candidate in lane.roster._actors:
		if candidate.actor_kind == &"minion" and candidate.is_alive():
			candidate.actor.global_position = Vector3(100.0 + float(candidate.get_instance_id() % 7), 0.55, 30.0)
	var hunter := await _spawn_minion(TeamRules.Team.TEAM_B, MELEE, player.global_position + Vector3(1.8, -0.35, 0))
	hunter.acquisition_range = 3.0
	hunter._update_target()
	_check(hunter.target_actor == player_identity, "R: hostile minion can target the hero")
	var victim := dummies[0]
	var victim_identity := victim.get_node("CombatActor") as CombatActor
	victim_identity.team = TeamRules.Team.TEAM_B
	victim_identity.actor_kind = &"hero"
	victim.get_node("Stats").current_health = 1000.0
	var aggro_tower := lane.team_b_tower
	aggro_tower.set_physics_process(false)
	aggro_tower.position = player.global_position + Vector3(0.0, 0.0, 4.0)
	player_stats.attack_range = 20.0
	player_stats.attack_damage = 1.0
	player_stats.attack_cooldown = 0.1
	player.attack_target(victim)
	var player_combat := player.get_node("Combat") as CombatComponent
	player_combat.cooldown_remaining = 0.0
	player_combat._physics_process(0.01)
	_check(hunter.aggro_target == player_identity and hunter.aggro_remaining > 0.0, "S: hero basic attack draws nearby enemy minion aggro")
	aggro_tower._acquire_target()
	_check(aggro_tower.target_actor == player_identity, "S: in-range enemy tower temporarily prioritizes attacking hero")
	var regular_target := await _spawn_minion(TeamRules.Team.TEAM_A, MELEE, hunter.global_position + Vector3(0, 0, 1.0))
	hunter.aggro_remaining = 0.0
	hunter._physics_process(0.01)
	_check(hunter.target_actor == regular_target._identity, "S: expired aggro returns to normal minion priority")
	regular_target.position = Vector3(-35, 0.55, 12)
	victim_identity.actor_kind = &"dummy"
	aggro_tower.position = Vector3(22.0, 0.0, 0.0)
	aggro_tower.set_physics_process(true)

	var hostile_near_tower := await _spawn_minion(TeamRules.Team.TEAM_B, MELEE, Vector3(-18.0, 0.55, 6))
	var allied_near_tower := await _spawn_minion(TeamRules.Team.TEAM_A, MELEE, Vector3(-17.0, 0.55, 6))
	var tower := lane.team_a_tower
	tower.tower_range = 12.0
	tower.tower_damage = 100.0
	tower.tower_attack_cooldown = 0.1
	tower._acquire_target()
	_check(tower.target_actor == hostile_near_tower._identity, "T: tower prioritizes hostile minion in range")
	var hostile_tower_hp := hostile_near_tower._stats.current_health
	tower._attack_left = 0.0
	tower._physics_process(0.01)
	_check(hostile_near_tower._stats.current_health < hostile_tower_hp, "T: tower attacks hostile minion")
	tower.target_actor = null
	tower._acquire_target()
	_check(tower.target_actor != allied_near_tower._identity, "U: tower never attacks same-team unit")
	var tower_hp := tower._stats.current_health
	tower._stats.apply_damage(tower_hp + 1.0, dummies[0], &"basic")
	_check(tower.destroyed and tower._stats.current_health == 0.0, "V: tower can be damaged and destroyed")
	tower._physics_process(10.0)
	_check(tower.target_actor == null and not tower.is_physics_processing(), "W: destroyed tower stops combat")

	player.global_position = Vector3(0, 0.9, 0)
	player_stats.current_health = player_stats.max_health
	player_stats.current_mana = player_stats.max_mana
	var enemy_minion := await _spawn_minion(TeamRules.Team.TEAM_B, MELEE, Vector3(3.0, 0.55, 0))
	var q_hp := enemy_minion._stats.current_health
	abilities.request_cast(&"q")
	_check(abilities.confirm_target(enemy_minion), "X: Q accepts an enemy minion")
	_check(enemy_minion._stats.current_health < q_hp, "X: Q damages enemy minion")
	var ally := await _spawn_minion(TeamRules.Team.TEAM_A, MELEE, Vector3(1.8, 0.55, 1.5))
	var enemy_two := await _spawn_minion(TeamRules.Team.TEAM_B, MELEE, Vector3(2.0, 0.55, -1.5))
	var ally_hp := ally._stats.current_health
	var enemy_two_hp := enemy_two._stats.current_health
	var enemy_one_hp := enemy_minion._stats.current_health
	abilities.request_cast(&"e")
	_check(abilities.confirm_point(Vector3(1.8, 0.0, 0.0)), "Y: E casts on a point containing ally and hostile minions")
	_check(ally._stats.current_health == ally_hp and enemy_two._stats.current_health < enemy_two_hp and enemy_minion._stats.current_health < enemy_one_hp, "Z: AoE damages multiple hostile minions and never allied minions")

	var projectile_ally := await _spawn_minion(TeamRules.Team.TEAM_A, MELEE, Vector3(6.0, 0.55, 4.0))
	var projectile_enemy := await _spawn_minion(TeamRules.Team.TEAM_B, MELEE, Vector3(8.0, 0.55, 4.0))
	var projectile := PROJECTILE.instantiate() as AbilityProjectile
	projectile.configure(Vector3.RIGHT, 5.0, 150.0, player)
	arena.add_child(projectile)
	projectile.global_position = Vector3(5.0, 1.1, 4.0)
	var projectile_ally_hp := projectile_ally._stats.current_health
	var projectile_enemy_hp := projectile_enemy._stats.current_health
	await create_timer(0.35).timeout
	_check(projectile_ally._stats.current_health == projectile_ally_hp and projectile_enemy._stats.current_health < projectile_enemy_hp, "AA: W collision ignores ally and hits first hostile")

	print("PHASE4_RESULT: PASS (all Phase 4 checks passed)") if failures == 0 else printerr("PHASE4_RESULT: FAIL (", failures, " checks failed)")
	quit(0 if failures == 0 else 1)

func _spawn_minion(team: TeamRules.Team, definition: MinionDefinition, at: Vector3) -> MinionActor:
	var minion := MINION_SCENE.instantiate() as MinionActor
	minion.definition = definition
	minion.team = team
	minion.lane_path = lane.lane_path
	minion.position = at
	minion.death_cleanup_delay = 30.0
	minion.set_physics_process(false)
	arena.add_child(minion)
	await process_frame
	minion.set_physics_process(false)
	return minion

func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		printerr("FAIL: ", message)
