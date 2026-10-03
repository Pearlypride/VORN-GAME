class_name PlaceholderModels
extends RefCounted
## Cheap primitive model builders. All use shared materials and leave collision untouched.

const TEAM_A_MATERIAL: Material = preload("res://gameplay/presentation/materials/team_a.tres")
const TEAM_B_MATERIAL: Material = preload("res://gameplay/presentation/materials/team_b.tres")
const ACCENT_MATERIAL: Material = preload("res://gameplay/presentation/materials/team_accent.tres")
const TEAM_A_LIGHT: Material = preload("res://gameplay/presentation/materials/team_a_light.tres")
const HERO_IRON: Material = preload("res://gameplay/presentation/materials/hero_iron.tres")
const HERO_EMBER: Material = preload("res://gameplay/presentation/materials/hero_ember.tres")
const HERO_EDGE: Material = preload("res://gameplay/presentation/materials/hero_edge.tres")
const HERO_GLOW: Material = preload("res://gameplay/presentation/materials/hero_glow.tres")
const ROCK_DARK: Material = preload("res://gameplay/presentation/materials/rock_dark.tres")
const ROCK_LIGHT: Material = preload("res://gameplay/presentation/materials/rock_light.tres")
const TEAM_B_LIGHT: Material = preload("res://gameplay/presentation/materials/team_b_light.tres")

static func build_hero() -> Node3D:
	var root := Node3D.new()
	root.name = "CharacterModel"
	_add(root, "Torso", _capsule(0.37, 0.94), Vector3(0.0, 1.08, 0.0), HERO_IRON)
	_add(root, "ChestPlate", _box(Vector3(0.63, 0.53, 0.22)), Vector3(0.0, 1.2, -0.12), HERO_EMBER)
	_add(root, "Belt", _box(Vector3(0.57, 0.16, 0.34)), Vector3(0.0, 0.76, 0.0), HERO_EDGE)
	_add(root, "Head", _sphere(0.23), Vector3(0.0, 1.78, 0.0), HERO_IRON)
	_add(root, "HelmCrest", _box(Vector3(0.18, 0.37, 0.13)), Vector3(0.0, 2.08, -0.02), HERO_EMBER).rotation.x = -0.18
	_add(root, "Visor", _box(Vector3(0.29, 0.075, 0.12)), Vector3(0.0, 1.8, -0.2), HERO_GLOW)
	_add(root, "ShoulderLeft", _box(Vector3(0.46, 0.3, 0.42)), Vector3(-0.49, 1.55, 0.0), HERO_EMBER).rotation.z = 0.12
	_add(root, "ShoulderRight", _box(Vector3(0.32, 0.22, 0.31)), Vector3(0.47, 1.49, 0.0), HERO_IRON)
	_add(root, "ArmLeft", _capsule(0.14, 0.59), Vector3(-0.49, 1.12, 0.0), HERO_IRON)
	_add(root, "ArmRight", _capsule(0.15, 0.62), Vector3(0.44, 1.08, 0.0), HERO_IRON)
	_add(root, "LegLeft", _capsule(0.16, 0.68), Vector3(-0.2, 0.34, 0.0), HERO_IRON)
	_add(root, "LegRight", _capsule(0.16, 0.68), Vector3(0.2, 0.34, 0.0), HERO_IRON)
	_add(root, "KneeLeft", _box(Vector3(0.27, 0.2, 0.28)), Vector3(-0.2, 0.42, -0.13), HERO_EDGE)
	_add(root, "KneeRight", _box(Vector3(0.27, 0.2, 0.28)), Vector3(0.2, 0.42, -0.13), HERO_EDGE)
	var weapon_pivot := Node3D.new()
	weapon_pivot.name = "WeaponPivot"
	weapon_pivot.position = Vector3(0.57, 0.96, -0.03)
	root.add_child(weapon_pivot)
	_add(weapon_pivot, "WeaponGrip", _cylinder(0.065, 0.58), Vector3(0.08, 0.02, 0.0), HERO_EMBER).rotation.z = -0.42
	_add(weapon_pivot, "WeaponPommel", _sphere(0.12), Vector3(-0.04, -0.28, 0.0), HERO_GLOW)
	_add(weapon_pivot, "WeaponHead", _box(Vector3(0.48, 0.74, 0.16)), Vector3(0.24, 0.5, 0.0), HERO_EDGE).rotation.z = -0.32
	_add(weapon_pivot, "WeaponSpike", _cylinder(0.025, 0.48), Vector3(0.24, 1.0, 0.0), HERO_EMBER).rotation.z = -0.32
	return root

