# VORN

VORN is a Godot 4.7 GDScript project. The current project is a small 3D combat sandbox built with primitive geometry and the Mobile renderer.

## Launch

Open this folder in Godot 4.7.2 and run the project (F6 is not needed; the development arena is the configured main scene). From a terminal:

```sh
godot --path .
```

For a headless project parse/import check:

```sh
godot --headless --path . --editor --quit
```

Run the automated Phase 2–6 checks with:

```sh
godot --headless --path . --script res://tests/phase2_validation.gd
godot --headless --path . --script res://tests/phase3_ability_validation.gd
godot --headless --path . --script res://tests/phase4_lane_validation.gd
godot --headless --path . --script res://tests/phase5_combat_validation.gd
godot --headless --path . --script res://tests/phase6_presentation_validation.gd
```

## Controls

- **Right-click ground:** move to that point; the temporary marker shows the latest move destination
- **Right-click an enemy:** select it, pursue its current position, and attack automatically in range
- **Right-click a hostile minion or tower:** issue the same basic attack command
- **S:** stop and clear movement and attack pursuit
- **Esc:** clear the selected target and current interaction
- **Middle-mouse drag:** pan the fixed-pitch MOBA camera
- **Mouse wheel:** zoom within configured limits
- **Q:** enter targeted-strike mode; left-click an enemy to cast
- **W:** enter projectile aim mode; left-click a point to fire
- **E:** enter area targeting; left-click a ground point to cast
- **R:** cast Overdrive on self immediately
- **Right-click or Esc while targeting Q/W/E:** cancel targeting mode

## Implemented

- Flat lit 3D arena, player and dummy spawn markers, and a top-down/isometric camera
- Ground-click movement and moving-target pursuit driven by semantic commands through an InputMap adapter
- Reusable actor health and combat stat component
- Independent targeting, health, death and respawn for three primitive dummies
- Selection ring, short-lived move marker, and camera pan/zoom
- `VORN_TEST_HERO` data resource, health/mana stats and regeneration
- Q targeted damage, W first-hit projectile, E area damage, and R temporary movement/attack-speed buff
- Development hero death and full-resource respawn loop
- One straight lane with Team A/Team B sides, one tower per team, and synchronized repeating 3-melee/1-ranged minion waves
- Minion advance/combat/death behavior, team-filtered target priorities, brief hero basic-attack aggro, and tower minion-first fire
- Last-hit gold, proximity XP, levels 1–6, and configurable hero per-level stat growth
- Shared IDLE/WINDUP/RELEASE/RECOVERY basic-attack lifecycle for the hero, melee/ranged minions, and towers
- Tracking primitive projectiles for ranged hero attacks, ranged minions, and towers; damage and last-hit credit resolve on impact
- World-space health bars and brief floating damage numbers for readable combat feedback
- Primitive hero/minion/tower presentation, semantic presentation states, hit/death/respawn/level feedback, and grouped development HUD with local playtest telemetry

Movement uses direct steering/basic range checks in this simple lane. Obstacle-aware navigation is intentionally deferred. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md), [docs/ABILITIES.md](docs/ABILITIES.md), [docs/LANE_SYSTEM.md](docs/LANE_SYSTEM.md), [docs/COMBAT_TIMING.md](docs/COMBAT_TIMING.md), [docs/PRESENTATION.md](docs/PRESENTATION.md), and [docs/PLAYTEST.md](docs/PLAYTEST.md) for system details, presentation contracts, and the graphical playtest checklist.
