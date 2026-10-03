extends SceneTree
## Headless smoke checks for Phase 2 commands, targets, camera and feedback.

var failures: int = 0
var arena: Node3D
var player: PlayerController
var player_stats: ActorStats
var combat: CombatComponent
var arena_input: Node
var camera_rig: Node3D
var camera: Camera3D
var dummies: Array[Node3D]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	arena = load("res://world/maps/dev_arena.tscn").instantiate() as Node3D
	root.add_child(arena)
	await process_frame
	player = arena.get_node("Player") as PlayerController
	player_stats = player.get_node("Stats") as ActorStats
	combat = player.get_node("Combat") as CombatComponent
	arena_input = arena.get_node("ArenaInput")
	camera_rig = arena.get_node("CameraRig") as Node3D
	camera = arena.get_node("CameraRig/Camera3D") as Camera3D
	dummies = [arena.get_node("Dummy1"), arena.get_node("Dummy2"), arena.get_node("Dummy3")]

	_check(dummies.size() == 3, "J: three independent dummies exist")
	await _check_ground_command_and_replacement()
	await _check_attack_pursuit_and_moving_target()
	await _check_death_respawn_terminates_attack()
	await _check_stop_and_escape()
	await _check_target_switching_and_feedback()
	_check_camera_independence_and_zoom()

	if failures == 0:
		print("PHASE2_RESULT: PASS (all automated checks passed)")
	else:
		printerr("PHASE2_RESULT: FAIL (", failures, " checks failed)")
	quit(0 if failures == 0 else 1)

func _check_ground_command_and_replacement() -> void:
	_reset_player(Vector3(-4.0, 0.9, 0.0))
	var first_destination := Vector3(1.0, 0.0, 4.0)
	await _right_click(first_destination)
	_check(player.command_state == PlayerController.CommandState.MOVE, "A: right-click ground issues MOVE")
	_check((arena.get_node("MoveMarker") as Node3D).visible, "A: move destination marker appears")
	await create_timer(0.25).timeout
	var second_destination := Vector3(-1.0, 0.0, 5.0)
	await _right_click(second_destination)
	_check(player.command_state == PlayerController.CommandState.MOVE and player._destination.is_equal_approx(second_destination), "B: new move replaces destination immediately")
	_check(arena.find_children("MoveMarker", "Node3D", true, false).size() == 1, "B: one reusable move marker exists")
	await create_timer(2.2).timeout
	_check(player.global_position.distance_to(Vector3(-1.0, 0.9, 5.0)) < 0.7, "A/B: player moves toward latest ground destination")
	_check(not (arena.get_node("MoveMarker") as Node3D).visible, "D: destination marker expires")

func _check_attack_pursuit_and_moving_target() -> void:
	_reset_player(Vector3(0.0, 0.9, 0.0))
	var target := dummies[0]
	var target_stats := target.get_node("Stats") as ActorStats
	target_stats.restore_full_health()
	player_stats.attack_damage = 20.0
	player_stats.attack_cooldown = 0.2
	await _right_click(target.global_position)
	_check(combat.target == target and player.command_state == PlayerController.CommandState.ATTACK, "C: right-click enemy outside range issues ATTACK")
	await create_timer(1.2).timeout
	_check(target_stats.current_health < target_stats.max_health, "C: player pursues and attacks outside-range target")
	var before_move := player.global_position.x
	target.global_position = Vector3(7.0, target.global_position.y, target.global_position.z)
	await create_timer(0.45).timeout
	_check(player.global_position.x > before_move, "D: pursuit tracks target after it moves")
	_check((target.get_node("SelectionRing") as Node3D).visible, "selection feedback appears on selected target")

func _check_death_respawn_terminates_attack() -> void:
	var target := dummies[0]
	var target_stats := target.get_node("Stats") as ActorStats
	_reset_player(target.global_position + Vector3(-1.4, 0.1, 0.0))
	target_stats.restore_full_health()
	player_stats.attack_damage = 200.0
	player_stats.attack_cooldown = 0.1
	player.attack_target(target)
	await create_timer(0.15).timeout
	_check(target_stats.current_health == 0.0, "E: selected target dies from combat")
	_check(combat.target == null and player.command_state == PlayerController.CommandState.IDLE, "E: death terminates ATTACK and clears selection")
	player.attack_target(target)
	_check(combat.target == null and player.command_state == PlayerController.CommandState.IDLE, "E: issuing an attack against a dead target is rejected")
	await create_timer((target as DummyTarget).respawn_delay + 0.2).timeout
	_check(target_stats.current_health == target_stats.max_health, "F: dummy respawns independently at full HP")
	await create_timer(0.3).timeout
	_check(combat.target == null and target_stats.current_health == target_stats.max_health, "F: respawn does not resume old attack")
	player_stats.attack_damage = 20.0