static func build_minion(minion_type: MinionDefinition.MinionType, team: TeamRules.Team) -> Node3D:
	var root := Node3D.new()
	root.name = "CharacterModel"
	var body_material := _team_material(team)
	var light_material := _team_light(team)
	if minion_type == MinionDefinition.MinionType.MELEE:
		_add(root, "Body", _capsule(0.36, 0.72), Vector3(0.0, 0.53, 0.0), body_material)
		_add(root, "Breastplate", _box(Vector3(0.72, 0.32, 0.25)), Vector3(0.0, 0.62, -0.15), light_material)
		_add(root, "ShoulderArmor", _box(Vector3(0.86, 0.24, 0.42)), Vector3(0.0, 0.85, 0.0), ACCENT_MATERIAL)
		_add(root, "Helmet", _sphere(0.24), Vector3(0.0, 1.12, 0.0), body_material).scale = Vector3(1.0, 0.8, 0.9)
		_add(root, "Faceplate", _box(Vector3(0.25, 0.1, 0.12)), Vector3(0.0, 1.1, -0.2), light_material)
		_add(root, "ShortBlade", _box(Vector3(0.1, 0.55, 0.09)), Vector3(0.49, 0.61, -0.06), HERO_EDGE).rotation.z = -0.32
		_add(root, "BladeGrip", _cylinder(0.04, 0.23), Vector3(0.48, 0.35, -0.06), ACCENT_MATERIAL)
	else:
		_add(root, "Body", _capsule(0.24, 0.76), Vector3(0.0, 0.53, 0.0), body_material)
		_add(root, "Mantle", _box(Vector3(0.46, 0.62, 0.24)), Vector3(0.0, 0.66, 0.13), light_material)
		_add(root, "Hood", _sphere(0.26), Vector3(0.0, 1.08, 0.0), body_material).scale = Vector3(0.9, 0.8, 1.0)
		_add(root, "Mask", _box(Vector3(0.2, 0.11, 0.12)), Vector3(0.0, 1.05, -0.23), HERO_GLOW)
		_add(root, "Staff", _cylinder(0.055, 1.25), Vector3(0.46, 0.66, -0.04), ACCENT_MATERIAL)
		_add(root, "StaffCore", _sphere(0.17), Vector3(0.46, 1.34, -0.04), light_material)
		_add(root, "EmitterRing", _torus(0.18, 0.23), Vector3(0.46, 1.34, -0.04), HERO_GLOW)
	return root

static func build_tower(team: TeamRules.Team) -> Node3D:
	var root := Node3D.new()
	root.name = "TowerModel"
	var body_material := _team_material(team)
	var light_material := _team_light(team)
	_add(root, "Platform", _cylinder(2.05, 0.46), Vector3(0.0, 0.23, 0.0), ROCK_DARK)
	_add(root, "Foundation", _cylinder(1.54, 0.5), Vector3(0.0, 0.62, 0.0), ROCK_LIGHT)
	_add(root, "LowerBand", _cylinder(1.22, 0.2), Vector3(0.0, 0.98, 0.0), body_material)
	_add(root, "Shaft", _cylinder(0.86, 2.18), Vector3(0.0, 2.22, 0.0), ROCK_DARK)
	_add(root, "TeamSigil", _box(Vector3(0.9, 0.58, 0.16)), Vector3(0.0, 2.18, -0.81), light_material)
	_add(root, "UpperPlatform", _cylinder(1.34, 0.3), Vector3(0.0, 3.48, 0.0), ROCK_LIGHT)
	_add(root, "Crown", _cylinder(0.92, 0.72), Vector3(0.0, 3.97, 0.0), ROCK_DARK)
	_add(root, "Emitter", _sphere(0.44), Vector3(0.0, 4.54, 0.0), light_material)
	_add(root, "EmitterCore", _sphere(0.2), Vector3(0.0, 4.54, 0.0), HERO_GLOW)
	return root

static func _add(parent: Node3D, node_name: String, mesh: Mesh, at: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = at
	instance.material_override = material
	parent.add_child(instance)
	return instance

static func _team_material(team: TeamRules.Team) -> Material:
	return TEAM_A_MATERIAL if team == TeamRules.Team.TEAM_A else TEAM_B_MATERIAL

static func _team_light(team: TeamRules.Team) -> Material:
	return TEAM_A_LIGHT if team == TeamRules.Team.TEAM_A else TEAM_B_LIGHT

static func _box(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh

static func _sphere(radius: float) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	return mesh

static func _cylinder(radius: float, height: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	return mesh

static func _torus(inner: float, outer: float) -> TorusMesh:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner
	mesh.outer_radius = outer
	return mesh

static func _capsule(radius: float, height: float) -> CapsuleMesh:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	return mesh
