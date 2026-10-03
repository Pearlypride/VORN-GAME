# VORN visual direction — Phase 7 slice

## Identity

VORN's first visual slice uses an ash-forged, mythic-industrial language: dark mineral ground, cut stone lane paving, weathered silhouettes, restrained ember light, and cool team signals. It should feel tactical and weighty. Composition favors clear unit silhouettes and high-contrast combat cues over decoration density. This is an original prototype direction, not a replication of an existing MOBA's characters, map, or interface.

## KARN

KARN is a front-line melee bruiser: a duelist who advances through pressure and wins close exchanges. Internal lore: a former breach-keeper of a vanished border citadel, carrying its broken gate as a cleaver. The primitive model has a broad chest, asymmetric pauldron, hard crest/visor, dark iron body, ember plates, and a heavy forward weapon. His kit names are **Rend**, **Breakline**, **War Ring**, and **Redline**. Existing ability effects/numbers remain prototype tuning.

## Hero identity and team identity

KARN's identity uses charcoal, steel, and ember. Team identity is carried separately through blue/red health bars and objective markers, lane-side materials, tower trim, minimap marks, and selection feedback. Do not recolor KARN's whole silhouette to make him read as Team A; future heroes should be able to keep their own palette.

## Environment language

The one-lane slice uses a subdued mineral/green-black terrain base, lighter gray lane paving with low stone curbs, sparse side ridges and boulders, a paired center landmark, and blue/ember crystal clusters near team territory. These are collision-free primitives around a simple walkable lane. Future environmental changes must preserve navigation/readability before decoration. No jungle, river, or extra routes are implied.

## HUD layout

Normal view: compact vector lane map upper left; match clock/0–0 score top center; settings/debug affordance top right; selected-target card below the clock; decorative movement pad lower left; KARN portrait/vitals/level/gold bottom center; Q/W/E/R and attack affordances bottom right. The old telemetry panel is hidden unless F3 is pressed. Layout uses anchors so wide and standard 16:9 viewports share one scene layout. The fixed camera opens around the Team A approach with ~54° pitch, orthographic size 20, pan speed 0.038, and zoom limits 18–30. Controls are visual placeholders; desktop keyboard/mouse remains the only gameplay input.

## VFX and feedback rules

- Rend: single fast ember slash/impact cue.
- Breakline: elongated, warm projectile with a short trail.
- War Ring: one expanding ground ring.
- Redline: restrained aura ring on KARN while the gameplay buff remains active.
- Basic ranged attacks: source-colored streak, brief impact ring, existing stat-driven damage response.
- Damage numbers stay selective to KARN and towers to reduce minion-fight clutter.

Effects listen to successful gameplay events and never alter damage, targeting, or timing. Prefer a few short-lived meshes and shared materials; no expensive shader outlines, particle storms, blur, or screen shake.

## Placeholder and mobile limits

All characters, structures, landmarks, and most VFX are Godot primitives, not production art. The map is flat, direct-steered, and collision-free outside its lane floor. The minimap is a vector projection of current lane actors, not screenshot art; it can later project a real map model. HUD controls do not implement touch. Avoid adding unique materials/nodes per frame; keep presentation updates throttled and temporary effects self-cleaning.
