# VORN foundation architecture

## Current scene structure

`world/maps/dev_arena.tscn` is the configured main scene. It contains a lit flat floor, an independent fixed-pitch MOBA camera rig, spawn markers, a `Player` (`CharacterBody3D`), three independent dummy actors (`StaticBody3D`), desktop input and selection-feedback adapters, a single reusable move marker and a minimal `HUD`. The arena and actor visuals use built-in primitive meshes and shapes only.

Scripts are arranged by responsibility:

- `gameplay/actors/`: player movement and dummy lifecycle
- `gameplay/stats/`: actor health and the small set of current combat stats
- `gameplay/combat/`: target state, attack range checks and cooldown timing
- `input/`: desktop keyboard/mouse adapter
- `ui/hud/`: debug-only status display
- `world/`: camera controls, selection presentation and development arena

## Gameplay responsibilities

`ActorStats` owns max/current health, movement speed, attack damage, attack range and attack cooldown. It applies damage and emits health/death signals; it does not know about meshes, input or arena presentation.

`CombatComponent` tracks a selected target and checks flat ground distance, attack cooldown and target health before applying an attack through the target's `ActorStats`. A dead, freed or invalid target clears the attack command immediately. On death it drops the target; a later dummy respawn therefore does not restart the attack without a new command. It has no projectile, armor or damage-type rules. Each `DummyTarget` responds only to its own stats' death signal by hiding its visual and disabling its collision, then restores health and re-enables collision after its own delay.

`PlayerController` exposes semantic `move_to`, `attack_target`, `stop_command` and `clear_command` methods and tracks `IDLE`, `MOVE`, `ATTACK` and `STOP` command states. A new command replaces the previous one immediately. Ground orders steer directly toward their destination; attack orders continuously steer toward the target's latest position and stop within attack range. `CombatComponent` applies attacks only when range and cooldown permit. The HUD reads state and presents it; it does not determine combat outcomes.

## Input architecture

`ArenaInput` translates `issue_command` (right mouse button), `stop_command` (S) and `clear_command` (Escape) InputMap actions into player orders. Right-clicking a combat target issues an attack order; right-clicking ground issues a move order. The input adapter owns mouse picking; combat and movement code do not read mouse buttons. A separate `SelectionFeedback` view listens to target changes to show or hide the selected actor's primitive ring. The input adapter reuses one timed move marker, so repeated commands replace the marker rather than accumulating nodes.

The debug HUD shows player HP, selected target name/type and HP, the current command state and attack cooldown. `ActorStats` has no UI dependency, and dummy actors contain no player-specific logic.

## Camera and movement path

The MOBA camera is on its own rig and never follows or moves the player. Its pitch is fixed. Middle-mouse drag pans across the ground plane; wheel zoom changes orthographic size within exported minimum and maximum values. Pan speed, zoom step and zoom bounds are configurable on `MobaCamera`.

Ground movement currently uses direct steering toward a destination and assumes the simple arena has no blocking obstacles. Full obstacle-aware pathfinding is intentionally deferred. `PlayerController.move_to()` is the command boundary; a future movement layer can replace its destination-steering calculation with a `NavigationAgent3D` path query while preserving move/attack/stop commands and combat range rules.

For mobile, a touch camera adapter can pan/zoom the same camera rig, while a tap/joystick adapter can emit the same semantic player commands. The gameplay movement and combat systems do not need to be rewritten around touch events.

## Authority and future multiplayer

This sandbox is local-only. Keeping movement intent, actor stats and combat rules behind component APIs gives a future server simulation a place to receive validated player commands and apply state changes. In an authoritative design, the server would own movement validation, attack timing, target/range validation, health and respawn; clients would send intent and render replicated results. No networking protocol, prediction, replication or trust boundary is implemented here, and current local execution must not be treated as a final authority model.

## Intentionally not implemented

Networking, server authority, bots, minions, towers, items, abilities, hero selection, accounts, matchmaking, MMR, mobile virtual controls, production UI and production art are outside this phase. There is no projectile simulation, armor formula, complex damage type, animation or sound system. Obstacle-aware navigation remains intentionally deferred.
