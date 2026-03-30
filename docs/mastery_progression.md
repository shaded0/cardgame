# Mastery & Retention Design

## Purpose

Design the systems that make players *come back*. The game feel doc covers
moment-to-moment satisfaction; this doc covers the longer arc - what happens
across runs, across sessions, across weeks.

---

## 1. The Mastery Framework

Player retention in roguelikes comes from three interlocking systems:

```
         SKILL MASTERY                BUILD MASTERY
     (I'm getting better)       (I understand the systems)
              \                        /
               \                      /
                v                    v
             PROGRESSION MASTERY
          (The game recognizes my growth)
```

**Skill mastery** = dodging better, managing mana, reading enemy patterns.
**Build mastery** = knowing which cards synergize, when to take risks.
**Progression mastery** = unlocking content that rewards the above two.

The Ember Sanctum currently supports skill mastery (combat is solid) and
early build mastery (card synergies exist). Progression mastery is absent.
This is the gap to fill.

---

## 2. Meta-Progression: The Ember Forge

### Concept

Between runs, the player visits the **Ember Forge** - a persistent hub
where currencies earned during runs are spent on permanent upgrades. This
is the equivalent of Hades' Mirror of Night.

### Currency: Embers

- Earned from every enemy kill (1-3 Embers based on enemy tier)
- Bonus Embers for room clears (10 base + 5 per tier)
- Bonus Embers for boss kill (50)
- Bonus Embers for combo milestones during run (5 per milestone)
- **Critically: earned even on failed runs.** A run to room 3 where you
  die still yields 40-80 Embers. This means every run has tangible value.

### Ember Forge Upgrades (Progression Tree)

**Vitality Branch** (survive longer):
| Level | Cost | Effect |
|-------|------|--------|
| 1 | 50 | +10 max health (all classes) |
| 2 | 100 | Start with 1 shield |
| 3 | 200 | +5% healing from all sources |
| 4 | 400 | Health potion at run start (heal 25%) |
| 5 | 800 | +20 max health |

**Arcane Branch** (stronger cards):
| Level | Cost | Effect |
|-------|------|--------|
| 1 | 50 | +5 max mana |
| 2 | 100 | +10% mana regen |
| 3 | 200 | Card cycling costs 4 mana (down from 5) |
| 4 | 400 | Start combat with 1 random card pre-played |
| 5 | 800 | +1 card choice when picking rewards (4 instead of 3) |

**Combat Branch** (deal more damage):
| Level | Cost | Effect |
|-------|------|--------|
| 1 | 50 | +5% basic attack damage |
| 2 | 100 | +10% damage to first enemy hit each room |
| 3 | 200 | Kills have 10% chance to refund 5 mana |
| 4 | 400 | +1 basic attack per combo (double-hit) |
| 5 | 800 | 5% chance for attacks to crit (2x damage) |

**Fortune Branch** (better rewards):
| Level | Cost | Effect |
|-------|------|--------|
| 1 | 75 | +20% Ember drops |
| 2 | 150 | Uncommon cards appear 15% more often |
| 3 | 300 | Rest chambers offer an additional choice |
| 4 | 600 | Rare cards appear 10% more often |
| 5 | 1200 | Start each run with 1 random relic |

### Pacing

Total cost to max all branches: ~6,500 Embers.
Average Embers per full run (all rooms): ~150-200.
Average Embers per failed run (die at room 3): ~50-80.

**Time to max:** ~40-50 runs. This aligns with the 30-100 run mastery
curve that Hades and Slay the Spire target.

**First meaningful unlock:** 50 Embers = 1-2 runs. The player should feel
progression within their first session.

---

## 3. Unlock System: New Content as Reward

### Card Pool Unlocks

Start the game with a reduced card pool (30 of 60 cards available).
Unlock new cards by meeting conditions:

| Unlock Condition | Cards Unlocked |
|-----------------|----------------|
| First run completed | 5 random class cards |
| Kill 50 enemies (lifetime) | 3 neutral cards |
| Clear a room without taking damage | 2 class cards |
| Use 10 different cards in one run | 3 cards |
| Beat the boss | 5 rare cards |
| Beat the boss with each class | 2 unique cards per class |
| Reach combo x10 | 2 combat-oriented cards |
| Play 20 AOE cards (lifetime) | 2 AOE cards |

