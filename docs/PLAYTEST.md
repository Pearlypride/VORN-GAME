# First graphical playtest checklist

Run the arena in a normal Godot window. This checklist measures feel and visual readability; headless tests cannot judge either. Record build/commit, display resolution, frame rate impression, and notes. Repeat the lane and combat observations at default zoom and one zoom step out.

## Movement

- [ ] Right-click ground near and far from the hero; note click accuracy and marker visibility.
- [ ] Issue a second destination while moving; confirm the hero redirects immediately and only the latest marker remains.
- [ ] Press **S** while moving; confirm immediate stop.
- [ ] Middle-drag camera without moving the hero; verify fixed pitch and comfortable pan speed.
- [ ] Wheel zoom to both limits; confirm it clamps and the lane/towers remain readable.

## Attack

- [ ] Order an attack outside range; assess pursuit response and facing.
- [ ] Observe windup; replace the order with Move or Stop before release and confirm cancellation.
- [ ] Observe release and recovery at close range; note whether the hit feels aligned with the visible strike.
- [ ] At ranged attack distance, compare hero/minion/tower projectile silhouettes, travel speed, and impact readability.
- [ ] Move the target during pursuit; confirm the hero follows its current position.

## Lane

- [ ] Observe wave cadence and spacing; check melee/ranged silhouettes are clear at normal zoom.
- [ ] Watch minion collisions, target changes, and combat; record any visual crowding.
- [ ] Attempt last hits across several waves; record easy/missed/unclear hits and whether projectile travel changes timing.
- [ ] Confirm XP gain for nearby living hero and observe the level-up ring/text.

## Abilities

- [ ] Q: check range ring, target hover ring, valid/invalid colors, and target confirmation.
- [ ] W: check direction/max-distance guide, cancel, then fire and follow projectile readability.
- [ ] E: check point marker and AoE radius, including at cast-range edge.
- [ ] R: assess attack-speed and movement-speed change, then expiry/reset.

## Tower

- [ ] Identify tower range from actual behavior and the visible lane context.
- [ ] Check minion-first targeting and hero aggro after attacking a hero under tower range.
- [ ] Assess upper-emitter windup/release, projectile speed, and how threatening tower damage feels.

## Visual and notes

- [ ] Compare Team A/Team B readability and hero silhouette against minions/tower.
- [ ] Check HP bar scale/placement/contrast, dead-unit hiding, floating damage, and death/respawn clarity.
- [ ] Confirm selection ring clears with Escape and move marker expires/replaces cleanly.
- [ ] Note HUD grouping, legibility, and whether combat/cooldown state is understandable during motion.

### Observation record

For each issue include: **area / reproduction / expected / observed / severity (1–5) / proposed tuning change**. Keep balance suggestions separate from bugs. Prototype values are not final balance targets.


## Phase 7 vertical-slice review

- [ ] Start with the normal HUD only; use F3 to show and hide developer values.
- [ ] Review the minimap, score/time row, selected-target card, bottom vitals, decorative movement control, and ability row at each requested aspect ratio.
- [ ] Confirm KARN is the visually dominant unit; compare his cleaver silhouette with compact melee/ranged minions.
- [ ] Check tower platform/emitter scale, team ownership accents, center landmark, ridge/rock framing, and crystal clusters.
- [ ] Cast Rend, Breakline, War Ring, and Redline; check each cue stays visible at play distance and does not obscure the lane.
- [ ] Watch minion fights for projectile/hit-feedback spam. Confirm hero bars, level marker, selection, and target panel remain readable.
- [ ] At 1920×1080, 1600×900, 1280×720, and 2340×1080, confirm HUD regions stay anchored, no control covers the hero, and ability buttons fit on screen.

Record screenshots and short clips from default zoom plus one zoom step out. Mark any overlap or illegible labels with the viewport size and scene state.
