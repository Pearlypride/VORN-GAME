# Phase 4 lane system

This document describes the current single-lane development prototype. Its rules are deliberately small and deterministic; they are not final competitive balance.

## Teams and combat actors

`TeamRules` defines `NEUTRAL`, `TEAM_A`, and `TEAM_B`. Only different non-neutral teams are hostile. Heroes, dummies, minions, and towers compose a `CombatActor` node exposing team, kind, alive state, position, hostility, and damage receipt. `ActorStats` remains the health/stat component and accepts damage source plus category metadata. `LaneCombatRoster` caches registered identities and supplies bounded-radius queries; AI does not traverse the whole scene tree every frame.

## Lane path and map

`LaneWorld` creates one straight lane between the Team A and Team B sides, a tower per side, and one spawner per team. `LanePath` maps distance from home to a world position and supplies each team's direction. Minions store scalar progress along this path. This path contract can later use a `Path3D`, waypoint list, or navigation layer without changing combat or wave code. Hero movement still uses Phase 2 direct destination steering.

## Minion lifecycle and targeting

Each wave contains configurable counts, defaulting to three melee and one ranged minion. Definitions are resources with health, speed, damage, range, cooldown, bounty, XP reward, and tint. Melee minions have more health and short range; ranged minions have less health and longer range. Each minion transitions among `ADVANCE`, `COMBAT`, and `DEAD`. It advances, scans the cached roster on a timer, fights a valid target, reacquires after target death, then resumes advancing. Dead units stop and are removed after a short delay.

Target selection is deterministic: nearest hostile minion first, then nearest hostile hero, then nearest hostile tower; an active hero-attack aggro override takes precedence for its short duration. Ties within a priority resolve by distance. Minions reacquire on their scan interval, so a higher-priority nearby unit can replace a previous target. When aggro expires, normal priorities apply again. This simple priority does not model lane blockers, attack windup, projectile travel, or sophisticated focus rules.

## Wave spawning

Each team has one `WaveSpawner` configured with the same initial delay and interval, so wave numbers stay synchronized. Defaults are a two-second first wave and eighteen-second interval for rapid testing. Spawners own composition and cadence only; minion AI owns combat. Wave spacing is configurable. No siege or super minions exist.

## Aggro

When the hero's basic attack damages an enemy hero, the roster checks nearby enemy minions. Minions within the configured radius prefer the attacking hero for a limited duration. Minions then resume their normal deterministic target choice. Ability damage does not trigger this rule.

Towers select the nearest hostile minion in range, falling back to the nearest hostile hero if no hostile minion is available. If an enemy hero basic-attacks a friendly hero while inside tower range, the tower temporarily prioritizes that attacker. This is a short local override; there is no projectile or multi-tower aggro coordination.

## Damage attribution and rewards

`ActorStats.apply_damage(amount, source, category)` records the most recent damaging actor and category. On hostile minion death, the player receives its bounty only if the last source is the player hero. No passive gold is awarded. A living hostile hero inside the minion's XP radius receives XP regardless of last hit; dead heroes and allied heroes receive none. Wallet and progression state are separate components.

The player starts at level 1 and can reach level 6. XP required is `base_xp_to_level + (level - 1) * xp_step_per_level`. XP spills over after a level. Hero definitions configure per-level health, mana, damage, and optional regeneration growth. Growth increases maximum stats and preserves current absolute HP/mana, capped at the new maximum; leveling does not heal the hero.

## Towers

Each stationary tower has team, health, damage, range, and cooldown. It acquires the nearest hostile minion in range, attacks through the common combat identity/stats API, and stops when destroyed. Dead towers are invalid combat targets and have collision disabled. Heroes, abilities, and minions may damage towers through the same damage API. No armor, backdoor protection, regeneration, fortification, glyph, or base exposure rules exist.

## HUD and validation

The debug HUD shows gold, level/current/required XP, wave counts, and both tower health values in addition to the Phase 3 hero/ability status. Run all validations with:

```sh
godot --headless --path . --script res://tests/phase2_validation.gd
godot --headless --path . --script res://tests/phase3_ability_validation.gd
godot --headless --path . --script res://tests/phase4_lane_validation.gd
```

The automated Phase 4 setup creates waves and units deterministically rather than waiting for a complete live lane match.

## Known simplifications and future authority

There is one straight lane, direct steering, instant basic attacks, primitive unit visuals, no animations, no ranged-minion projectile, and no tower hero-aggro. The roster performs a bounded-distance pass over cached actors; this avoids scene-tree searches and per-frame scans, but very large populations may need a spatial hash or physics-area query. Wave sizes remain small for mobile-oriented development.

Wave spawning, minion state, combat resolution, damage source, gold, XP, levels, and tower state are independent of desktop input and presentation. Those systems are candidates for server ownership later. Networking, replication, prediction, and authority enforcement are not implemented.