This creates discoverable goals. Players who check their card collection
see locked cards with unlock hints, motivating specific playstyles.

### Class Unlocks

- **Soldier**: Available from start
- **Rogue**: Unlocked after first boss kill
- **Mage**: Unlocked after clearing 3 elite rooms (lifetime)

Starting with one class and unlocking others is a proven retention hook.
It gives returning players entirely new gameplay to explore.

### Enemy Bestiary

Track enemies killed per type. Display in a "Bestiary" menu:
- Silhouette until first kill (mystery = curiosity)
- Stats revealed after 10 kills
- Behavior hints revealed after 25 kills
- Lore text revealed after 50 kills

This is pure collection/completion motivation and costs almost nothing
to implement since enemy data already exists.

---

## 4. Within-Run Mastery Signals

### Combo System (Detailed Design)

```
Kill without taking damage:
  x1 -> x2 -> x3 (bronze glow, +2 mana per kill)
  x4 -> x6 (silver glow, +3 mana per kill, damage numbers bigger)
  x7 -> x9 (gold glow, +5 mana per kill, subtle time slow on kill)
  x10+ (platinum glow, +5 mana, screen pulse, ember drop bonus)

Taking damage: combo resets, brief "combo broken" flash
```

**Why mana as the combo reward?** It feeds back into card play. Higher
combos = more cards played = more spectacular combat = higher combos.
This is a positive feedback loop that rewards skill with *more fun*,
not just more numbers.

### Mastery Ratings Per Room

After clearing a room, briefly show a performance rating:

| Rating | Criteria |
|--------|----------|
| S | No damage taken, combo x5+ |
| A | Took less than 20% max health in damage |
| B | Took less than 50% damage |
| C | Cleared the room (any health) |

Ratings are displayed for 1 second during the clear animation. They don't
gate rewards - they're purely a mastery signal. Players will naturally try
to improve their ratings, creating self-imposed challenge.

### Build Synergy Notifications

When the player's deck reaches a critical mass of synergistic cards,
show a brief "SYNERGY UNLOCKED" notification:

- 3+ damage cards + Vulnerable debuff card = "Glass Cannon Synergy"
- 3+ shield/heal cards = "Fortress Synergy"
- 2+ AOE cards + multi-hit = "Wrath Synergy"
- Exhaust cards + draw cards = "Efficiency Synergy"

These are cosmetic labels, not mechanical bonuses. But naming a build
makes it feel intentional and crafted, not random.

---

## 5. Session Structure & Pacing

### The Ideal Session Arc

A single session (30-60 minutes) should contain:

1. **Open Ember Forge** - Spend currency from last session, feel progress
2. **Run 1** - Apply new upgrades, maybe die early (learning run)
3. **Return to Forge** - Spend earned Embers, unlock something
4. **Run 2** - Better prepared, reach further, earn more
5. **Return to Forge** - Meaningful unlock (new card? new upgrade tier?)
6. **Run 3** (optional) - Go for the boss with accumulated knowledge

Each run is 8-12 minutes. Three runs per session = ~30-40 minutes.
The Forge visits between runs are the "breathing room" that prevents
burnout and creates anticipation for the next run.

### The "One More Run" Hook

The player should end each run in one of two states:

**State A: "I almost had it"**
- Died on room 5 of 7, had a great build going
- *Motivation:* "If I just play a bit more carefully, I can win"
- *System support:* Show "You were X rooms from the boss" on death

**State B: "I just unlocked something cool"**
- Earned enough Embers for a new upgrade
- *Motivation:* "I want to try a run with this new upgrade"
- *System support:* Show unlock notification + "NEW" badge in Forge

Both states create immediate desire to play again. The key is that the
death screen should never feel like a dead end - it should always point
toward the next goal.

### Run End Screen Design

On death or victory, show:

```
+------------------------------------------+
|         RUN COMPLETE / DEFEATED           |
|                                           |
|  Rooms Cleared: 4/7                       |
|  Enemies Slain: 28                        |
|  Cards Played: 42                         |
|  Best Combo: x7                           |
|  Damage Dealt: 1,840                      |
|                                           |
|  EMBERS EARNED: 87                        |
|    Kills: 42                              |
|    Room clears: 40                        |
|    Combo bonus: 5                         |
|                                           |
|  [RETURN TO FORGE]  [NEW RUN]             |
+------------------------------------------+
```

