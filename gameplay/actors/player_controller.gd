class_name PlayerController
extends CharacterBody3D
## Executes movement and attack-move orders independent of their input source.

signal command_state_changed(state: int)

enum CommandState { IDLE, MOVE, ATTACK, STOP }

@export_range(0.1, 100.0, 0.1) var acceleration: float = 24.0
@export_range(0.05, 1.0, 0.05) var arrival_tolerance: float = 0.25
@export var hero_definition: HeroDefinition
var _stats: ActorStats
var _combat: CombatComponent
var _abilities: AbilityController
var _destination: Vector3
var _has_destination: bool = false
var command_state: CommandState = CommandState.IDLE

func _ready() -> void:
	_stats = $Stats as ActorStats
	_combat = $Combat as CombatComponent
	_abilities = $AbilityController as AbilityController
	if hero_definition != null:
		_stats.configure_from_hero(hero_definition)
		_abilities.initialize(hero_definition, self, _stats)
	_combat.target_changed.connect(_on_target_changed)

func move_to(world_position: Vector3) -> void:
	if not is_alive():
		return
	_combat.set_target(null)
	_destination = world_position
	_has_destination = true
	_set_command_state(CommandState.MOVE)

func attack_target(target: Node3D) -> void:
	if not is_alive():
		return
	_has_destination = false
	_combat.set_target(target)
	if _combat.target == null:
		velocity.x = 0.0
		velocity.z = 0.0
		_set_command_state(CommandState.IDLE)
		return
	_set_command_state(CommandState.ATTACK)

func stop_command() -> void:
	_has_destination = false
	_combat.set_target(null)
	velocity.x = 0.0
	velocity.z = 0.0
	_set_command_state(CommandState.STOP)

func clear_command() -> void:
	_has_destination = false
	_combat.set_target(null)
	velocity.x = 0.0
	velocity.z = 0.0
	_set_command_state(CommandState.IDLE)

func get_command_state_name() -> String:
	return CommandState.keys()[command_state]

func is_alive() -> bool:
	return _stats != null and _stats.current_health > 0.0

func _set_command_state(state: CommandState) -> void:
	if command_state == state:
		return
	command_state = state
	command_state_changed.emit(command_state)

func _on_target_changed(new_target: Node3D) -> void:
	if new_target == null and command_state == CommandState.ATTACK:
		_set_command_state(CommandState.IDLE)

func _physics_process(delta: float) -> void:
	if not is_alive():
		velocity = Vector3.ZERO
		return
	var desired_direction := Vector3.ZERO
	var desired_speed := _stats.get_effective_movement_speed()
	var desired_target: Vector3
	var has_desired_target := false
	var target_stats := _combat.get_target_stats()
	if _combat.target != null and is_instance_valid(_combat.target) and target_stats != null and target_stats.current_health > 0.0:
		desired_target = _combat.target.global_position
		has_desired_target = true
	elif _has_destination:
		desired_target = _destination
		has_desired_target = true

	if has_desired_target:
		var offset := desired_target - global_position
		offset.y = 0.0
		var distance := offset.length()
		var stop_distance := arrival_tolerance
		if _combat.target != null and is_instance_valid(_combat.target):
			stop_distance = maxf(arrival_tolerance, _stats.attack_range)
		if distance <= stop_distance:
			if _combat.target == null:
				_has_destination = false
		else:
			desired_direction = offset / distance
			if _combat.target == null:
				var braking_distance := maxf(0.0, distance - stop_distance)
				desired_speed = minf(desired_speed, sqrt(2.0 * acceleration * braking_distance))
	var desired_velocity := desired_direction * desired_speed
	velocity.x = move_toward(velocity.x, desired_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, desired_velocity.z, acceleration * delta)
	move_and_slide()
	if desired_direction.length_squared() > 0.001:
		$Visual.look_at(global_position + desired_direction, Vector3.UP)
