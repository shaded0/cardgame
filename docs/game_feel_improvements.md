# Game Feel Improvements - Actionable Roadmap

## Purpose

Concrete, implementable changes to make The Ember Sanctum *feel* better
moment-to-moment. Organized by impact and effort. Each item references
the specific files that need to change.

---

## Quick Wins (High Impact, Low Effort)

### 1. Enemy Death Burst

**Problem:** Enemies vanish on death. No payoff for the kill.

**Fix:** On enemy death, spawn a burst effect at their position:
- 8-12 directional particles in the enemy's color palette
- Brief scale-up (1.2x over 0.05s) then fade (0.2s)
- Small screen shake (4.0 intensity, 0.08s)
- Spawn 1-3 small "orb" pickups that drift toward player (gold/mana/xp)

**Files:** `scripts/enemies/base_enemy.gd` (death handler),
`scripts/combat/screen_fx.gd` (new `enemy_death_burst` static method)

**Why it matters:** Every enemy kill becomes a micro-reward. The particle
burst provides the "crunch" that currently only exists on player attacks.
The drifting orbs create a secondary pleasure (collection = dopamine).

---

### 2. Enemy Remaining Counter

**Problem:** Player can't anticipate room clear. The transition from
"fighting" to "ROOM CLEARED" is abrupt.

**Fix:** Add a subtle enemy counter to the HUD: `Foes: 7` that ticks
down with each kill. When it hits 1, pulse the counter. When it hits 0,
brief pause (0.2s freeze) then the clear label.

**Files:** `scripts/ui/hud.gd` (new label),
`scripts/levels/arena_base.gd` (emit enemy_killed signal),
`scripts/managers/game_manager.gd` (track enemy count)

**Why it matters:** Anticipation is the phase where dopamine is actually
*produced* (before the reward). Watching the counter approach zero builds
anticipation. The final kill becomes a climax, not a surprise.

---

### 3. Card Draw Animation

**Problem:** Cards appear instantly in hand slots. No draw moment.

**Fix:** When hand refreshes (room start, cycle, reshuffle):
- Cards slide up from below the hand area (y+40 -> y+0, 0.15s)
- Stagger each card by 0.05s
- Brief scale bounce on arrival (1.1x -> 1.0x, back ease)
- Subtle "whoosh" placeholder (visual swoosh trail) until audio exists

**Files:** `scripts/ui/card_slot_ui.gd` or `scripts/cards/card_manager.gd`
(wherever hand display updates)

**Why it matters:** Card games live and die on the "draw moment." In Slay
the Spire, the card draw animation is one of the most satisfying micro-
interactions. It creates a beat of anticipation before the player reads
what they got.

---

### 4. Dodge Afterimage

**Problem:** Dodge has invincibility frames and speed boost but no visual
flair. Player can't "see" the dodge working.

**Fix:** During dodge, spawn 3-4 afterimages at 0.08s intervals:
- Copy of player sprite at 50% opacity
- Tinted toward class color
- Fade out over 0.2s
- Slight scale-down (0.95x)

**Files:** `scripts/player/player.gd` (dodge state),
new method in player or ScreenFX

**Why it matters:** The dodge is a skill expression. Making it look cool
rewards the player for using it well. Afterimages are the universal
"I'm fast" signal in action games.

---

### 5. Hit Damage Number Variety

**Problem:** All damage numbers are white. No visual distinction between
damage types or amounts.

**Fix:**
- Normal damage: white (current)
- Critical/high damage (>150% of base): larger font, orange, with "!"
- Weak hits (<50% of base): smaller font, grey
- Healing: green with "+" prefix (already exists)
- Shield: blue (already exists)
- Debuff damage (vulnerable target): red with emphasis shake
- Multi-hit: numbers stack slightly, ascending position

**Files:** `scripts/combat/damage_number.gd`

**Why it matters:** Varied damage numbers create a richer visual language.
Players learn to "read" the numbers and associate bigger/colored numbers
with their build choices paying off.

