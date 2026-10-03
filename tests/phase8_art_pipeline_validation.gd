extends SceneTree
## Phase 8 structural asset/animation integration tests; not subjective art QA.

const ARENA := preload("res://world/maps/dev_arena.tscn")
const KARN_SCENE_PATH := "res://assets/characters/karn/karn_character.tscn"
const GLB_PATH := "res://art/exports/karn.glb"
const REQUIRED_CLIPS: Array[StringName] = [&"IDLE", &"RUN", &"ATTACK_1", &"CAST", &"HIT", &"DEATH"]
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_check(ResourceLoader.exists(GLB_PATH), "A: generated KARN GLB source exists")
	var karn_packed := ResourceLoader.load(KARN_SCENE_PATH) as PackedScene
	_check(karn_packed != null, "B: dedicated KARN character scene loads")
	var karn := karn_packed.instantiate() as KarnRigAdapter if karn_packed != null else null
	if karn == null:
		_check(false, "C: rig scene root is a KARN presentation adapter")
		quit(1)
		return
	root.add_child(karn)
	await process_frame
	_check(karn.validate_imported_rig(), "dedicated scene passes rig/clip completeness check")
	var model := karn.get_node_or_null("KarnModel")
	var skeleton := karn.find_child("Skeleton3D", true, false) as Skeleton3D
	_check(model != null and skeleton != null and skeleton.get_bone_count() >= 19, "C: imported rigged model and humanoid skeleton exist")
	_check(karn.animation_player != null, "D: AnimationPlayer is available")
	for clip in REQUIRED_CLIPS:
		_check(karn.has_clip(clip), "%s animation is available" % String(clip))
	var chest_index := skeleton.find_bone("CHEST") if skeleton != null else -1
	var idle_pose := skeleton.get_bone_pose(chest_index) if chest_index >= 0 else Transform3D.IDENTITY
	await create_timer(0.18).timeout
	var breathing_pose := skeleton.get_bone_pose(chest_index) if chest_index >= 0 else Transform3D.IDENTITY
	_check(chest_index >= 0 and not idle_pose.is_equal_approx(breathing_pose), "IDLE clip animates imported skeleton pose")
	var weapon_index := skeleton.find_bone("WEAPON") if skeleton != null else -1
	var weapon_rest := skeleton.get_bone_pose(weapon_index) if weapon_index >= 0 else Transform3D.IDENTITY
	karn.play_visual_state(ActorPresentation.VisualState.ATTACK_WINDUP)
	await create_timer(0.16).timeout
	var weapon_strike := skeleton.get_bone_pose(weapon_index) if weapon_index >= 0 else Transform3D.IDENTITY
	_check(weapon_index >= 0 and not weapon_rest.is_equal_approx(weapon_strike), "ATTACK_1 clip animates the weapon attachment bone")

	var arena := ARENA.instantiate() as Node3D
	root.add_child(arena)
	await process_frame
	await process_frame
	var player := arena.get_node("Player") as PlayerController
	var presentation := player.get_node("ActorPresentation") as ActorPresentation
	var rig := player.get_node("Visual/CharacterModel") as KarnRigAdapter
	_check(rig != null, "rigged character scene is selected for KARN")
	var mesh := rig.find_child("KARN_BodyMesh", true, false) as MeshInstance3D if rig != null else null
	_check(mesh != null and mesh.skin != null and skeleton != null, "R: render mesh uses imported skeleton skin")
	var collision := player.get_node_or_null("CollisionShape3D") as CollisionShape3D
	_check(collision != null and (rig == null or rig.find_child("CollisionShape3D", true, false) == null), "R: gameplay collision stays separate from render mesh")
	var actor_player := rig.animation_player if rig != null else null
	_check(actor_player != null, "rigged actor exposes its animation system")
	if presentation != null and rig != null and actor_player != null:
		presentation._set_state(ActorPresentation.VisualState.IDLE)
		await process_frame
		_check(actor_player.current_animation == &"IDLE", "K: ActorPresentation drives idle")
		presentation._set_state(ActorPresentation.VisualState.MOVE)
		await process_frame
		_check(actor_player.current_animation == &"RUN", "L: ActorPresentation drives movement")
		presentation._set_state(ActorPresentation.VisualState.ATTACK_WINDUP)
		await process_frame
		_check(actor_player.current_animation == &"ATTACK_1", "M: ActorPresentation drives attack")
		var attack_position := actor_player.current_animation_position
		await create_timer(0.06).timeout
		presentation._set_state(ActorPresentation.VisualState.ATTACK_RELEASE)
		await process_frame
		var continuous_attack := actor_player.current_animation == &"ATTACK_1" and actor_player.current_animation_position >= attack_position
		presentation._set_state(ActorPresentation.VisualState.ATTACK_RECOVERY)
		await process_frame
		_check(continuous_attack and actor_player.current_animation == &"ATTACK_1", "attack phases share one uninterrupted gameplay-timed clip")
		presentation._set_state(ActorPresentation.VisualState.CAST, &"w")
		await process_frame
		_check(actor_player.current_animation == &"CAST", "N: ActorPresentation drives cast")
		presentation._set_state(ActorPresentation.VisualState.HIT, &"basic_attack")
		await process_frame
		_check(actor_player.current_animation == &"HIT", "O: ActorPresentation drives hit")
		presentation._set_state(ActorPresentation.VisualState.DEATH)
		await process_frame
		_check(actor_player.current_animation == &"DEATH", "P: ActorPresentation drives death")

	# Exercise explicit fallback selection before its deferred model construction.
	var fallback_arena := ARENA.instantiate() as Node3D
	var fallback_presentation := fallback_arena.get_node("Player/ActorPresentation") as ActorPresentation
	fallback_presentation.use_rigged_karn = false
	root.add_child(fallback_arena)
	await process_frame
	await process_frame
	var fallback_model := fallback_arena.get_node_or_null("Player/Visual/CharacterModel") as Node3D
	_check(fallback_model != null and fallback_model.has_node("Torso") and fallback_model.has_node("WeaponPivot/WeaponHead"), "Q: primitive KARN fallback can be explicitly selected")

	var imported_scene := ResourceLoader.load(KARN_SCENE_PATH) as PackedScene
	var imported_rig := imported_scene.instantiate() as KarnRigAdapter if imported_scene != null else null
	var imported_mesh := imported_rig.find_child("KARN_BodyMesh", true, false) as MeshInstance3D if imported_rig != null else null
	_check(imported_mesh != null and imported_mesh.mesh != null and imported_mesh.mesh.get_surface_count() > 0, "render geometry is present and remains separate from gameplay collision")

	karn.queue_free()
	arena.queue_free()
	fallback_arena.queue_free()
	if imported_rig != null:
		imported_rig.free()
	await process_frame
	for entry in [
		["S", "Phase 2", "res://tests/phase2_validation.gd"],
		["T", "Phase 3", "res://tests/phase3_ability_validation.gd"],
		["U", "Phase 4", "res://tests/phase4_lane_validation.gd"],
		["V", "Phase 5", "res://tests/phase5_combat_validation.gd"],
		["W", "Phase 6", "res://tests/phase6_presentation_validation.gd"],
		["X", "Phase 7", "res://tests/phase7_vertical_slice_validation.gd"],
	]:
		_run_subprocess(entry[0], entry[1], ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", entry[2]])
	_run_subprocess("Y", "headless parser/runtime smoke", ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--quit-after", "90"])
	print("PHASE8_RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
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
