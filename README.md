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

Run the automated Phase 2 and Phase 3 checks with:

```sh
godot --headless --path . --script res://tests/phase2_validation.gd
godot --headless --path . --script res://tests/phase3_ability_validation.gd
```

## Controls

- **Right-click ground:** move to that point; the temporary marker shows the latest move destination
- **Right-click an enemy:** select it, pursue its current position, and attack automatically in range
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
- Debug HUD for HP/mana, target, command state, Q/W/E/R states, targeting mode and R buff timer

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) and [docs/ABILITIES.md](docs/ABILITIES.md) for architecture and ability lifecycle details.
