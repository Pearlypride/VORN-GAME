extends Node3D
## Small presentation-only dressing pass. Props intentionally have no collision shapes.

const ROCK_DARK: Material = preload("res://gameplay/presentation/materials/rock_dark.tres")
const ROCK_LIGHT: Material = preload("res://gameplay/presentation/materials/rock_light.tres")
const CRYSTAL_A: Material = preload("res://gameplay/presentation/materials/crystal_blue.tres")
const CRYSTAL_B: Material = preload("res://gameplay/presentation/materials/crystal_ember.tres")

func _ready() -> void:
	_add_side_ridges()
	_add_boulder_groups()
	_add_center_landmark()
	_add_team_crystals(-28.0, CRYSTAL_A)
	_add_team_crystals(28.0, CRYSTAL_B)

func _add_side_ridges() -> void:
	var wall_mesh := BoxMesh.new()
	wall_mesh.size = Vector3(7.0, 1.8, 1.1)
	var cap_mesh := BoxMesh.new()
	cap_mesh.size = Vector3(7.25, 0.24, 1.25)
	for index in 12:
		var x := -38.5 + float(index) * 7.0
		for side in [-1.0, 1.0]:
			var z: float = side * 25.0
			_add_mesh("Ridge", wall_mesh, Vector3(x, 0.45, z), ROCK_DARK, Vector3(1.0, randf_range(0.75, 1.25), 1.0), randf_range(-0.08, 0.08))
			_add_mesh("RidgeCap", cap_mesh, Vector3(x, 1.42, z), ROCK_LIGHT, Vector3(1.0, 1.0, 1.0), randf_range(-0.06, 0.06))

func _add_boulder_groups() -> void:
	var boulder_mesh := SphereMesh.new()
	boulder_mesh.radius = 1.0
	boulder_mesh.height = 1.5
	var small_mesh := SphereMesh.new()
	small_mesh.radius = 0.58
	small_mesh.height = 0.9
	for index in 15:
		var x := -34.0 + float(index) * 4.8
		var side := -1.0 if index % 2 == 0 else 1.0
		var z := side * randf_range(7.2, 11.2)
		_add_mesh("Boulder", boulder_mesh, Vector3(x, 0.3, z), ROCK_DARK, Vector3(randf_range(1.2, 2.0), randf_range(0.75, 1.35), randf_range(1.0, 1.8)), randf_range(-0.3, 0.3))
		_add_mesh("BoulderSmall", small_mesh, Vector3(x + randf_range(-1.2, 1.2), 0.18, z + side * 1.25), ROCK_LIGHT, Vector3.ONE * randf_range(0.7, 1.2), randf_range(-0.2, 0.2))

func _add_center_landmark() -> void:
	var plinth := CylinderMesh.new()
	plinth.top_radius = 2.5
	plinth.bottom_radius = 3.0
	plinth.height = 0.52
	var pillar := BoxMesh.new()
	pillar.size = Vector3(0.55, 3.4, 0.55)
	var lintel := BoxMesh.new()
	lintel.size = Vector3(3.6, 0.55, 0.72)
	for side in [-1.0, 1.0]:
		var z: float = side * 10.3
		_add_mesh("LandmarkPlinth", plinth, Vector3(0.0, 0.24, z), ROCK_DARK)
		_add_mesh("LandmarkPillar", pillar, Vector3(-1.35, 1.85, z), ROCK_LIGHT, Vector3.ONE, side * -0.04)
		_add_mesh("LandmarkPillar", pillar, Vector3(1.35, 1.85, z), ROCK_LIGHT, Vector3.ONE, side * 0.04)
		_add_mesh("LandmarkLintel", lintel, Vector3(0.0, 3.55, z), ROCK_DARK)

func _add_team_crystals(x: float, material: Material) -> void:
	var crystal := PrismMesh.new()
	crystal.size = Vector3(0.72, 2.6, 0.72)
	var cluster := PrismMesh.new()
	cluster.size = Vector3(0.48, 1.55, 0.5)
	for index in 3:
		var z := -3.6 + float(index) * 3.6
		_add_mesh("TeamCrystal", crystal, Vector3(x, 1.2, z), material, Vector3(1.0, randf_range(0.68, 1.0), 1.0), float(index) * 0.8)
		_add_mesh("CrystalShard", cluster, Vector3(x + (1.15 if index % 2 == 0 else -1.15), 0.72, z + 0.55), material, Vector3.ONE * 0.72, -0.45)

func _add_mesh(node_name: String, mesh: Mesh, at: Vector3, material: Material, stretch: Vector3 = Vector3.ONE, yaw: float = 0.0) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = at
	instance.scale = stretch
	instance.rotation.y = yaw
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
