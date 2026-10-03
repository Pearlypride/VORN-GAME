extends SceneTree
## Headless integration checks for the first hero ability kit and lifecycle.

var failures: int = 0
var arena: Node3D
var player: PlayerController
var stats: ActorStats
var combat: CombatComponent
var abilities: AbilityController
var statuses: StatusEffectController
var lifecycle: HeroLifecycle
var desktop_input: ArenaInput
var camera: Camera3D
var dummies: Array[Node3D]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	arena = load("res://world/maps/dev_arena.tscn").instantiate() as Node3D
	root.add_child(arena)
	current_scene = arena
	await process_frame
	player = arena.get_node("Player") as PlayerController
	stats = player.get_node("Stats") as ActorStats
	combat = player.get_node("Combat") as CombatComponent
	abilities = player.get_node("AbilityController") as AbilityController
	statuses = player.get_node("StatusEffects") as StatusEffectController
	lifecycle = player.get_node("HeroLifecycle") as HeroLifecycle
	desktop_input = arena.get_node("ArenaInput") as ArenaInput
	camera = arena.get_node("CameraRig/Camera3D") as Camera3D
	dummies = [arena.get_node("Dummy1"), arena.get_node("Dummy2"), arena.get_node("Dummy3")]
	stats.health_regeneration = 0.0
	stats.mana_regeneration = 0.0
	_check(player.hero_definition.hero_name == "KARN", "hero definition configures the prototype player")
	_check(stats.max_health == 1000.0 and stats.max_mana == 500.0, "hero definition configures base health and mana")
	_check(abilities.get_ability_ids().size() == 4, "hero definition loads Q/W/E/R data assets")
	var starting_mana := stats.current_mana
	_check(not stats.spend_mana(starting_mana + 1.0) and stats.current_mana == starting_mana, "mana cannot be spent below zero")
	_check(is_equal_approx(stats.restore_mana(1000.0), 0.0), "mana restoration cannot exceed maximum")

	await _test_targeted_strike()
	await _test_projectile()
	await _test_area_damage()
	await _test_overdrive()
	await _test_death_and_respawn()
	await _test_targeting_cancel_and_command_compatibility()

	if failures == 0:
		print("PHASE3_RESULT: PASS (all automated ability checks passed)")
	else:
		printerr("PHASE3_RESULT: FAIL (", failures, " checks failed)")
	quit(0 if failures == 0 else 1)

func _test_targeted_strike() -> void:
	_reset_arena()
	player.global_position = Vector3(0.0, 0.9, 0.0)
	dummies[0].global_position = Vector3(3.0, 0.8, 0.0)
	dummies[1].global_position = Vector3(7.0, 0.8, 0.0)
	dummies[2].global_position = Vector3(9.0, 0.8, 0.0)
	var first_stats := _stats_for(dummies[0])
	var second_stats := _stats_for(dummies[1])
	var third_stats := _stats_for(dummies[2])
	var mana_before := stats.current_mana
	player.move_to(Vector3(0.0, 0.0, 1.0))
	_press_key(KEY_Q)
	_check(abilities.current_targeting_ability == &"q", "A: Q enters targeted cast mode")
	_check(player.command_state == PlayerController.CommandState.MOVE, "Q does not replace the movement command")
	await process_frame
	_check((arena.get_node("AbilityTargetingFeedback/CastRangeRing") as Node3D).visible, "Q targeting shows cast-range feedback")
	_left_click(dummies[0].global_position)
	_check(first_stats.current_health == 0.0, "A: Q applies 120 damage to valid selected target")
	_check(second_stats.current_health == second_stats.max_health and third_stats.current_health == third_stats.max_health, "A: Q affects only its selected target")
	_check(stats.current_mana == mana_before - 60.0, "Q spends its configured mana cost")
	_check(abilities.get_ability_state(&"q") == AbilityController.AbilityState.COOLDOWN, "Q begins cooldown after a valid cast")
	_check(not abilities.request_cast(&"q"), "D: Q refuses to cast during cooldown")
	_check(stats.current_mana == mana_before - 60.0, "D: cooldown rejection spends no mana")

	_reset_cooldown(&"q")
	_reset_dummy(dummies[0])
	_reset_dummy(dummies[2])
	player.global_position = Vector3(0.0, 0.9, 0.0)
	_press_key(KEY_Q)
	var mana_for_range_test := stats.current_mana
	_check(not _left_click(dummies[2].global_position), "B: Q rejects an out-of-range target")
	_check(abilities.is_targeting() and stats.current_mana == mana_for_range_test, "N/O: invalid range spends no mana and starts no cooldown")
	_cancel_with_escape()
	_reset_cooldown(&"q")
	stats.current_mana = 59.0
	_press_key(KEY_Q)
	_check(not abilities.is_targeting() and abilities.get_cooldown_remaining(&"q") == 0.0, "C: Q refuses to begin without enough mana")
	_check(stats.current_mana == 59.0, "C: insufficient mana is not consumed")
	stats.current_mana = stats.max_mana

