# The Ember Sanctum - Game Design Audit

## What This Document Is

An honest assessment of The Ember Sanctum's current dopamine loop, reward
structure, and game feel through the lens of proven action-roguelike design.
The goal: identify what's working, what's missing, and where the game leaks
engagement.

---

## 1. The Current Core Loop

Every sticky game has a tight **core loop** - the smallest repeatable cycle
that feels rewarding. Here's ours mapped out:

```
  [ENTER ROOM] --> [FIGHT ENEMIES] --> [USE CARDS] --> [CLEAR ROOM]
       ^               |                   |               |
       |               v                   v               v
       |          (hit feedback)      (mana economy)   (card reward)
       |                                                   |
       +------- [PICK CARD] <--- [CHOOSE FROM 3] <--------+
                     |
                     v
              [NEXT ROOM ON MAP]
```

**Loop timing** (estimated): ~60-90 seconds per room, ~8-12 minutes per run.

### What's Working

- **The card reward after each room is the right instinct.** Slay the Spire
  proved that "pick 1 of 3" is one of the strongest dopamine triggers in
  games - it creates *anticipation* (what will I be offered?), *agency*
  (I choose my build direction), and *variable reward* (different cards
  each time).

- **Health carrying between rooms creates tension.** Every hit matters
  because it persists. This is the roguelike "risk/reward pressure" that
  keeps attention high.

- **The card hand system during combat adds tactical depth.** Tactical
  focus mode (slow-mo on RMB) is a great touch - it gives that Superhot
  feeling of "time moves when I move" planning.

- **Enemy variety is genuinely strong.** 10 enemy types with 13 composable
  behaviors is well above average for this stage. The Banshee's mana cost
  increase is particularly clever - it attacks the player's card economy,
  not just their health bar.

### Where It Breaks Down

**Problem 1: The loop is missing its "crunch" moment.**

The best action roguelikes have a moment *within* each combat where the
player feels powerful. In Hades, it's the chain-dash into a crowd with
a powered boon. In Vampire Survivors, it's the screen-filling explosion
when your build comes online. In Slay the Spire, it's the turn where your
combo fires off 40 damage.

Currently: enemies spawn, player hits them, they die. There's no escalation
*within* a fight. The card system has the potential to create these moments,
but cards resolve instantly with no buildup.

**Problem 2: No economy beyond cards.**

The only reward is "pick a card." Every room, same reward type. This makes
the reward schedule *fixed ratio* - the player knows exactly what they'll
get and when. Research shows fixed ratio schedules produce engagement that
drops off quickly compared to variable ratio schedules.

Compare to Slay the Spire: after a fight you might get a card, gold,
a potion, or a relic. The *uncertainty* of what reward type you'll see
is itself engaging.

**Problem 3: No meta-progression.**

When a run ends, nothing carries over. The player returns to class select
with zero persistent progress. This is the single biggest retention killer.

Hades solved this brilliantly: every failed run deposits currencies
(Darkness, Keys, Gems, Nectar) that unlock permanent upgrades, new weapons,
and story beats. The player is *always* progressing even when they lose.
Slay the Spire uses character XP to unlock new cards for the pool.

Without meta-progression, the game is asking players to replay the same
7-room structure with only their own skill growth as motivation. That works
for a tiny percentage of players; most need extrinsic scaffolding.

**Problem 4: No audio whatsoever.**

This is the elephant in the room. Zero sound files exist in the project.
Visual juice is excellent (screen shake, hit sparks, damage numbers, spell
effects) but without audio, every hit feels like punching underwater.
Audio is responsible for roughly 50% of perceived "game feel" impact.

---

## 2. The Dopamine Loop Breakdown

A dopamine loop has three phases: **Anticipation** (trigger), **Action**
(behavior), and **Reward** (reinforcement). Here's how each phase performs:

### Anticipation (WEAK)

| Moment | Current State | Issue |
|--------|---------------|-------|
| Entering a new room | Map shows room name/type | No preview of enemies, no threat assessment |
| Drawing cards in combat | Cards appear in hand slots | No "draw" animation, cards just appear |
| Room clear approaching | No indicator | Player can't tell when last enemy dies vs more spawning |
| Boss encounter | Same door as other rooms | No buildup, no distinct warning |

**The fix:** Anticipation needs *signals*. A wave counter ("Wave 1/1" or
"3 enemies remaining"), a boss door that looks different, a card draw
animation that creates a micro-moment of "what did I get?"

### Action (STRONG)

| Moment | Current State | Assessment |
|--------|---------------|------------|
| Basic attacks | Hit stop, sparks, shake, knockback | Good |
| Card plays | Screen effects, burst visuals, shake | Good |
| Dodging | Invincibility frames, speed boost | Functional but no afterimage |
| Tactical focus | 15% time scale on RMB | Excellent |

The combat action layer is the game's strongest pillar. The ScreenFX system
and SpellEffectVisual system are comprehensive.

### Reward (NEEDS WORK)

| Moment | Current State | Issue |
|--------|---------------|-------|
| Killing an enemy | Enemy disappears | No loot drop, no XP, no satisfying death anim |
| Clearing a room | "ROOM CLEARED" label + card pick | Only one reward type, no variation |
| Beating the boss | "VICTORY" label | Returns to class select - no unlocks, no fanfare |
| Playing a synergy | Glow on cards | No combo counter, no escalating reward |

