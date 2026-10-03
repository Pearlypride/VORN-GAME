# Presentation contract

## Authority and state

Gameplay owns outcomes. `ActorStats`, `CombatComponent`, `BasicAttackController`, `AbilityController`, `HeroLifecycle`, and `HeroProgression` decide health, target validity, attack timing, casts, death, respawn, and level. `ActorPresentation` observes their local signals and current movement/attack state and mirrors them as `IDLE`, `MOVE`, `ATTACK_WINDUP`, `ATTACK_RELEASE`, `ATTACK_RECOVERY`, `CAST`, `HIT`, and `DEATH`. `visual_state_changed(state, detail)` is a presentation-facing contract, not a gameplay command channel.

Attack release remains authoritative in `BasicAttackController`: melee damage is applied there and ranged projectiles are created there. A future clip's animation event must never decide whether damage occurs. This avoids animation/import timing changing game rules.

## Component responsibilities

- `ActorStats`: values and stat/damage signals; no UI or scene presentation.
- `BasicAttackController` / `AbilityController`: command execution, validation, timing, and effects; no mouse input.
- `ActorPresentation`: placeholder model, procedural pose, hit/death/respawn/level feedback; no damage or cooldown ownership.
- `ActorReadability`: world health bars and floating damage labels driven by stats events.
- `DebugHUD`: read-only formatting of gameplay/telemetry values.

`ActorPresentation` runs its lightweight motion update at roughly 12.5 Hz. Its primitive meshes do not participate in collision or gameplay shape. Team/projectile/feedback materials are shared resources; brief feedback nodes are freed by their owning tween/timer.

## Future AnimationTree integration

Keep the state contract and replace the procedural pose driver behind it with an `AnimationTree`/`AnimationPlayer` adapter:

| Gameplay signal/state | Future clip/parameter |
| --- | --- |
| velocity / `MOVE` | locomotion blend by speed and direction |
| `ATTACK_WINDUP` | attack anticipation; controller supplies remaining windup |
| `ATTACK_RELEASE` | strike/release pose synchronized to the controller's release signal |
| `ATTACK_RECOVERY` | recovery/backswing; controller owns recovery end |
| `CAST` + ability id | ability-specific cast pose |
| `HIT` | short hit reaction |
| `DEATH` / respawn signal | death pose then reset to idle on respawn |

The controller's clock and events remain the source of truth. Animation can interpolate, blend, and present those events, but cannot apply damage, validate targets, or extend/reduce cooldowns.

## Placeholder strategy

`PlaceholderModels` builds low-node-count primitives for a humanoid hero, visibly broad melee and slim staff ranged minions, and an elevated-emitter tower. Materials are shared `.tres` resources. This is prototype readability, not production character art, rigging, or animation. Replace the builders/models while preserving gameplay nodes and the `ActorPresentation` state contract.


## Phase 7 vertical-slice extension

KARN uses a distinct charcoal/ash-metal and ember palette. Team ownership remains in team health bars, selection markers, lane accents, tower materials, and minimap symbols; hero identity is not encoded by Team A blue alone. The primitive presentation adds an asymmetric shoulder, crested helm, visor, and heavy cleaver. Melee and ranged minions use simpler, shorter silhouettes so they remain visually subordinate. Towers add a broad platform, shaft, crown, and readable emitter.

The normal HUD uses anchored panels and reusable palette/style tokens in `ui/theme/vorn_ui_theme.gd`; the old telemetry panel stays available with F3. Ability presentation listens to successful ability casts: Rend uses a brief slash flash, Breakline has an elongated ember projectile, War Ring expands a ground ring, and Redline shows a timed hero aura. Basic ranged projectiles use short shared-material streaks and impact rings. Effects are presentation-only and short-lived.

Environment props are created by `world/environment_dressing.gd`, have no collision, and remain sparse around the fight lane: ridge silhouettes, boulders, team crystals, and a paired center landmark. The lane remains intentionally flat for steering and combat tests. Limit unique materials, keep prop counts low, and avoid particle systems, screen-space blur, expensive outlines, or mandatory real-time post-processing for mobile.

The Phase 7 camera opens around the Team A approach (rig X = −10) with a fixed ~54° pitch, orthographic size 20, pan speed 0.038, and zoom limits 18–30. It remains independent of KARN and has no free-look.
