# Presentation contract

## Authority and state

Gameplay owns outcomes. `ActorStats`, `CombatComponent`, `BasicAttackController`, `AbilityController`, `HeroLifecycle`, and `HeroProgression` decide health, target validity, attack timing, casts, death, respawn, and level. `ActorPresentation` observes their local signals and current movement/attack state and mirrors them as `IDLE`, `MOVE`, `ATTACK_WINDUP`, `ATTACK_RELEASE`, `ATTACK_RECOVERY`, `CAST`, `HIT`, and `DEATH`. `visual_state_changed(state, detail)` is a presentation-facing contract, not a gameplay command channel.

Attack release remains authoritative in `BasicAttackController`: melee damage is applied there and ranged projectiles are created there. A future clip's animation event must never decide whether damage occurs. This avoids animation/import timing changing game rules.

## Component responsibilities

- `ActorStats`: values and stat/damage signals; no UI or scene presentation.
- `BasicAttackController` / `AbilityController`: command execution, validation, timing, and effects; no mouse input.
- `ActorPresentation`: semantic visual-state adapter, optional rigged KARN model, primitive fallback, hit/death/respawn/level feedback; no damage or cooldown ownership.
- `ActorReadability`: world health bars and floating damage labels driven by stats events.
- `DebugHUD`: read-only formatting of gameplay/telemetry values.

`ActorPresentation` runs its remaining primitive motion update at roughly 12.5 Hz. The imported KARN mesh and skeleton do not participate in gameplay collision or shape. Team/projectile/feedback materials are shared resources; brief feedback nodes are freed by their owning tween/timer.

## Phase 8 rigged KARN integration

`assets/characters/karn/karn_character.tscn` wraps the generated GLB and `KarnRigAdapter`. The adapter finds the imported `AnimationPlayer` and maps `ActorPresentation` states into `IDLE`, `RUN`, `ATTACK_1`, `CAST`, `HIT`, and `DEATH`. The rigged hero is selected by default; setting `ActorPresentation.use_rigged_karn = false` or launching with `VORN_FORCE_PRIMITIVE_KARN=1` forces the existing primitive `PlaceholderModels.build_hero()` model. Missing scene/adapter falls back automatically. Minions, towers, and non-hero actors remain primitive-built.

| Gameplay signal/state | KARN animation |
| --- | --- |
| velocity / `MOVE` | looping `RUN` |
| `ATTACK_WINDUP` → `ATTACK_RELEASE` → `ATTACK_RECOVERY` | one continuous `ATTACK_1` clip |
| `CAST` + ability id | `CAST` |
| `HIT` | `HIT` |
| `DEATH` / respawn | `DEATH` then `IDLE` on respawn |

`ATTACK_1` is 0.533 s at 30 fps. Its normalized timing is approximately windup 0.00–0.44, release 0.44–0.625, recovery 0.625–1.0. This mirrors current prototype timings (0.24 s windup, 0.08 s release feedback, 0.22 s recovery); cooldown time outside those phases is not added to the clip. `BasicAttackController` still emits release and decides damage. Blender keys and imported animation events never own damage timing. All clips are in-place; gameplay movement remains controlled by `PlayerController`.

The adapter is intentionally a small `AnimationPlayer` state mapper rather than a gameplay-aware `AnimationTree`. A future blend tree can replace its internals while keeping `ActorPresentation` as the boundary.

## Primitive fallback and collision

The player keeps its existing simple `CollisionShape3D` as a sibling of `Visual/CharacterModel`; the GLB mesh is never used as collision. If the rigged asset is unavailable, `ActorPresentation` creates the primitive KARN model. Validate both modes with the Phase 8 suite before changing the asset path. See [ART_PIPELINE.md](ART_PIPELINE.md) for reproducible source generation and import details.


## Phase 7 vertical-slice extension

KARN uses a distinct charcoal/ash-metal and ember palette. Team ownership remains in team health bars, selection markers, lane accents, tower materials, and minimap symbols; hero identity is not encoded by Team A blue alone. The primitive presentation adds an asymmetric shoulder, crested helm, visor, and heavy cleaver. Melee and ranged minions use simpler, shorter silhouettes so they remain visually subordinate. Towers add a broad platform, shaft, crown, and readable emitter.

The normal HUD uses anchored panels and reusable palette/style tokens in `ui/theme/vorn_ui_theme.gd`; the old telemetry panel stays available with F3. Ability presentation listens to successful ability casts: Rend uses a brief slash flash, Breakline has an elongated ember projectile, War Ring expands a ground ring, and Redline shows a timed hero aura. Basic ranged projectiles use short shared-material streaks and impact rings. Effects are presentation-only and short-lived.

Environment props are created by `world/environment_dressing.gd`, have no collision, and remain sparse around the fight lane: ridge silhouettes, boulders, team crystals, and a paired center landmark. The lane remains intentionally flat for steering and combat tests. Limit unique materials, keep prop counts low, and avoid particle systems, screen-space blur, expensive outlines, or mandatory real-time post-processing for mobile.

The Phase 7 camera opens around the Team A approach (rig X = −10) with a fixed ~54° pitch, orthographic size 20, pan speed 0.038, and zoom limits 18–30. It remains independent of KARN and has no free-look.