**This is where the loop leaks most.** The player does hard work (action)
but the reward phase is thin. Every kill should feel *slightly* rewarding
(enemy burst effect, small mana/health/currency drop). Every room clear
should feel like opening a chest with unknown contents.

---

## 3. Systems Scorecard

| System | Score | Notes |
|--------|-------|-------|
| Combat feel | 8/10 | Hit stop + sparks + shake = excellent base |
| Card design | 8/10 | 60 cards, good variety, synergy system |
| Enemy design | 8/10 | 10 types, 13 behaviors, strong composition |
| Visual juice | 9/10 | ScreenFX and SpellEffectVisual are thorough |
| Audio | 0/10 | Nothing exists |
| Reward variety | 3/10 | Cards only, no gold/relics/potions |
| Meta-progression | 1/10 | Nothing persists between runs |
| Anticipation/buildup | 3/10 | No wave counters, enemy previews, or threat signals |
| Death satisfaction | 2/10 | Enemies just disappear |
| Run-end payoff | 2/10 | Win or lose, same outcome: class select screen |
| UI information | 7/10 | Health/mana bars are polished, but no buff timers |
| Player identity | 5/10 | 3 classes exist but feel similar in combat |

**Overall: 4.7/10 for "stickiness"**

The *mechanical foundation* is strong (7-8/10). The *psychological
engagement layer* is weak (2-3/10). The game plays well in the moment
but gives no reason to start another run.

---

## 4. The Competition Benchmark

How comparable games handle what we're missing:

### Slay the Spire
- **Rewards**: Cards + gold + potions + relics after each fight
- **Meta**: Character XP unlocks new cards for future pool
- **Anticipation**: Question mark nodes, elite markers, shop previews
- **Retention hook**: Ascension levels (20 difficulty tiers)

### Hades
- **Rewards**: Boons (random god powers), currencies, story progression
- **Meta**: Mirror of Night (permanent stat upgrades), weapon aspects, keepsakes
- **Anticipation**: Door symbols show reward type before entering
- **Retention hook**: Relationship progression, true ending requires 10+ clears

### Vampire Survivors
- **Rewards**: XP → level up → pick 1 of 3 upgrades (every 30-60s!)
- **Meta**: Gold → permanent unlocks, new characters, new stages
- **Anticipation**: Level-up bar always visible, approaching boss timer
- **Retention hook**: Achievement unlocks reveal hidden content

### What They All Share
1. **Multiple reward currencies** (not just one type)
2. **Persistent progression** between runs
3. **Visible anticipation signals** (progress bars, door previews)
4. **Escalating power fantasy** within a run (you START weak, END strong)
5. **Audio that sells every moment**

---

## 5. Priority Recommendations

### Tier 1: "Makes or Breaks Retention"

1. **Add meta-progression system** - Persistent currency (Ember? Souls?)
   earned each run (win or lose) that unlocks permanent upgrades, new
   cards for the pool, and cosmetics. This is the #1 change for retention.

2. **Add audio/SFX** - Hit sounds, card play sounds, ambient music,
   death sounds. Every other juice system is built and waiting for audio
   to complete the sensory loop.

3. **Add gold/currency drops from enemies** - Small gold drops on kill
   create micro-rewards throughout combat. Accumulates to spend at rest
   chambers (card upgrades, healing, card removal).

### Tier 2: "Makes the Game Feel Alive"

4. **Enemy death effects** - Burst particles, brief ragdoll/dissolve,
   small screen shake. Make every kill feel like an accomplishment.

5. **Reward variety** - Post-room rewards should vary: cards OR gold OR
   potion OR relic. The uncertainty is itself engaging.

6. **Wave/enemy counter UI** - Show remaining enemies. Watching the number
   tick down creates anticipation for the clear moment.

### Tier 3: "Deepens Mastery"

7. **Combo counter** - Track consecutive hits without taking damage.
   Higher combos = bonus gold or damage multiplier. Creates a visible
   mastery metric players can try to improve.

8. **Class-specific ultimates** - Each class gets a signature ability
   on a long cooldown. Creates "power fantasy peaks" within fights.

9. **Run statistics screen** - On run end, show stats: damage dealt,
   cards played, enemies killed, rooms cleared, time. Let players see
   their growth.

---

## Sources

Research informing this audit:
- [Compulsion Loops & Dopamine in Games](https://www.gamedeveloper.com/design/compulsion-loops-dopamine-in-games-and-gamification)
- [Why Roguelikes Are So Addictive](https://retrostylegames.com/blog/why-are-roguelike-games-so-engaging/)
- [The Dopamine Loop: How Game Design Keeps Players Hooked](https://videogameheart.com/the-dopamine-loop-how-game-design-keeps-players-hooked/)
- [Reward Schedules and When to Use Them](https://www.gamedeveloper.com/business/reward-schedules-and-when-to-use-them)
- [How Slay The Spire Became The Gold Standard](https://www.greenmangaming.com/blog/how-slay-the-spire-became-the-gold-standard-for-all-card-battler-games/)
- [Game Feel: A Beginner's Guide](https://gamedesignskills.com/game-design/game-feel/)
- [Juice in Game Design](https://www.bloodmooninteractive.com/articles/juice.html)
- [The Secret Sauce of Vampire Survivors](https://jboger.substack.com/p/the-secret-sauce-of-vampire-survivors)
