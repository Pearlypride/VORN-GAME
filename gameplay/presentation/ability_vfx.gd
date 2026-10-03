class_name AbilityVFX
extends Node
## Local ability presentation adapter. It listens to successful casts; effects stay non-authoritative.

const REND_MATERIAL: Material = preload("res://gameplay/presentation/materials/vfx_rend.tres")
const BREAKLINE_MATERIAL: Material = preload("res://gameplay/presentation/materials/vfx_breakline.tres")
const WARRING_MATERIAL: Material = preload("res://gameplay/presentation/materials/vfx_warring.tres")
const REDLINE_MATERIAL: Material = preload("res://gameplay/presentation/materials/hero_glow.tres")

var _caster: Node3D
var _controller: AbilityController
var _aura: MeshInstance3D

func _ready() -> void:
	_caster = get_parent() as Node3D
	_controller = _caster.get_node("AbilityController") as AbilityController
	_controller.ability_cast.connect(_on_ability_cast)
	var stats := _caster.get_node_or_null("Stats") as ActorStats
	if stats != null:
		stats.died.connect(_stop_redline)
	var lifecycle := _caster.get_node_or_null("HeroLifecycle") as HeroLifecycle
	if lifecycle != null:
		lifecycle.hero_respawned.connect(_stop_redline)
	_create_aura()

func _on_ability_cast(ability_id: StringName, target: Node3D, point: Vector3) -> void:
	match ability_id:
		&"q":
			_spawn_rend(target.global_position if is_instance_valid(target) else point)
		&"w":
			pass # Breakline's launched projectile carries its own distinct elongated model.
		&"e":
			_spawn_warring(point)
		&"r":
			_start_redline()

func _spawn_rend(at: Vector3) -> void:
	var slash := MeshInstance3D.new()
	slash.name = "RendSlashVFX"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.17, 0.42, 1.75)
	slash.mesh = mesh
	slash.material_override = REND_MATERIAL
	slash.position = at + Vector3.UP * 0.78
	slash.rotation.y = _caster.global_position.direction_to(at).signed_angle_to(Vector3.FORWARD, Vector3.UP)
	var scene := get_tree().current_scene
	(scene if scene != null else get_tree().root).add_child(slash)
	var tween := slash.create_tween()
	tween.tween_property(slash, "scale", Vector3(1.15, 1.0, 1.35), 0.13)
	tween.parallel().tween_property(slash, "transparency", 1.0, 0.16)
	tween.tween_callback(slash.queue_free)

func _spawn_warring(at: Vector3) -> void:
	var ring := MeshInstance3D.new()
	ring.name = "WarRingVFX"
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.76
	mesh.outer_radius = 0.92
	ring.mesh = mesh
	ring.material_override = WARRING_MATERIAL
	ring.rotation_degrees.x = 90.0
	ring.position = Vector3(at.x, 0.085, at.z)
	var scene := get_tree().current_scene
	(scene if scene != null else get_tree().root).add_child(ring)
	var tween := ring.create_tween()
	tween.tween_property(ring, "scale", Vector3(3.0, 3.0, 3.0), 0.36)
	tween.parallel().tween_property(ring, "transparency", 1.0, 0.36)
	tween.tween_callback(ring.queue_free)

func _create_aura() -> void:
	_aura = MeshInstance3D.new()
	_aura.name = "RedlineAura"
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.67
	mesh.outer_radius = 0.82
	_aura.mesh = mesh
	_aura.material_override = REDLINE_MATERIAL
	_aura.position = Vector3.UP * 0.1
	_aura.rotation_degrees.x = 90.0
	_aura.scale = Vector3(1.0, 0.48, 1.0)
	_aura.visible = false
	_caster.get_node("Visual").add_child(_aura)

func _start_redline() -> void:
	_aura.visible = true
	_aura.scale = Vector3(0.7, 0.34, 0.7)
	var pulse := _aura.create_tween()
	pulse.tween_property(_aura, "scale", Vector3(1.35, 0.6, 1.35), 0.22)
	pulse.tween_property(_aura, "scale", Vector3(1.0, 0.48, 1.0), 0.25)
	var definition := _controller.get_ability_definition(&"r")
	var effect := definition.effect as SelfBuffEffect if definition != null else null
	var duration := effect.duration if effect != null else 6.0
	get_tree().create_timer(duration).timeout.connect(_stop_redline)

func _stop_redline() -> void:
	if is_instance_valid(_aura):
		_aura.hide()
