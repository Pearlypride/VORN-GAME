class_name ActorPresentation
extends Node3D
## Mirrors gameplay into disposable primitive presentation. It never applies gameplay effects.

enum VisualState { IDLE, MOVE, ATTACK_WINDUP, ATTACK_RELEASE, ATTACK_RECOVERY, CAST, HIT, DEATH }

const HIT_MATERIAL: Material = preload("res://gameplay/presentation/materials/hit_flash.tres")

signal visual_state_changed(state: VisualState, detail: StringName)
signal actor_died
signal actor_respawned

@export var hit_state_duration: float = 0.18
@export var cast_state_duration: float = 0.24
@export var death_pose_duration: float = 0.65

var current_state: VisualState = VisualState.IDLE
var state_detail: StringName = &""
var _owner_actor: Node3D
var _stats: ActorStats
var _identity: CombatActor
var _attacks: BasicAttackController
var _abilities: AbilityController
var _progression: HeroProgression
var _lifecycle: HeroLifecycle
var _visual: Node3D
var _model: Node3D
var _arm_left: Node3D
var _arm_right: Node3D
var _leg_left: Node3D
var _leg_right: Node3D
var _hit_marker: MeshInstance3D
var _tower_emitter: Node3D
var _timed_state_remaining: float = 0.0
var _motion_accumulator: float = 0.0
var _motion_clock: float = 0.0
var _dead: bool = false

func _ready() -> void:
	_owner_actor = get_parent() as Node3D
	_stats = _owner_actor.get_node_or_null("Stats") as ActorStats
	_identity = _owner_actor.get_node_or_null("CombatActor") as CombatActor
	_attacks = _owner_actor.get_node_or_null("BasicAttackController") as BasicAttackController
	_abilities = _owner_actor.get_node_or_null("AbilityController") as AbilityController
	_progression = _owner_actor.get_node_or_null("Progression") as HeroProgression
	_lifecycle = _owner_actor.get_node_or_null("HeroLifecycle") as HeroLifecycle
	_visual = _owner_actor.get_node_or_null("Visual") as Node3D
	call_deferred("_build_placeholder")
	_build_hit_marker()
	if _stats != null:
		_stats.damage_received.connect(_on_damage_received)
		_stats.died.connect(_on_died)
	if _attacks != null:
		_attacks.state_changed.connect(_on_attack_state_changed)
	var controller := _owner_actor as PlayerController
	if controller != null:
		controller.command_state_changed.connect(_on_command_state_changed)
	if _abilities != null:
		_abilities.ability_cast.connect(_on_ability_cast)
	if _progression != null:
		_progression.level_up.connect(_on_level_up)
	if _lifecycle != null:
		_lifecycle.hero_respawned.connect(_on_respawned)
	_set_state(VisualState.IDLE)

func _process(delta: float) -> void:
	_motion_accumulator += delta
	_timed_state_remaining = maxf(0.0, _timed_state_remaining - delta)
	if _motion_accumulator < 0.08:
		return
	var step := _motion_accumulator
	_motion_accumulator = 0.0
	_motion_clock += step
	if _dead or _model == null:
		return
	if current_state in [VisualState.IDLE, VisualState.MOVE]:
		_refresh_from_gameplay()
	if current_state == VisualState.MOVE:
		var swing := sin(_motion_clock * 11.0) * 0.34
		if _arm_left != null:
			_arm_left.rotation.x = swing
			_arm_right.rotation.x = -swing
			_leg_left.rotation.x = -swing * 0.8
			_leg_right.rotation.x = swing * 0.8
	else:
		_model.scale.y = 1.0 + (sin(_motion_clock * 3.2) * 0.012 if current_state == VisualState.IDLE else 0.0)
		if _arm_left != null:
			_arm_left.rotation.x = move_toward(_arm_left.rotation.x, 0.0, step * 2.0)
			_arm_right.rotation.x = move_toward(_arm_right.rotation.x, 0.0, step * 2.0)
			_leg_left.rotation.x = move_toward(_leg_left.rotation.x, 0.0, step * 2.0)
			_leg_right.rotation.x = move_toward(_leg_right.rotation.x, 0.0, step * 2.0)
	if _timed_state_remaining <= 0.0 and current_state in [VisualState.HIT, VisualState.CAST]:
		_refresh_from_gameplay()

func _build_placeholder() -> void:
	if _visual == null or _identity == null:
		return
	for child in _visual.get_children():
		if child.name in ["CharacterModel", "TowerModel"]:
			child.queue_free()
	match _identity.actor_kind:
		&"hero":
			_model = PlaceholderModels.build_hero()
		&"minion":
			var minion := _owner_actor as MinionActor
			var kind := minion.definition.minion_type if minion != null and minion.definition != null else MinionDefinition.MinionType.MELEE
			_model = PlaceholderModels.build_minion(kind, _identity.team)
		&"tower":
			_model = PlaceholderModels.build_tower(_identity.team)
		_:
			return
	_visual.add_child(_model)
	_arm_left = _model.get_node_or_null("ArmLeft") as Node3D
	_arm_right = _model.get_node_or_null("ArmRight") as Node3D
	_leg_left = _model.get_node_or_null("LegLeft") as Node3D
	_leg_right = _model.get_node_or_null("LegRight") as Node3D
	_tower_emitter = _model.get_node_or_null("Emitter") as Node3D