func _test_projectile() -> void:
	_reset_arena()
	player.global_position = Vector3(-4.0, 0.9, 0.0)
	for index in range(3):
		dummies[index].global_position = Vector3(float(index) * 2.0, 0.8, 0.0)
	var first_stats := _stats_for(dummies[0])
	var second_stats := _stats_for(dummies[1])
	var third_stats := _stats_for(dummies[2])
	_reset_cooldown(&"w")
	_press_key(KEY_W)
	_check(abilities.current_targeting_ability == &"w", "W enters point/skills­hot targeting mode")
	_check(_left_click(Vector3(7.0, 0.0, 0.0)), "W accepts a point in cast range")
	_check(stats.current_health != 0.0, "W test setup remains alive")
	_check(_projectile_count() == 1, "W launches one primitive debug projectile")
	await create_timer(0.35).timeout
	_check(first_stats.current_health == 0.0, "E: W projectile damages the first enemy in its path")
	_check(second_stats.current_health == second_stats.max_health and third_stats.current_health == third_stats.max_health, "E: projectile disappears on first hit; later enemies are untouched")
	_check(_projectile_count() == 0, "W projectile is removed after a hit")

	_reset_cooldown(&"w")
	stats.current_mana = stats.max_mana
	player.global_position = Vector3(-4.0, 0.9, -4.0)
	for target in dummies:
		target.global_position.z = 10.0
	_press_key(KEY_W)
	_check(_left_click(Vector3(7.0, 0.0, -4.0)), "W accepts empty-ground aim near maximum range")
	await create_timer(1.1).timeout
	_check(_projectile_count() == 0, "F: W projectile expires after traveling its maximum range")

func _test_area_damage() -> void:
	_reset_arena()
	player.global_position = Vector3(0.0, 0.9, 0.0)
	dummies[0].global_position = Vector3(2.0, 0.8, 0.0)
	dummies[1].global_position = Vector3(3.5, 0.8, 0.0)
	dummies[2].global_position = Vector3(6.0, 0.8, 0.0)
	var first_stats := _stats_for(dummies[0])
	var second_stats := _stats_for(dummies[1])
	var third_stats := _stats_for(dummies[2])
	_reset_cooldown(&"e")
	stats.current_mana = stats.max_mana
	_press_key(KEY_E)
	await process_frame
	_check((arena.get_node("AbilityTargetingFeedback/AreaRadiusRing") as Node3D).visible, "E targeting shows an AoE radius preview")
	_check(_left_click(Vector3(2.0, 0.0, 0.0)), "E accepts an in-range area point")
	_check(first_stats.current_health == 30.0 and second_stats.current_health == 30.0, "G: E damages multiple enemies inside radius")
	_check(third_stats.current_health == third_stats.max_health, "H: E leaves an enemy outside its radius untouched")
	_check(stats.current_mana == stats.max_mana - 70.0, "E spends configured mana once")

	third_stats.apply_damage(third_stats.max_health)
	dummies[2].global_position = Vector3(2.5, 0.8, 0.0)
	_reset_cooldown(&"e")
	stats.current_mana = stats.max_mana
	_press_key(KEY_E)
	_left_click(Vector3(2.0, 0.0, 0.0))
	_check(third_stats.current_health == 0.0, "dead enemies inside an AoE are ignored")

func _test_overdrive() -> void:
	_reset_arena()
	stats.current_mana = stats.max_mana
	var r_definition := abilities.get_ability_definition(&"r")
	var r_effect := r_definition.effect as SelfBuffEffect
	r_effect.duration = 0.15
	_reset_cooldown(&"r")
	var base_speed := stats.get_effective_movement_speed()
	_check(_press_key(KEY_R), "R self-cast command is accepted")
	_check(statuses.has_effect(&"r_surge"), "I: R applies its temporary status modifier")
	_check(stats.get_effective_movement_speed() > base_speed, "R increases movement speed through stat modifiers")
	_check(stats.get_effective_attack_cooldown() < stats.attack_cooldown, "R reduces the basic attack interval")
	_check(abilities.get_ability_state(&"r") == AbilityController.AbilityState.COOLDOWN, "R starts cooldown after a valid cast")
	await create_timer(0.25).timeout
	_check(not statuses.has_effect(&"r_surge"), "J: R buff expires and restores base stats")
	r_effect.duration = 6.0
	_reset_cooldown(&"r")
	stats.current_mana = stats.max_mana
	abilities.request_cast(&"r")
	_check(statuses.has_effect(&"r_surge"), "R buff active before death test")

