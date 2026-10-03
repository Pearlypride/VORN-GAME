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

Run the automated Phase 2, Phase 3, and Phase 4 checks with:

```sh
godot --headless --path . --script res://tests/phase2_validation.gd
godot --headless --path . --script res://tests/phase3_ability_validation.gd
godot --headless --path . --script res://tests/phase4_lane_validation.gd
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
- Debug HUD for HP/mana, gold, level/XP, waves, tower HP, target, command state, Q/W/E/R states, targeting mode and R buff timer

Movement and combat currently use direct steering/basic range checks in this simple lane. Obstacle-aware navigation and tower hero-aggro are intentionally deferred. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md), [docs/ABILITIES.md](docs/ABILITIES.md), and [docs/LANE_SYSTEM.md](docs/LANE_SYSTEM.md) for system details and simplifications.
