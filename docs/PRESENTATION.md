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