func _build_hit_marker() -> void:
	if _visual == null:
		return
	_hit_marker = MeshInstance3D.new()
	_hit_marker.name = "HitFlash"
	var mesh := SphereMesh.new()
	mesh.radius = 0.8
	mesh.height = 1.6
	_hit_marker.mesh = mesh
	_hit_marker.material_override = HIT_MATERIAL
	_hit_marker.visible = false
	_visual.add_child(_hit_marker)

func _on_attack_state_changed(attack_state: int, _progress: float, _target: Node3D, _time_left: float) -> void:
	match attack_state:
		BasicAttackController.State.WINDUP:
			_set_state(VisualState.ATTACK_WINDUP)
			if _model != null:
				_model.rotation.z = -0.12
			if _tower_emitter != null:
				_tower_emitter.scale = Vector3.ONE * 1.18
		BasicAttackController.State.RELEASE:
			_set_state(VisualState.ATTACK_RELEASE)
			if _model != null:
				_model.rotation.z = 0.18
			if _tower_emitter != null:
				_tower_emitter.scale = Vector3.ONE * 1.55
				var pulse := create_tween()
				pulse.tween_property(_tower_emitter, "scale", Vector3.ONE, 0.22)
		BasicAttackController.State.RECOVERY:
			_set_state(VisualState.ATTACK_RECOVERY)
			if _model != null:
				_model.rotation.z = 0.06
		BasicAttackController.State.IDLE:
			if _model != null:
				_model.rotation.z = 0.0
			_refresh_from_gameplay()

func _on_damage_received(event: DamageEvent) -> void:
	if event == null or not is_instance_valid(_hit_marker):
		return
	_hit_marker.visible = true
	_timed_state_remaining = hit_state_duration
	if not _dead:
		_set_state(VisualState.HIT, event.category)
	get_tree().create_timer(hit_state_duration).timeout.connect(_clear_hit_marker)

func _on_died() -> void:
	_dead = true
	_timed_state_remaining = 0.0
	actor_died.emit()
	_set_state(VisualState.DEATH)
	if _model != null:
		var tween := create_tween()
		tween.tween_property(_model, "rotation:z", PI * 0.5, 0.38)
	if is_instance_valid(_visual):
		get_tree().create_timer(death_pose_duration).timeout.connect(_hide_dead_visual)

func _on_respawned() -> void:
	_dead = false
	if _visual != null:
		_visual.show()
	if _model != null:
		_model.rotation = Vector3.ZERO
		_model.scale = Vector3.ONE
	if _hit_marker != null:
		_hit_marker.hide()
	actor_respawned.emit()
	_set_state(VisualState.IDLE)

func _on_ability_cast(ability_id: StringName, _target: Node3D, _point: Vector3) -> void:
	_timed_state_remaining = cast_state_duration
	_set_state(VisualState.CAST, ability_id)
	if _arm_right != null:
		_arm_right.rotation.x = -0.55

func _on_command_state_changed(_command_state: int) -> void:
	_refresh_from_gameplay()

func _on_level_up(level: int) -> void:
	var ring := MeshInstance3D.new()
	ring.name = "LevelUpPulse"
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.56
	ring_mesh.outer_radius = 0.66
	ring.mesh = ring_mesh
	ring.position = Vector3.UP * 2.15
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.38, 0.92, 1.0)
	ring.material_override = material
	_visual.add_child(ring)
	var label := Label3D.new()
	label.text = "LEVEL %d" % level
	label.font_size = 38
	label.modulate = Color(0.62, 0.95, 1.0)
	label.outline_size = 6
	label.position = Vector3.UP * 2.65
	_visual.add_child(label)
	var tween := create_tween()
	tween.tween_property(ring, "scale", Vector3(1.8, 1.8, 1.8), 0.65)
	tween.parallel().tween_property(ring, "transparency", 1.0, 0.65)
	tween.parallel().tween_property(label, "position:y", 3.3, 0.85)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.85)
	tween.tween_callback(ring.queue_free)
	tween.tween_callback(label.queue_free)

func _hide_dead_visual() -> void:
	if _dead and is_instance_valid(_visual):
		_visual.hide()

func _clear_hit_marker() -> void:
	if is_instance_valid(_hit_marker):
		_hit_marker.visible = false

func _refresh_from_gameplay() -> void:
	if _dead:
		_set_state(VisualState.DEATH)
		return
	if is_instance_valid(_abilities) and _abilities.is_targeting():
		_set_state(VisualState.CAST, _abilities.current_targeting_ability)
		return
	if is_instance_valid(_attacks) and _attacks.current_state != BasicAttackController.State.IDLE:
		_on_attack_state_changed(_attacks.current_state, _attacks.get_attack_point_progress(), null, _attacks.get_time_until_next_attack())
		return
	var body := _owner_actor as CharacterBody3D
	if body != null and Vector2(body.velocity.x, body.velocity.z).length() > 0.15:
		_set_state(VisualState.MOVE)
	else:
		_set_state(VisualState.IDLE)

func _set_state(new_state: VisualState, detail: StringName = &"") -> void:
	if current_state == new_state and state_detail == detail:
		return
	current_state = new_state
	state_detail = detail
	visual_state_changed.emit(current_state, state_detail)