func _test_death_and_respawn() -> void:
	var spawn_position := lifecycle._spawn_position
	_press_key(KEY_Q)
	_check(abilities.is_targeting(), "targeting mode active before death test")
	player.move_to(Vector3(5.0, 0.0, 0.0))
	stats.apply_damage(stats.current_health)
	_check(stats.current_health == 0.0 and player.command_state == PlayerController.CommandState.IDLE, "hero death clears movement and disables actor")
	_check(not statuses.has_effect(&"r_surge"), "K: death removes the active R buff")
	_check(not abilities.is_targeting(), "death clears an active targeting mode")
	var presentation := player.get_node("ActorPresentation") as ActorPresentation
	_check(presentation.current_state == ActorPresentation.VisualState.DEATH and (player.get_node("Visual") as Node3D).visible, "death enters a visible hero death pose")
	_check(not abilities.request_cast(&"q"), "L: abilities cannot be cast while dead")
	var old_mana := stats.current_mana
	await create_timer(presentation.death_pose_duration + 0.1).timeout
	_check(not (player.get_node("Visual") as Node3D).visible, "death presentation hides the hero after its pose")
	await create_timer(lifecycle.respawn_delay + 0.2).timeout
	_check(stats.current_health == stats.max_health and stats.current_mana == stats.max_mana, "M: respawn restores health and mana to configured maximums")
	_check(player.global_position.is_equal_approx(spawn_position), "M: respawn returns hero to original spawn position")
	_check((player.get_node("Visual") as Node3D).visible, "M: respawn restores hero visual")
	_check(presentation.current_state == ActorPresentation.VisualState.IDLE, "respawn resets the hero presentation state")
	_check(not statuses.has_effect(&"r_surge") and player.command_state == PlayerController.CommandState.IDLE, "M: respawn has no stale buff or command")
	_check(old_mana < stats.max_mana, "death-test setup had spent mana before its deterministic reset")

func _test_targeting_cancel_and_command_compatibility() -> void:
	_reset_arena()
	player.move_to(Vector3(0.0, 0.0, 1.0))
	var destination_before := player._destination
	_press_key(KEY_Q)
	_check(abilities.is_targeting() and player.command_state == PlayerController.CommandState.MOVE, "Q targeting preserves an existing move order")
	_cancel_with_escape()
	_check(not abilities.is_targeting() and player.command_state == PlayerController.CommandState.MOVE and player._destination == destination_before, "P/Q: Escape cancels targeting without damaging movement command")
	_press_key(KEY_Q)
	_right_click_cancel()
	_check(not abilities.is_targeting() and player.command_state == PlayerController.CommandState.MOVE, "P: right-click cancels ability targeting without issuing a new order")
	_check((arena.get_node("AbilityTargetingFeedback/CastRangeRing") as Node3D).visible == false, "P: cancel hides cast indicators")
	var mana_before := stats.current_mana
	var cooldown_before := abilities.get_cooldown_remaining(&"q")
	_press_key(KEY_Q)
	_check(not _left_click(Vector3(20.0, 0.0, 0.0)), "N: out-of-range point is rejected")
	_check(stats.current_mana == mana_before and abilities.get_cooldown_remaining(&"q") == cooldown_before, "N/O: rejected point consumes no mana and starts no cooldown")
	_cancel_with_escape()
	_check(player.command_state == PlayerController.CommandState.MOVE, "Q: ability casts do not replace command architecture")

func _press_key(key: Key) -> bool:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = true
	desktop_input._unhandled_input(event)
	return true

func _left_click(world_position: Vector3) -> bool:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = camera.unproject_position(world_position)
	desktop_input._unhandled_input(event)
	return not abilities.is_targeting()

func _cancel_with_escape() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.physical_keycode = KEY_ESCAPE
	event.pressed = true
	desktop_input._unhandled_input(event)

func _right_click_cancel() -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_RIGHT
	event.pressed = true
	desktop_input._unhandled_input(event)

func _reset_arena() -> void:
	abilities.cancel_targeting()
	player.clear_command()
	player.velocity = Vector3.ZERO
	if stats.current_health <= 0.0:
		stats.restore_full_resources()
	for target in dummies:
		_reset_dummy(target)
	stats.current_mana = stats.max_mana

func _reset_dummy(target: Node3D) -> void:
	var target_stats := _stats_for(target)
	if target_stats.current_health <= 0.0:
		target_stats.restore_full_health()
	(target.get_node("Visual") as Node3D).show()
	(target.get_node("CollisionShape3D") as CollisionShape3D).set_deferred("disabled", false)

func _reset_cooldown(ability_id: StringName) -> void:
	var runtime: Dictionary = abilities._runtime[ability_id]
	runtime["cooldown_remaining"] = 0.0

func _stats_for(target: Node3D) -> ActorStats:
	return target.get_node("Stats") as ActorStats

func _projectile_count() -> int:
	return arena.get_tree().get_nodes_in_group("ability_projectile").size()

func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		failures += 1
		printerr("FAIL: ", description)
