"""Headless integrity validator for generated KARN source and GLB export."""

from pathlib import Path
import bpy

ROOT = Path(__file__).resolve().parents[2]
BLEND = ROOT / "art/blender/karn.blend"
GLB = ROOT / "art/exports/karn.glb"
EXPECTED_BONES = {
	"ROOT", "PELVIS", "SPINE", "CHEST", "NECK", "HEAD",
	"UPPER_ARM_L", "FOREARM_L", "HAND_L", "THIGH_L", "SHIN_L", "FOOT_L",
	"UPPER_ARM_R", "FOREARM_R", "HAND_R", "THIGH_R", "SHIN_R", "FOOT_R", "WEAPON",
}
EXPECTED_ANIMS = {"IDLE", "RUN", "ATTACK_1", "CAST", "HIT", "DEATH"}


def require(condition, message):
	if not condition:
		raise RuntimeError("KARN VALIDATION FAILED: " + message)
	print("PASS:", message)


def validate():
	require(BLEND.is_file(), f"source blend exists: {BLEND}")
	require(GLB.is_file() and GLB.stat().st_size > 0, f"non-empty GLB exists: {GLB}")
	bpy.ops.wm.open_mainfile(filepath=str(BLEND))
	armatures = [o for o in bpy.data.objects if o.type == "ARMATURE" and o.get("vorn_character") == "KARN"]
	meshes = [o for o in bpy.data.objects if o.type == "MESH" and o.get("vorn_character") == "KARN"]
	require(len(armatures) == 1, "exactly one tagged KARN armature exists")
	require(len(meshes) == 1, "exactly one tagged KARN body mesh exists")
	arm, mesh = armatures[0], meshes[0]
	bones = {b.name for b in arm.data.bones}
	require(EXPECTED_BONES <= bones, "all expected humanoid and weapon bones exist")
	anim_names = {a.name for a in bpy.data.actions}
	require(EXPECTED_ANIMS <= anim_names, "IDLE/RUN/ATTACK_1/CAST/HIT/DEATH actions exist")
	require(len(mesh.data.materials) in range(3, 6), "mesh uses 3–5 shared materials")
	require(any(m.type == "ARMATURE" and m.object == arm for m in mesh.modifiers), "body mesh has armature skin modifier")
	deform_bones = EXPECTED_BONES - {"ROOT"}
	groups = {g.name: g for g in mesh.vertex_groups}
	require(deform_bones <= set(groups), "all deform bones have explicit skin groups")
	used_groups = {name for name, group in groups.items() if any(any(link.group == group.index and link.weight > 0.0 for link in vertex.groups) for vertex in mesh.data.vertices)}
	require(deform_bones <= used_groups, "each deform bone influences at least one mesh vertex")
	require(len(mesh.data.vertices) > 0 and len(mesh.data.polygons) > 0, "KARN mesh has geometry")
	triangles = sum(max(0, len(poly.vertices) - 2) for poly in mesh.data.polygons)
	print("SOURCE_STATS", {"vertices": len(mesh.data.vertices), "triangles": triangles, "bones": len(bones), "materials": len(mesh.data.materials), "animations": sorted(EXPECTED_ANIMS), "glb_bytes": GLB.stat().st_size})
	# Independently import the exported container in a clean scene to catch GLB
	# corruption or missing exported skeleton/mesh/animation data.
	bpy.ops.wm.read_factory_settings(use_empty=True)
	bpy.ops.import_scene.gltf(filepath=str(GLB))
	imported_meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
	imported_arms = [o for o in bpy.context.scene.objects if o.type == "ARMATURE"]
	require(imported_meshes, "GLB imports with at least one mesh")
	require(imported_arms, "GLB imports with an armature")
	require(any(o.parent in imported_arms or any(m.type == "ARMATURE" for m in o.modifiers) for o in imported_meshes), "GLB mesh remains skinned")
	imported_actions = {a.name.rsplit("|", 1)[-1] for a in bpy.data.actions}
	require(EXPECTED_ANIMS <= imported_actions, "GLB contains all six expected animation actions")
	print("GLB_IMPORT_STATS", {"meshes": len(imported_meshes), "armatures": len(imported_arms), "animations": sorted(imported_actions)})
	print("KARN_VALIDATION_RESULT: PASS")


if __name__ == "__main__":
	validate()
