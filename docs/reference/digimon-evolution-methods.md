# Digimon evolution rules

Growth stage and evolution method are independent. The app uses 475 Time Stranger
species with explicit application overrides. These are game rules for this fan
app, not an exhaustive account of every Digimon title.

## Ordinary evolution

Choose a direct candidate or fill the gauge to evolve automatically. Automatic
choice favors uncollected ordinary candidates. Registered direct forms can be
revisited immediately. A training path cannot revisit the same species.
Final training forms require a full final gauge before a new egg or parked partner
is returned. Special conditions never silently become ordinary token growth.

## Special evolution

The Home alert lists every ready, uncollected result, independently of the active
partner. Eligibility is checked again when starting the scene. Completion adds
the result to the Notebook without replacing the active or parked companion.

- **Fusion:** all listed ingredients must be collected; ingredients are retained.
  A Digimon used as a weapon/power source counts as a fusion ingredient.
- **Item evolution:** collect the listed source and own the designated item.
  The item is consumed once when evolution is committed. Dedicated capsules map
  to specific Armor results; X-Antibody A/S and Digivice cover their explicit rules.
- **Daily-token evolution:** collect the source and reach the displayed actual
  daily-token requirement. Bond evolution requires 30M; configured release/Burst
  and other daily-gated routes require 60M. Actual providers are combined. Growth
  items and difficulty multipliers do not count toward these thresholds.

Fusion keeps the combination sequence. Other reveal scenes start at the shadow,
with slow flashes, binary belts and lasting light. Home is the completion control.
Cancelling before Start consumes nothing; closing after commit retains the result.
Replaying or duplicate requests cannot consume an item twice.

## Selected examples

| Result | Collection / item requirement |
| --- | --- |
| Paildramon / Dinobeemon | ExVeemon + Stingmon |
| Omnimon | WarGreymon + MetalGarurumon |
| Imperialdramon Paladin Mode | Imperialdramon Fighter Mode + Omnimon |
| Alphamon Ouryuken | Alphamon + Ouryumon |
| Flamedramon | Veemon + dedicated Courage capsule |
| Magnamon | Veemon + dedicated Miracles capsule |

The explicit rules and supporting references are in
[`evolution-rules.json`](../../Sources/PokeTokenBar/Resources/Digimon/evolution-rules.json).
Unverified routes are not presented as confirmed lore. Armageddemon uses ordinary
growth by application policy. See [continuation](digimon-continue-training.md) for
special results that still have uncollected ordinary descendants.
