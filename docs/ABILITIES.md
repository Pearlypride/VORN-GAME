# Ability framework

## Lifecycle

Each `AbilityDefinition` is a Godot Resource containing an identifier, debug/display name, cast type, mana cost, cooldown, cast range, and an `AbilityEffect` Resource. The hero Resource references the abilities. `AbilityController.initialize()` creates per-caster runtime cooldown state without mutating the shared definition assets.

Q/W/E request an ability and enter `TARGETING` without spending resources. The input adapter then confirms a target or point. R is `SELF` and executes immediately. On successful execution, the controller checks the caster is alive, the target/point is valid and in range where required, enough mana is available, and cooldown is ready. It then spends mana, starts cooldown, builds an `AbilityCastContext`, and executes the effect. Invalid attempts spend no mana and start no cooldown. Current exposed states are `READY`, `TARGETING`, and `COOLDOWN`; the HUD also shows insufficient mana.

Cooldowns are runtime data held by the controller and tick in `_physics_process`. They continue while the hero is dead. Mana regeneration is on `ActorStats` and pauses while dead. Respawn restores health and mana to maximum but does not reset ability cooldowns.

## Cast types

- **TARGETED:** confirmation needs a live actor in the `combat_target` group and within cast range.
- **POINT:** confirmation needs a world point within cast range.
- **AREA:** confirmation validates a point, then the effect evaluates all live actors in radius.
- **SELF:** no target confirmation or range check; the effect runs on the caster.

Q/W/E enter targeting mode when requested. Left-click confirms. Right-click or Escape cancels. Cancelling leaves mana and cooldown untouched and does not discard the current move/attack command. R executes as soon as its command is accepted.

## Prototype hero kit

The temporary resource at `gameplay/heroes/vorn_test_hero.tres` is named `VORN_TEST_HERO`.

| Key | Ability | Type | Cost | Cooldown | Range | Effect |
|---|---|---|---:|---:|---:|---|
| Q | Targeted Strike | Targeted | 60 mana | 5 s | 8 | Instantly deals 120 damage to the confirmed enemy. |
| W | Line Projectile | Point | 80 mana | 8 s | 12 | Fires a debug projectile at 14 units/s; it damages the first live enemy hit for 150, or disappears at max travel distance. |
| E | Area Damage | Area | 70 mana | 10 s | 9 | Deals 90 damage to each live enemy within 3 units of the confirmed point. |
| R | Overdrive | Self | 120 mana | 35 s | — | For 6 s, movement speed is multiplied by 1.3 and basic attack interval by 0.7. |

Values live in `.tres` resources and are prototype tuning, not final hero balance.

## Mana and effect extension

`ActorStats.spend_mana()` refuses costs that would go below zero. `restore_mana()` clamps at maximum and returns the amount actually restored. Health/mana start full. Hero death disables gameplay and the respawn loop restores both to maximum; health/mana regeneration pauses while dead.

Add an ability by creating an `AbilityDefinition` resource and an `AbilityEffect` subclass Resource, then reference it from a `HeroDefinition`. Effects receive only an `AbilityCastContext`; they do not read input, start cooldowns, or own presentation. A projectile is a scene spawned by its effect and performs collision/damage through `ActorStats`. Presentation previews are handled separately by `AbilityTargetingFeedback`.

`StatusEffectController` is intentionally small: it stores timed multipliers keyed by effect id and combines them into movement and attack-cooldown multipliers. New effect data can add slow/bonus modifiers; stun and silence can later be represented with control tags checked by movement and ability validation. Those controls are not implemented now.

## Mobile input and server authority

The desktop adapter maps Q/W/E/R and mouse confirmation to `AbilityController.request_cast()`, `confirm_target()`, `confirm_point()`, and `cancel_targeting()`. A mobile HUD can call those same methods from virtual ability buttons and tap selection, replacing only the input adapter.

For server-authoritative play, send semantic ability id plus target identity or point to the server. The server should re-run caster, target, range, mana, cooldown, and effect validation and own resource changes. Current local execution is not an authority model; networking and replication are not part of this phase.

## Limitations

Target teams are represented only by the `combat_target` group; faction and visibility checks do not exist. Point and area targeting use direct world raycasts, and projectiles travel in a straight line with no homing, collision filtering by team, armor, or damage types. The preview meshes are debug geometry, not polished VFX. Projectiles and cooldowns have no networking or prediction layer.

Run the automated checks with:

```sh
godot --headless --path . --script res://tests/phase3_ability_validation.gd
```
