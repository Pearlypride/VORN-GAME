# Phase 4 lane system

This describes VORN's single-lane development prototype. Rules and timings are test values, not final competitive balance.

## Teams and combat actors

`TeamRules` defines `NEUTRAL`, `TEAM_A`, and `TEAM_B`; only different non-neutral teams are hostile. Heroes, dummies, minions, and towers compose `CombatActor` for team, kind, alive state, hostility, and damage receipt. `ActorStats` owns health and combat stats. `LaneCombatRoster` caches actors and answers bounded-radius queries, so AI does not walk the scene tree every frame.

## Lane path and minion FSM

`LaneWorld` creates one straight lane, one tower per side, and one spawner per team. `LanePath` maps scalar home-to-enemy progress to a world position. It can later be replaced by a `Path3D`, waypoints, or a navigation query without changing combat or wave code. Hero destination steering is also intentionally direct; obstacle-aware navigation is deferred.

Each wave defaults to three melee minions and one ranged minion. Definitions configure health, speed, damage, range, attack interval, attack point, recovery, projectile speed, bounty, XP, and tint. Minions transition among `ADVANCE`, `COMBAT`, and `DEAD`. They advance on the lane, periodically query the cached roster, pursue a selected target into range, run the shared attack controller, reacquire after target death, and resume advancing when combat ends. Ranged minions' longer range naturally keeps them farther from targets than melee minions. Dead minions stop and are removed after a short delay.

Selection priority is nearest hostile minion, then hero, then tower. Temporary hero basic-attack aggro overrides that order. Ties resolve by distance. Changed targets cancel only attacks still in windup; a released attack resolves independently. There is no sophisticated focus logic or lane blocker rule.

## Waves and aggro

Each side has a `WaveSpawner` with synchronized defaults: two seconds to the first wave, then eighteen-second intervals. Spawn composition and cadence are separate from minion AI.

When a hero basic attack targets an enemy hero, nearby hostile minions receive a short aggro override. Abilities do not trigger this behavior. Towers target the nearest hostile minion in range before a hero. An enemy hero that basic-attacks a friendly hero inside tower range can temporarily override the tower's normal target.

## Basic attacks and rewards

Heroes, melee/ranged minions, and towers share `BasicAttackController`: `IDLE → WINDUP → RELEASE → RECOVERY`. Melee attacks validate the target again at release and apply damage then. Ranged attacks launch tracking primitive projectiles at release; impact applies damage only if the target is still alive and hostile. Dead or removed targets make the projectile expire without damage. Projectiles carry a snapshot of source team, damage, and category so released shots remain safe after their source dies.

Each accepted health change creates `DamageEvent` metadata (source, target, amount, category, lethal flag). Basic attacks use `BASIC_ATTACK`; ability effects use `ABILITY`. Last-hit gold is awarded from the final applied damage event at impact. Damage against a dead minion is ignored, so bounty cannot be awarded twice. XP goes to living hostile heroes within the minion's configured radius regardless of last hit. Wallet and progression are separate components. Heroes start at level one and can reach six; growth increases configured maxima and damage while preserving current absolute resources.

## Towers

Towers are stationary ranged attackers with configurable interval, attack point, recovery, range, and projectile speed. They use the shared attack controller and tracking projectile, maintain minion-first targeting and brief hero aggro, and stop launching attacks when destroyed. Projectiles released before tower destruction continue to their hostile target. There is no armor, backdoor protection, regeneration, fortification, glyph, or base exposure rule.

## Feedback and validation

The debug HUD shows attack phase, windup progress, current attack target, time until next attack, target HP, command state, economy, levels, wave count, and tower HP. Heroes, minions, and towers have simple world-space health bars; accepted damage briefly floats a number above the unit. Presentation listens to stats and does not resolve combat.

Run validation suites from the project root:

```sh
godot --headless --path . --script res://tests/phase2_validation.gd
godot --headless --path . --script res://tests/phase3_ability_validation.gd
godot --headless --path . --script res://tests/phase4_lane_validation.gd
godot --headless --path . --script res://tests/phase5_combat_validation.gd
```

The test harnesses create units deterministically. Graphical checks remain necessary for attack responsiveness, cancellation feel, minion spacing, projectile speed/readability, last-hit feel, HP bars, and R buff feel.

## Simplifications and future authority

This prototype has one straight lane, direct steering, primitive visuals, no attack animations, and no obstacle-aware navigation. The projectile directly tracks a target without collision geometry; navigation can later replace destination steering behind `PlayerController.move_to()` / the lane path interface without rewriting command or combat logic. Ranged target seeking uses periodic roster queries rather than per-frame full-scene scans. Larger populations may call for profiling and a spatial hash.

Input adapters, minion AI, attack timing, damage, reward, and tower state are separate. A mobile adapter can issue the same semantic movement/attack and ability commands; a server can later own timing and damage resolution. Networking, prediction, replication, and authority enforcement are not implemented.