func _check_stop_and_escape() -> void:
	_reset_player(Vector3(-4.0, 0.9, 0.0))
	await _right_click(Vector3(8.0, 0.0, 7.0))
	var stop_event := InputEventKey.new()
	stop_event.physical_keycode = KEY_S
	stop_event.keycode = KEY_S
	stop_event.pressed = true
	arena_input.call("_unhandled_input", stop_event)
	_check(player.command_state == PlayerController.CommandState.STOP and player.velocity.length() == 0.0, "G: S stops movement immediately")
	_check(not player._has_destination, "G: S clears the movement order")
	player.attack_target(dummies[1])
	_check(player.command_state == PlayerController.CommandState.ATTACK, "H: attack order starts pursuit")
	arena_input.call("_unhandled_input", stop_event)
	_check(player.command_state == PlayerController.CommandState.STOP and combat.target == null and player.velocity.length() == 0.0, "H: S stops and clears attack pursuit")
	var escape_event := InputEventKey.new()
	escape_event.physical_keycode = KEY_ESCAPE
	escape_event.keycode = KEY_ESCAPE
	escape_event.pressed = true
	await _right_click(dummies[1].global_position)
	_check(combat.target == dummies[1], "I: target selected before Escape")
	arena_input.call("_unhandled_input", escape_event)
	_check(combat.target == null and player.command_state == PlayerController.CommandState.IDLE, "I: Escape clears selected target and interaction")
	_check(not (dummies[1].get_node("SelectionRing") as Node3D).visible, "I: Escape hides selection feedback")

func _check_target_switching_and_feedback() -> void:
	for target in dummies:
		await _right_click(target.global_position)
		_check(combat.target == target, "J: target switches to %s" % target.name)
		for other in dummies:
			var ring := other.get_node("SelectionRing") as Node3D
			_check(ring.visible == (other == target), "selection ring matches active target %s" % target.name)
		var target_stats := target.get_node("Stats") as ActorStats
		target_stats.restore_full_health()
		(target as DummyTarget).respawn_delay = 0.5
		_reset_player(target.global_position + Vector3(-1.4, 0.1, 0.0))
		player_stats.attack_damage = target_stats.max_health + 1.0
		player_stats.attack_cooldown = 0.05
		player.attack_target(target)
		await create_timer(0.05).timeout
		_check(target_stats.current_health == 0.0, "J: %s takes independent lethal damage" % target.name)
		for other in dummies:
			if other != target:
				_check(is_equal_approx((other.get_node("Stats") as ActorStats).current_health, (other.get_node("Stats") as ActorStats).max_health), "J: %s health is unaffected by attacking %s" % [other.name, target.name])
		await create_timer(0.6).timeout
		_check(is_equal_approx(target_stats.current_health, target_stats.max_health), "J: %s respawns independently" % target.name)
	combat.set_target(null)
	_check(not (dummies[2].get_node("SelectionRing") as Node3D).visible, "selection feedback disappears when cleared")
	var invalid_target := Node3D.new()
	root.add_child(invalid_target)
	player.attack_target(invalid_target)
	_check(combat.target == null and player.command_state == PlayerController.CommandState.IDLE, "invalid target without ActorStats is rejected")
	invalid_target.queue_free()

func _check_camera_independence_and_zoom() -> void:
	_reset_player(Vector3(-3.0, 0.9, 2.0))
	var player_position := player.global_position
	var camera_position := camera_rig.global_position
	var fixed_rotation := camera.global_rotation
	var drag_start := InputEventMouseButton.new()
	drag_start.button_index = MOUSE_BUTTON_MIDDLE
	drag_start.pressed = true
	camera_rig.call("_unhandled_input", drag_start)
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(80.0, -35.0)
	camera_rig.call("_unhandled_input", motion)
	_check(camera_rig.global_position != camera_position, "K: middle-mouse pan moves camera rig")
	_check(player.global_position.is_equal_approx(player_position), "K: camera pan does not move player")
	_check(camera.global_rotation.is_equal_approx(fixed_rotation), "K: camera pitch/orientation stays fixed")
	var wheel_up := InputEventMouseButton.new()
	wheel_up.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel_up.pressed = true
	for _index in range(20):
		camera_rig.call("_unhandled_input", wheel_up)
	_check(is_equal_approx(camera.size, camera_rig.get("zoom_min")), "L: zoom clamps at configured minimum")
	var wheel_down := InputEventMouseButton.new()
	wheel_down.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel_down.pressed = true
	for _index in range(20):
		camera_rig.call("_unhandled_input", wheel_down)
	_check(is_equal_approx(camera.size, camera_rig.get("zoom_max")), "L: zoom clamps at configured maximum")

func _right_click(world_position: Vector3) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_RIGHT
	event.pressed = true
	event.position = camera.unproject_position(world_position)
	arena_input.call("_unhandled_input", event)
	await physics_frame

func _reset_player(position: Vector3) -> void:
	player.clear_command()
	player.global_position = position
	player.velocity = Vector3.ZERO
	player_stats.attack_damage = 20.0
	for target in dummies:
		var stats := target.get_node("Stats") as ActorStats
		if stats.current_health <= 0.0:
			stats.restore_full_health()
			(target as DummyTarget).get_node("Visual").show()
			(target as DummyTarget).get_node("CollisionShape3D").set_deferred("disabled", false)

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		printerr("FAIL: ", label)