---

## Medium Effort Improvements

### 6. Kill Streak / Combo Counter

**Problem:** No feedback loop for sustained skillful play. Each kill is
isolated.

**Design:**
- Track consecutive kills without player taking damage
- Display combo counter in bottom-right: "x3 COMBO" -> "x4 COMBO"
- Counter resets on player damage
- Visual escalation: counter gets larger and more colorful at higher values
- At 5x/10x/15x: brief screen flash + bigger shake
- Gameplay effect: bonus mana on kill scales with combo (5 base + 2 per combo)

**Files:** New `scripts/systems/combo_tracker.gd`,
`scripts/ui/hud.gd` (display),
`scripts/combat/health_component.gd` (hook into damage/death)

**Why it matters:** Combo counters create a mastery feedback loop. They
give advanced players something to optimize and create visible "flow state"
moments. The mana bonus means skilled play is mechanically rewarded, not
just aesthetically.

---

### 7. Power Scaling Moments

**Problem:** Player power feels flat across a run. Room 1 and Room 5 feel
similar despite accumulating cards.

**Design:**
- Track "power level" based on cards in deck (common=1, uncommon=2, rare=3)
- At power thresholds (10, 20, 30), trigger a "POWER UP" moment:
  - Brief slow-mo (0.3s at 30% time scale)
  - Radial burst from player
  - Permanent subtle particle aura (grows with power level)
  - Small stat bonus (+5% damage per threshold)
- Display power level somewhere subtle on HUD

**Files:** `scripts/managers/game_manager.gd` (power tracking),
`scripts/player/player.gd` (aura effect),
`scripts/ui/hud.gd` (power display)

**Why it matters:** The feeling of "getting stronger" is the core fantasy
of roguelikes. Without visible power scaling, card accumulation feels
abstract. Making it visible and impactful creates the "build coming online"
moment that Vampire Survivors nails.

---

### 8. Rest Chamber Interaction

**Problem:** Rest chambers exist in the room data but have no gameplay.

**Design:** Rest chambers should offer a *choice* (choices = engagement):
- **Rest**: Heal 30% of max health
- **Upgrade**: Pick one card in your deck to upgrade to its "+" version
- **Remove**: Delete one card from your deck (deck thinning)
- **Pray**: Gain a random buff for the next 2 rooms (risk/reward)

Only one action per rest chamber. This creates meaningful decisions.

**Files:** New `scripts/ui/rest_screen.gd`,
`scenes/levels/arena_rest.tscn`,
`scripts/managers/game_manager.gd` (card upgrade/remove methods)

**Why it matters:** Rest chambers are free "choice moments" that don't
require new combat design. They break up the fight-fight-fight rhythm,
let players reflect on their build, and add deck manipulation that
Slay the Spire players expect.

---

### 9. Boss Entrance Sequence

**Problem:** Boss room loads the same as any other room. No buildup.

**Design:**
- Fade to near-black on entering boss room (0.5s)
- Slow camera push (zoom from 1.0 to 0.9 over 1s)
- Boss name plate: "STONE GOLEM" slides in from right, holds 1.5s, slides out
- Health bar appears at top of screen (separate from normal enemy bars)
- Boss roar moment: big screen shake (15.0, 0.4s), ground crack effect
- 1s pause before boss becomes active

**Files:** `scripts/levels/arena_boss.gd` (override _ready sequence),
`scripts/ui/hud.gd` (boss health bar),
`scripts/combat/screen_fx.gd` (boss_entrance method)

**Why it matters:** Boss fights need ceremony. The entrance sequence builds
anticipation, signals "this is different", and makes the encounter
feel like a culmination. Every memorable boss in gaming history has an
entrance sequence.

---

## Larger Systems

### 10. Audio Foundation

**Problem:** Zero audio exists. This halves the game's perceived impact.

**Minimum viable audio set (prioritized):**

