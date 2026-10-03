# VORN character art pipeline

## Toolchain and reproducible commands

The Phase 8 asset was built with Blender **5.2.2 LTS** at `/snap/bin/blender`. Rebuild from the project root with:

```sh
/snap/bin/blender --background --python tools/blender/build_karn.py
```

The script starts from Blender factory settings, creates the same named mesh, materials, armature, and animation actions, writes `art/blender/karn.blend`, and exports `art/exports/karn.glb`. It does not need UI interaction or external assets. Validate the source and independently import/inspect the GLB with:

```sh
/snap/bin/blender --background --python tools/blender/validate_character.py
```

Then import the GLB into Godot and run structural/runtime validation:

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/phase8_art_pipeline_validation.gd
```

`tools/blender/export_character.py` is the shared selection/export helper. Paths derive from the script location, so the commands can be run from the repository root without manual Blender setup.

## Directory conventions

| Path | Purpose |
| --- | --- |
| `tools/blender/` | Deterministic Blender build, export, and validation scripts |
| `art/blender/` | Editable `.blend` source; `.gdignore` keeps Godot from treating source files as runtime assets |
| `art/exports/` | Rebuilt interchange assets, including `karn.glb` |
| `assets/characters/karn/` | Godot-facing scene wrapper and model-only adapter |

Godot imports the GLB in place from `art/exports/`; there is no duplicate GLB under `assets/`. `assets/characters/karn/karn_character.tscn` instances that imported scene and attaches `KarnRigAdapter`.

## KARN mesh, rig, and materials

KARN is assembled from low-poly Blender primitives into one joined body mesh. The broad charcoal torso, narrowed waist, armored heavy stance, oversized left pauldron, partially covered helmet, and single large cleaver favor readable shapes over fine surface detail. Mesh orientation is authored with Blender Z-up and the character facing local -Y; the standard glTF exporter writes the Y-up GLB coordinate convention expected by Godot. Character height is authored at about 2.35 Blender units/metres.

The source mesh is skinned to one armature. Limb/armor vertices receive a deterministic nearest-bone rigid weight assignment; this is a prototype skin, not production smooth deformation. Overlapping armor plates hide most segment boundaries. The weapon geometry is weighted to the `WEAPON` attachment bone under `HAND_R`.

The skeleton has 19 bones:

```text
ROOT
└─ PELVIS
   └─ SPINE
      └─ CHEST
         └─ NECK
            └─ HEAD
         ├─ UPPER_ARM_L → FOREARM_L → HAND_L
         └─ UPPER_ARM_R → FOREARM_R → HAND_R → WEAPON
   ├─ THIGH_L → SHIN_L → FOOT_L
   └─ THIGH_R → SHIN_R → FOOT_R
```

The body uses four shared Principled materials: charcoal, warm metal, ember accent, and muted cloth. Materials have simple solid colors and modest metallic/roughness values; no textures, transparency, procedural shaders, Blender lights, or cameras are exported.

## Animation and timing contract

All clips are in-place: `ROOT` does not translate, and Godot gameplay movement remains authoritative. The GLB contains `IDLE`, `RUN`, `ATTACK_1`, `CAST`, `HIT`, and `DEATH`.

At 30 fps, `ATTACK_1` is approximately 0.533 seconds. Normalized phases are approximately:

| Clip fraction | Presentation phase | Prototype duration |
| --- | --- | --- |
| 0.00–0.44 | Windup / anticipation | 0.24 s |
| 0.44–0.625 | Release pose | 0.08–0.10 s |
| 0.625–1.00 | Recovery / return | 0.20–0.22 s |

The small discrepancy comes from frame quantization. `ActorPresentation` sees the `BasicAttackController` state changes; `KarnRigAdapter` starts `ATTACK_1` on windup and leaves that clip playing through release and recovery. The controller's release signal still decides whether/how much damage occurs. Do not add authoritative damage notifies or gameplay timing to Blender actions. An `AnimationTree` or blend layer may later replace the adapter internals while keeping this state contract.

## Godot integration and fallback

The player's `ActorPresentation` attempts to instantiate the dedicated KARN scene. `KarnRigAdapter` searches its imported model for an `AnimationPlayer` and maps semantic states to clips. If loading the packed scene or adapter fails, it falls back to `PlaceholderModels.build_hero()`. To choose the fallback intentionally, either:

- set `use_rigged_karn = false` on the player's `ActorPresentation` in the scene inspector, or
- launch with `VORN_FORCE_PRIMITIVE_KARN=1` in the environment.

The player's `CollisionShape3D`, combat nodes, stats, and commands stay outside the model scene. Do not derive gameplay collision from render triangles. Keep model scale adjustments on the visual instance so collider tuning remains explicit and separate.

## Prototype budget and future heroes

Current generated budget: **580 vertices, 1,040 triangles, 19 bones, 4 materials, 6 clips, and about 205 KB GLB**. The `.blend` source is also generated and tracked; it is approximately under 1 MB and should remain reasonable to version alongside its script. These values are a practical prototype budget, not device profiling results.

For another hero, add a deterministic build script with the same clean-scene workflow; preserve a compact humanoid skeleton/weapon attachment contract where animation retargeting is useful; export a GLB containing only that character hierarchy; add a Godot scene wrapper and model-only adapter; keep collision and gameplay outside the imported scene; provide a primitive or previous-model fallback; and extend the Blender and Godot validators before switching the default presentation. Generated assets must be rebuildable from checked-in scripts and source settings.