This screen serves three purposes:
1. **Validates the run** - "I accomplished things even though I died"
2. **Shows currency earned** - "My time wasn't wasted"
3. **Points forward** - "Return to Forge" implies spending, "New Run"
   implies trying again

---

## 6. Long-Term Retention: Ascension System

After the player beats the boss for the first time, unlock **Ascension
Mode** - escalating difficulty modifiers that stack:

| Ascension | Modifier |
|-----------|----------|
| 1 | Enemies have +10% health |
| 2 | Elite rooms have +1 enemy |
| 3 | Rest chambers heal 20% instead of 30% |
| 4 | Enemies have +10% damage |
| 5 | Start with -10 max health |
| 6 | Card rewards offer 2 choices instead of 3 |
| 7 | Boss gains a new attack pattern |
| 8 | Enemies move 10% faster |
| 9 | -1 starting mana per room |
| 10 | All modifiers from 1-9 active, boss has 2 phases |

Ascension gives completionist players hundreds of hours of content with
minimal new asset creation. It's how Slay the Spire kept players engaged
for 1000+ hours.

---

## 7. Implementation Roadmap

### Phase 1: Foundation (Weeks 1-2)
- [ ] Ember currency system (earn on kill/clear/boss)
- [ ] Run end screen with stats and Embers earned
- [ ] Basic Ember Forge screen (spend Embers on upgrades)
- [ ] 2-3 upgrades per branch to start

### Phase 2: Content Unlocks (Weeks 3-4)
- [ ] Card pool unlock system (conditions tracking)
- [ ] Class unlock gates
- [ ] Enemy bestiary (collection screen)
- [ ] "NEW" badges on newly unlocked content

### Phase 3: Within-Run Mastery (Weeks 5-6)
- [ ] Combo counter system
- [ ] Room mastery ratings (S/A/B/C)
- [ ] Build synergy notifications
- [ ] Relic system (5-10 starter relics)

### Phase 4: Endgame (Weeks 7-8)
- [ ] Ascension system
- [ ] Complete Forge upgrade tree
- [ ] Full card pool (all 60 unlockable)
- [ ] Statistics tracking (lifetime stats)

---

## 8. Metrics to Watch

Once implemented, these signals indicate whether the mastery systems are
working:

| Metric | Healthy Range | Problem Signal |
|--------|---------------|----------------|
| Runs per session | 2-4 | <2 = progression too slow, >5 = runs too short |
| Forge visits per session | 1-3 | 0 = not earning enough, >3 = runs too short |
| Avg run length (rooms) | 3-6 | <3 = too hard or not enough upgrades, >6 = too easy |
| Time to first boss kill | 5-10 runs | <3 = too easy, >15 = too hard or not enough upgrades |
| Ascension 1 attempts | 3-5 runs | <2 = ascension too easy, >8 = cliff too steep |
| Card unlock rate | 2-4 per session | <1 = conditions too hard, >6 = no scarcity |

---

## Sources

- [Designing for Mastery in Roguelikes](https://www.gridsagegames.com/blog/2025/08/designing-for-mastery-in-roguelikes-w-roguelike-radio/)
- [Roguelite Games With Best Progression Systems](https://gamerant.com/roguelite-games-with-best-progression-systems/)
- [The Secret Sauce of Vampire Survivors](https://jboger.substack.com/p/the-secret-sauce-of-vampire-survivors)
- [Hades Changes What It Means To Be A Roguelike](https://www.gamespot.com/articles/hades-changes-what-it-means-to-be-a-roguelike/1100-6483420/)
- [How Slay The Spire Became The Gold Standard](https://www.greenmangaming.com/blog/how-slay-the-spire-became-the-gold-standard-for-all-card-battler-games/)
- [Understanding Game Design: Psychology of Addiction](https://medium.com/@luc_chaoui/understanding-game-design-the-psychology-of-addiction-41128565305f)
- [Reward Schedules and When to Use Them](https://www.gamedeveloper.com/business/reward-schedules-and-when-to-use-them)
- [The Psychology of Reward Cycles in Modern Games](https://good2gorecruiter.com/the-psychology-of-reward-cycles-in-modern-games/)
