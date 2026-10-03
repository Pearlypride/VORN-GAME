# VORN architecture

## Current scene

`world/maps/dev_arena.tscn` is the configured main scene. It contains a fixed-pitch MOBA camera, `VORN_TEST_HERO`, a one-lane `LaneWorld`, two towers, two wave spawners, three legacy development dummies, desktop input, primitive feedback, and a debug HUD. All visuals use primitives and standard materials.

Code is grouped by responsibility:

- `gameplay/actors/`: player movement and hero lifecycle
- `gameplay/stats/`: reusable health, mana, regen, and combat stats
- `gameplay/combat/`: attack intent validation, shared timing controller, damage metadata, and ranged basic-attack projectile
- `gameplay/lane/`: lane path, minion definitions/AI, wave spawners, tower behavior, and lane setup
- `gameplay/economy/` and `gameplay/progression/`: last-hit wallet and proximity XP/levels
- `gameplay/heroes/`: hero base-stat and ability-list resource
- `gameplay/abilities/`: cast definitions, per-hero runtime cooldowns, effects, and projectile
- `gameplay/status/`: minimal timed stat modifiers, currently used by R
- `input/`: desktop event-to-command adapter
- `ui/hud/`: debug-only state display
- `world/`: camera, selection/targeting presentation, and arena scene

## Actor and combat responsibilities

`ActorStats` owns max/current health and mana, regeneration, movement speed, attack damage, range, and cooldown. It clamps spending/restoring mana, applies damage, and emits health/mana/death signals. It has no UI dependency.

`HeroDefinition` supplies configurable base stats and ability definitions. `PlayerController` applies the hero data during startup; the definition is data rather than runtime state. Dummies each own an independent `ActorStats` node and handle only their own death presentation and respawn. No dummy contains player-specific logic.

`CombatComponent` owns the hero's selected attack target, validates hostility and life, and delegates in-range attack intent to `BasicAttackController`. The shared controller owns IDLE/WINDUP/RELEASE/RECOVERY timing for heroes, minions, and towers. It applies melee damage at RELEASE or spawns a ranged projectile. The controller and damage resolution do not read desktop input. Ability damage is applied through `ActorStats.apply_damage()` by separate effect resources.

`CombatActor` composes team identity, actor kind, alive state, hostility checks, and damage receipt onto a unit without requiring a shared gameplay inheritance tree. `TeamRules` is the central hostility policy. `LaneCombatRoster` caches registered combat actors and answers bounded-radius queries for minion/tower AI and area effects. Each accepted health change creates a `DamageEvent` with source, target, amount, category, and lethal flag. Minion death uses the final impact source for gold; only a hero basic-attack impact triggers hero aggro.

`PlayerController` retains the semantic `move_to`, `attack_target`, `stop_command`, and `clear_command` operations. Desktop input turns mouse/keyboard actions into those commands; movement and attack pursuit remain separate from mouse picking. Touch adapters can emit the same commands.

## Ability flow and input

`ArenaInput` maps InputMap actions into player commands and `AbilityController` calls. Q/W/E enter targeting mode; R self-casts immediately. Left-click confirms a target or world point. Right-click or Escape cancels the active targeting mode; if no ability is targeting, Escape clears the current player interaction. This mode does not replace the current move/attack command. See [ABILITIES.md](ABILITIES.md) for cast lifecycle and effect details.

`AbilityController` owns per-hero runtime cooldown state and validates caster life, mana, cooldown, cast type, target validity, and range before spending. `AbilityDefinition` resources carry type, cost, cooldown, range, and an `AbilityEffect` resource. `AbilityCastContext` passes the caster, stats, target/point, and definition to that effect. `AbilityTargetingFeedback` presents range, point, AoE radius, and skillshot line with primitive geometry; presentation does not apply gameplay effects.

The debug HUD reads state and formats it. It does not choose targets, apply damage, or advance attack timing. `ActorReadability` listens to `ActorStats` events and owns only world-space bars and short-lived damage numbers.

## Timed modifiers and hero life cycle

`StatusEffectController` stores small timed multiplicative modifiers and applies combined movement-speed and attack-cooldown multipliers to `ActorStats`. R uses it for a six-second speed/attack interval bonus. Death clears the modifiers, so no R effect persists through respawn. The API can later add modifier types or control tags for slows, stun, or silence without placing status timers into ability effects.

`HeroLifecycle` listens for hero death, clears commands, basic attack target, ability targeting and modifiers, disables collision and hides the primitive, then respawns after a development delay. Respawn restores health and mana to their configured maxima at the original spawn. Regeneration pauses while dead; ability cooldowns continue ticking during the respawn wait.

## Lane systems

`LaneWorld` lays out one straight lane, constructs the shared roster/path, and owns one synchronized spawner and one tower per team. `LanePath` is a deterministic coordinate path; minions store progress from their home side. It can be replaced with a curve or navigation query behind the lane path API. Minions use cached roster queries on a timer, choose nearest targets by minion → hero → tower priority, and return to advance when combat ends. Hero basic attacks can briefly redirect nearby hostile minions; ability aggro is not implemented.

The player receives gold only when it is the final damage source on impact for a hostile minion. XP is granted to living hostile heroes inside the minion's configured XP radius, regardless of last hit. Levels 1–6 use a linear configurable threshold. Level growth adds configured maxima and damage while preserving absolute current HP/mana, capped by the new maxima. Towers are stationary, target minions before heroes, and temporarily prioritize an enemy hero that damages a friendly hero inside tower range. See [LANE_SYSTEM.md](LANE_SYSTEM.md) and [COMBAT_TIMING.md](COMBAT_TIMING.md) for the lane and impact rules.

## Camera and movement replacement path

The orthographic MOBA camera is independent of the player, has fixed pitch, middle-mouse drag pan, and wheel zoom with exported pan speed and zoom limits. Desktop input controls only the camera rig.

Hero ground movement and minion lane advance use direct steering. Obstacle-aware pathfinding is intentionally deferred. Hero move commands remain behind `PlayerController.move_to()`, and minion location progression is behind `LanePath`; a `NavigationAgent3D` or curve-backed path layer can replace these movement calculations without changing command, combat, or reward rules. Keep the destination interface stable and swap only the steering/path implementation.

## Mobile and server-authority extension

Mobile touch adapters can call the same `PlayerController` methods and `AbilityController.request_cast()` / confirmation methods as desktop input. Touch buttons and screen taps replace the event translation layer; ability effects, validation, movement, attack timing, and damage remain input-independent.

This project is local-only. A future server-authoritative simulation can receive semantic ability/movement commands and run the same validation/effect rules on the server. Client-side visuals and prediction are not authority. No networking, replication, prediction, or trust protocol is implemented here.

## Not implemented

This prototype has one lane only. It does not include neutral jungle units, extra lanes, base structures, tower hero-aggro, tower armor, ability aggro, shop/items, fog of war, networking, production UI/art, animations, sound, or monetization. There is no generalized damage type or server authority yet. Scaling beyond small development waves needs profiling and possibly a spatial index; the current roster scans its cached actor list for bounded-radius queries.