**Must-have (10 sounds):**
1. Melee hit impact (thwack)
2. Enemy death (pop/splat)
3. Player damage taken (grunt + thud)
4. Card play (whoosh + magic chime)
5. Room cleared (triumphant sting, 2s)
6. Dodge (swift air sound)
7. Health pickup / heal (gentle chime)
8. UI click / card select (soft click)
9. Mana gain (crystalline tinkle)
10. Boss roar / entrance (deep rumble)

**Nice-to-have (10 more):**
11. AOE explosion (boom)
12. Shield gain (metallic ring)
13. Debuff applied (dark whomp)
14. Buff applied (bright ascending tone)
15. Critical hit (amplified hit + glass shatter)
16. Combo milestone (ascending chime)
17. Card draw (paper slide)
18. Low health warning (heartbeat loop)
19. Map ambient (wind + distant echoes)
20. Combat ambient (percussive loop, scales with intensity)

**Files:** New `scripts/managers/audio_manager.gd` (singleton),
audio files in `assets/audio/sfx/` and `assets/audio/music/`

**Why it matters:** Audio research consistently shows that sound effects
account for roughly half of perceived impact in action games. The visual
juice system is excellent but incomplete without its audio counterpart.
A sword swing with no sound is a ghost. A kill with no death sound is
unsatisfying. This is the single largest gap.

---

### 11. Relic/Artifact System

**Problem:** No persistent modifiers within a run. Build identity comes
only from cards.

**Design concept:**
- Relics are passive items gained from elite rooms, boss kills, or shops
- Each relic modifies gameplay in a unique way:
  - "Ember Ring" - attacks have 10% chance to ignite enemies
  - "Thief's Glove" - gain 5 gold per kill
  - "Glass Cannon" - +30% damage, -20% max health
  - "Mana Prism" - card cycling costs 3 mana instead of 5
- Display relics in a row on the HUD (small icons)
- Start with 0, cap at ~5-6 per run

**Files:** New `resources/relics/relic_data.gd`,
`scripts/systems/relic_manager.gd`,
`scripts/ui/hud.gd` (relic display row)

**Why it matters:** Relics create *build identity*. "I'm running the glass
cannon fire build" is a story the player tells themselves. It's why they
start another run - "what if I got Ember Ring with a mage?" Build-crafting
fantasies drive replay more than any other single mechanic.

---

## Implementation Priority

| Priority | Item | Effort | Impact |
|----------|------|--------|--------|
| 1 | Enemy death burst (#1) | 2-3 hours | High |
| 2 | Enemy counter (#2) | 1-2 hours | High |
| 3 | Card draw animation (#3) | 2-3 hours | Medium |
| 4 | Dodge afterimage (#4) | 1-2 hours | Medium |
| 5 | Damage number variety (#5) | 1-2 hours | Medium |
| 6 | Audio foundation (#10) | 8-12 hours | Critical |
| 7 | Rest chamber (#8) | 4-6 hours | High |
| 8 | Boss entrance (#9) | 3-4 hours | High |
| 9 | Combo counter (#6) | 4-5 hours | Medium |
| 10 | Relic system (#11) | 12-16 hours | Critical |
| 11 | Power scaling (#7) | 3-4 hours | Medium |

---

## Sources

- [Game Feel: A Beginner's Guide](https://gamedesignskills.com/game-design/game-feel/)
- [Juice in Game Design: Making Games Feel Amazing](https://www.bloodmooninteractive.com/articles/juice.html)
- [Screen Shake and Hit Stop Effects on Impact](https://www.oreateai.com/blog/research-on-the-mechanism-of-screen-shake-and-hit-stop-effects-on-game-impact/decf24388684845c565d0cc48f09fa24)
- [Squeezing More Juice Out of Your Game Design](https://www.gameanalytics.com/blog/squeezing-more-juice-out-of-your-game-design)
- [How To Improve Game Feel In Three Easy Ways](https://gamedevacademy.org/game-feel-tutorial/)
