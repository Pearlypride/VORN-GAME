# Combat timing and basic attacks

## Shared attack lifecycle

Heroes, melee minions, ranged minions, and towers use `BasicAttackController`; targeting/pursuit remains with the hero's `CombatComponent` or lane actor. The controller has four states:

1. `IDLE`: no active swing. It can begin when the interval has elapsed.
2. `WINDUP`: target and range are checked while the attack point timer runs.
3. `RELEASE`: the melee hit is applied or a ranged projectile is created.
4. `RECOVERY`: the backswing completes; the controller becomes idle when recovery and the full attack interval have elapsed.

Attack interval comes from `ActorStats.attack_cooldown`; attack point, recovery, type, and projectile speed are configurable on the hero/minion/tower data or actor. Range remains `ActorStats.attack_range`. Current hero prototype: 25 damage, 2.35 range, 0.78 s interval, 0.24 s attack point, 0.22 s recovery. These are a first tuning pass for deliberate, readable timing, not final balance. Current minion/tower values live in their definitions and lane resources.

## Cancellation and validation

Before release, replacing a hero attack order with Move, Stop, or a different target cancels the windup and resets that pending swing's interval. A target that dies, becomes invalid, hostile checks fail, or moves outside range before release causes the swing to fail safely. Clearing an order after release cannot retract a melee hit that already resolved or a projectile already launched. Launched projectiles resolve independently of the attacker's later orders or death.

Minion retargeting, target death, leaving range, and tower target changes follow the same pre-release cancellation behavior. A dead tower disables its controller, so it cannot release a new attack; already launched tower projectiles can still impact.

## Melee and ranged impact

Melee attacks validate the target again at attack point, then call `CombatActor.receive_damage` immediately. They create no projectile.

Ranged attacks create `BasicAttackProjectile`, separate from ability projectiles. It stores source actor, source team snapshot, target actor, damage, category, and speed. The primitive projectile steers toward the target's current position each physics tick. On impact it checks that the target still exists, is alive, and remains hostile to the source team. If the target dies, leaves the tree, or becomes an ally before impact, the projectile expires without damage. Projectiles are freed on impact, invalid target, or timeout. There is no collision-based interception or projectile dodge behavior.

Damage metadata is `DamageEvent`: source, target, amount, category, and lethal flag. Basic attacks use `BASIC_ATTACK`; abilities use `ABILITY`. `ActorStats` emits one event for each accepted health change. Last-hit rewards use the event that actually reaches zero HP, so a ranged attack may lose the last hit while in flight, and dead units cannot award the same bounty twice.

## Attack speed

`StatusEffectController` exposes attack-speed changes as an attack-cooldown multiplier on `ActorStats`; the basic attack controller does not know about R. At swing start, it snapshots the ratio between effective and base interval. That ratio scales the current swing's attack point and recovery and sets its full interval. An R expiry during a swing does not reshape timing mid-swing; the next swing uses the updated stats. Durations are clamped to valid nonnegative values, and attack point remains shorter than the interval.

## Presentation integration

The controller emits local `attack_started`, `attack_released`, and `attack_finished` signals alongside phase changes. `ActorPresentation` mirrors windup, release, and recovery for primitive motion. The visual strike may later be driven by clips, but release and damage continue to come from this controller; see [PRESENTATION.md](PRESENTATION.md).

## Feedback and limits

Windup, release, and recovery are differentiated by a primitive colored ring on the actor. World-space health bars listen to `ActorStats.health_changed` and hide at zero health. Brief floating numbers listen to `damage_received`. The HUD reports player attack state, attack-point progress, current target, and time until the next attack. These nodes present combat state but do not make gameplay decisions.

The implementation is local and deterministic within the current physics loop. It has no attack animation events, collision-based projectile interception, projectile acceleration, armor/resistance, critical hits, or server authority. Timing configuration should later be driven by server-owned actor stats; presentation can interpolate the replicated attack state without becoming authoritative.
