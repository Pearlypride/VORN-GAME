# VORN architecture

## Current scene

`world/maps/dev_arena.tscn` is the configured main scene. It contains a flat lit arena, independent fixed-pitch MOBA camera rig, a `Player` (`CharacterBody3D`) configured by `VORN_TEST_HERO`, three independent target dummies, desktop input, selection and ability targeting feedback, a single reusable move marker, primitive projectile, and debug HUD. All visuals use Godot primitives and standard materials.

Code is grouped by responsibility:

- `gameplay/actors/`: player movement and hero lifecycle
- `gameplay/stats/`: reusable health, mana, regen, and combat stats
- `gameplay/combat/`: basic attack target/range/cooldown rules
- `gameplay/heroes/`: hero base-stat and ability-list resource
- `gameplay/abilities/`: cast definitions, per-hero runtime cooldowns, effects, and projectile
- `gameplay/status/`: minimal timed stat modifiers, currently used by R
- `input/`: desktop event-to-command adapter
- `ui/hud/`: debug-only state display
- `world/`: camera, selection/targeting presentation, and arena scene

## Actor and combat responsibilities

`ActorStats` owns max/current health and mana, regeneration, movement speed, attack damage, range, and cooldown. It clamps spending/restoring mana, applies damage, and emits health/mana/death signals. It has no UI dependency.

`HeroDefinition` supplies configurable base stats and ability definitions. `PlayerController` applies the hero data during startup; the definition is data rather than runtime state. Dummies each own an independent `ActorStats` node and handle only their own death presentation and respawn. No dummy contains player-specific logic.

`CombatComponent` owns basic attack target validation, range checks, cooldown, and stat-based damage. It rejects dead/invalid targets and stops attacking when either actor dies. Ability damage is applied through `ActorStats.apply_damage()` by separate effect resources; ability code does not read mouse or keyboard events.

`PlayerController` retains the Phase 2 semantic `move_to`, `attack_target`, `stop_command`, and `clear_command` operations. Ground steering and attack pursuit remain separate from desktop mouse picking.

## Ability flow and input

`ArenaInput` maps InputMap actions into player commands and `AbilityController` calls. Q/W/E enter targeting mode; R self-casts immediately. Left-click confirms a target or world point. Right-click or Escape cancels the active targeting mode; if no ability is targeting, Escape clears the current player interaction. This mode does not replace the current move/attack command. See [ABILITIES.md](ABILITIES.md) for cast lifecycle and effect details.

`AbilityController` owns per-hero runtime cooldown state and validates caster life, mana, cooldown, cast type, target validity, and range before spending. `AbilityDefinition` resources carry type, cost, cooldown, range, and an `AbilityEffect` resource. `AbilityCastContext` passes the caster, stats, target/point, and definition to that effect. `AbilityTargetingFeedback` presents range, point, AoE radius, and skillshot line with primitive geometry; presentation does not apply gameplay effects.

The debug HUD reads state and formats it. It does not choose targets, apply damage, or advance cooldowns.

## Timed modifiers and hero life cycle

`StatusEffectController` stores small timed multiplicative modifiers and applies combined movement-speed and attack-cooldown multipliers to `ActorStats`. R uses it for a six-second speed/attack interval bonus. Death clears the modifiers, so no R effect persists through respawn. The API can later add modifier types or control tags for slows, stun, or silence without placing status timers into ability effects.

`HeroLifecycle` listens for hero death, clears commands, basic attack target, ability targeting and modifiers, disables collision and hides the primitive, then respawns after a development delay. Respawn restores health and mana to their configured maxima at the original spawn. Regeneration pauses while dead; ability cooldowns continue ticking during the respawn wait.

## Camera and movement replacement path

The orthographic MOBA camera is independent of the player, has fixed pitch, middle-mouse drag pan, and wheel zoom with exported pan speed and zoom limits. Desktop input controls only the camera rig.

Ground movement uses direct steering in this unobstructed test arena. Obstacle-aware pathfinding is intentionally deferred. `PlayerController.move_to()` is the command boundary; a future movement implementation can replace destination steering with `NavigationAgent3D` path queries without changing semantic commands, targeting, or combat range rules.

## Mobile and server-authority extension

Mobile touch adapters can call the same `PlayerController` methods and `AbilityController.request_cast()` / confirmation methods as desktop input. Touch buttons and screen taps replace the event translation layer; ability effects, validation, movement, and combat remain input-independent.

This project is local-only. A future server-authoritative simulation can receive semantic ability/movement commands and run the same validation/effect rules on the server. Client-side visuals and prediction are not authority. No networking, replication, prediction, or trust protocol is implemented here.

## Not implemented

This phase does not include final hero content, leveling, items, inventory, minions, towers, lanes, jungle, fog of war, wards, multiplayer/networking, backend, matchmaking, MMR, accounts, shop, production UI/art, animation, sound, or monetization. There is no armor or generalized damage-type system. Obstacle navigation remains deferred.
