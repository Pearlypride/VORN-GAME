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

Run the Phase 2 automated checks with:

```sh
godot --headless --path . --script res://tests/phase2_validation.gd
```

## Controls

- **Right-click ground:** move to that point; the temporary marker shows the latest move destination
- **Right-click an enemy:** select it, pursue its current position, and attack automatically in range
- **S:** stop and clear movement and attack pursuit
- **Esc:** clear the selected target and current interaction
- **Middle-mouse drag:** pan the fixed-pitch MOBA camera
- **Mouse wheel:** zoom within configured limits

## Implemented

- Flat lit 3D arena, player and dummy spawn markers, and a top-down/isometric camera
- Ground-click movement and moving-target pursuit driven by semantic commands through an InputMap adapter
- Reusable actor health and combat stat component
- Independent targeting, health, death and respawn for three primitive dummies
- Selection ring, short-lived move marker, and camera pan/zoom
- Debug HUD for player HP, target name/type and HP, command state and attack cooldown

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the current scene and gameplay boundaries.
