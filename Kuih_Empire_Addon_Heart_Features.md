# Kuih Empire — Add-on: Heart Features

**Project:** Kuih Empire  
**Document Type:** Feature Add-on  
**Feature Group:** Heart / Life System, Free Play Window & Soft Monetization  
**Engine:** Godot 4.x  
**Status:** Proposed for post-core-MVP / soft-launch testing

---

## 1. Purpose

This add-on introduces a light **Heart / Life system** for Kuih Empire.

The system is intended to:

- add gentle pacing to repeated puzzle attempts,
- provide optional monetization through rewarded ads and coins,
- create additional reward opportunities,
- support longer-term retention,
- remain consistent with the game's cozy and player-friendly identity.

The Heart system must behave as a **soft gate**, not a hard punishment.

---

## 2. Core Heart Rules

Recommended starting values:

- **Maximum Hearts:** 5
- **Lose / fail a stage:** -1 Heart
- **Win a stage:** no Heart consumed
- **Automatic refill:** +1 Heart every 30 minutes
- **When Hearts are full:** refill timer pauses
- Hearts are only required for starting or retrying puzzle stages.
- Hearts are not consumed while viewing:
  - Stall
  - Recipe Book
  - Route / Journey Map
  - Story scenes
  - Settings
  - Shop

### Early Game Exception

During tutorial and early onboarding, Hearts should either:

- not be consumed, or
- temporarily use an active Free Play Window.

This prevents new players from being blocked while still learning the game.

---

## 3. Heart Refill Options

When Hearts are depleted, the player should always have multiple options.

### 3.1 Automatic Refill

- Restore **1 Heart every 30 minutes**.
- Display a countdown until the next Heart.

Example:

```text
❤️❤️❤️♡♡
Next Heart: 18:42
```

---

### 3.2 Rewarded Ad Refill

Player may voluntarily watch a rewarded ad.

Reward:

```text
Watch Ad → +1 Heart
```

Recommended starting cap:

- **3 rewarded Heart refills per day**

This limit can be adjusted after soft-launch analytics.

Rewarded ads must remain optional.

---

### 3.3 Coin Refill

Recommended starting prices:

```text
+1 Heart      = 500 Coins
Full Refill   = 1,800 Coins
```

These values are initial balancing targets only and should be tuned through analytics.

---

### 3.4 Reward-Based Refill

Hearts can also be awarded through:

- Daily Login
- Story milestones
- Chapter completion
- Special events
- Achievement rewards
- Seasonal rewards

---

## 4. Heart Empty Modal

When the player reaches zero Hearts, show a friendly refill modal.

Suggested tone:

> **Aina needs a little rest!**  
> Come back soon, watch a short ad, or use coins to keep serving kuih.

Available actions:

```text
[ Watch Ad +1 Heart ]

[ Use 500 Coins +1 Heart ]

[ Full Refill 1,800 Coins ]

Next Heart in 18:42

[ Back to Stall ]
```

The modal must not make rewarded ads or payment feel mandatory.

---

# 5. Free Play Window

## 5.1 Definition

A **Free Play Window** is a temporary period during which puzzle attempts do not consume Hearts.

During Free Play:

- losing does not reduce Hearts,
- retrying is unlimited,
- normal stage rewards still apply,
- the player can continue progressing normally.

Example indicator:

```text
FREE PLAY ACTIVE
14:32 remaining
```

---

## 5.2 Suggested Triggers

### Win Streak Reward

Example:

```text
3 consecutive wins
→ 15 Minutes Free Play
```

Message:

> **Hot Streak! Unlimited Hearts for 15 minutes!**

---

### Chapter Milestone

Example:

```text
Chapter Milestone
→ 30 Minutes Free Play
```

Message:

> **Sweet Bonus! Enjoy 30 minutes of Free Play!**

---

### Event Reward

Free Play may also be rewarded through:

- Daily reward
- Festival event
- Seasonal milestone
- Limited-time challenge
- Special player appreciation reward

---

## 5.3 Timer Rules

The Free Play timer should use a real timestamp rather than relying only on active scene time.

Save:

```text
free_play_end_timestamp
```

This allows the timer to remain accurate when:

- app is minimized,
- game is closed,
- device sleeps,
- player changes scenes.

Recommended behavior:

- Free Play timer continues counting down in real time.

---

# 6. Top Bar UI

Recommended resource bar:

```text
❤️ 4 / 5     🪙 1,250     ⭐ 36
```

If Heart is not full:

```text
❤️ 4 / 5
+1 in 18:42
```

If Free Play is active:

```text
❤️ FREE PLAY
14:32
```

The UI should remain compact.

Avoid adding unnecessary premium currencies during MVP.

---

# 7. Resource Roles

Kuih Empire should keep each resource conceptually separate.

## Coins

**Coins = Spendable Currency**

Used for:

- boosters,
- pre-level specials,
- +5 Moves,
- Heart refill,
- selected Stall cosmetics,
- selected non-critical upgrades.

Coins can be earned through:

- stage completion,
- remaining-move bonus,
- Daily Reward,
- achievement,
- event,
- optional rewarded ad.

---

## Stars

**Stars = Permanent Progress**

Stars are not spendable currency.

Used for:

- route progression,
- chapter milestones,
- Story unlocks,
- Stall progression requirements,
- Recipe milestones,
- completionist goals.

Stars are never deducted.

Example:

```text
Stage 1   ⭐⭐⭐
Stage 2   ⭐⭐☆
Stage 3   ⭐⭐⭐
```

Possible milestones:

```text
12 Stars → Stall Upgrade
24 Stars → Recipe Unlock
36 Stars → Story Scene
45 Stars → Chapter Finale
```

Story-critical progression should preferably not require Coins.

---

## Hearts

**Hearts = Attempt Pacing**

Used for:

- puzzle attempts after failure.

Rules:

- winning does not cost a Heart,
- failure costs 1,
- Free Play disables Heart consumption.

---

# 8. Suggested Economy Flow

```text
PLAY LEVEL
    │
    ├── WIN
    │    ├── Coins
    │    ├── Stars
    │    └── Progress
    │
    └── FAIL
         └── -1 Heart
                │
                ├── Wait
                ├── Rewarded Ad
                ├── Coins
                └── Free Play Window
```

---

# 9. Monetization Principles

The Heart system must support monetization without damaging the cozy game experience.

## Allowed

- Rewarded ad for +1 Heart
- Coins for Heart refill
- Optional convenience purchases
- Free Play as a positive reward

## Avoid

- forcing ads when Hearts reach zero,
- removing all free refill options,
- extremely long refill timers,
- intentionally unfair stages designed to drain Hearts,
- frequent popups asking players to buy Lives,
- requiring paid currency for story progression.

The player must always retain a free path forward.

---

# 10. Balancing Defaults

Initial soft-launch values:

| Setting | Default |
|---|---:|
| Maximum Hearts | 5 |
| Heart lost on failure | 1 |
| Heart cost on win | 0 |
| Auto refill | 1 per 30 min |
| Rewarded ad reward | +1 Heart |
| Rewarded refill cap | 3 / day |
| Coin refill | 500 Coins / Heart |
| Full refill | 1,800 Coins |
| 3-win streak reward | 15 min Free Play |
| Chapter milestone | 30 min Free Play |

All values are subject to analytics and playtesting.

---

# 11. Godot Architecture

Recommended services / autoloads:

```text
GameManager
SaveManager
EconomyManager
HeartManager
RewardManager
AdManager
```

---

## 11.1 HeartManager Responsibilities

`HeartManager` should manage:

- current Hearts,
- maximum Hearts,
- refill interval,
- remove Heart,
- add Heart,
- full refill,
- automatic recovery,
- free-play active state,
- Free Play end timestamp,
- rewarded refill daily cap,
- UI update signals,
- save/load integration.

Possible API:

```gdscript
HeartManager.can_start_stage()
HeartManager.consume_on_failure()
HeartManager.add_heart(1)
HeartManager.full_refill()
HeartManager.start_free_play(duration_seconds)
HeartManager.is_free_play_active()
HeartManager.get_free_play_remaining()
HeartManager.get_next_refill_remaining()
```

---

## 11.2 Suggested Signals

```gdscript
signal hearts_changed(current, maximum)
signal heart_refilled()
signal hearts_depleted()
signal refill_timer_changed(seconds_remaining)

signal free_play_started(seconds)
signal free_play_updated(seconds_remaining)
signal free_play_ended()
```

---

# 12. Save Data

Persist:

```text
current_hearts
max_hearts
last_heart_refill_timestamp

free_play_end_timestamp

rewarded_heart_ads_used_today
rewarded_heart_ads_reset_date
```

Do not rely only on runtime countdown values.

Use timestamps so state can be restored after restarting the game.

---

# 13. Stage Start Logic

Before starting a puzzle:

```text
Player selects Stage
        ↓
Is Free Play active?
     ├── Yes → Start
     │
     └── No
           ↓
      Heart > 0?
       ├── Yes → Start
       └── No → Heart Refill Modal
```

A Heart is **not immediately consumed when entering the stage**.

Recommended rule:

> Consume one Heart only when the stage ends in failure.

This makes successful play feel less punitive.

---

# 14. Stage Failure Logic

```text
STAGE FAILED
      ↓
Free Play active?
  ├── Yes
  │    └── No Heart consumed
  │
  └── No
       ↓
      -1 Heart
```

Then show:

- Try Again
- Use Booster
- Back to Stall

If no Hearts remain:

- show Heart refill options before retry.

---

# 15. Stage Win Logic

```text
STAGE COMPLETE
      ↓
No Heart consumed
      ↓
Award Coins
      ↓
Calculate Stars
      ↓
Check Win Streak
      ↓
Check Free Play Reward
      ↓
Progress Journey
```

---

# 16. Win Streak

Track consecutive stage victories.

Example:

```text
Win 1 → streak 1
Win 2 → streak 2
Win 3 → Free Play 15 min
```

A failed stage resets the normal win streak unless future balancing decides otherwise.

The reward should feel celebratory rather than mandatory.

---

# 17. Free Play Reward UI

Suggested popup:

```text
SWEET STREAK!

3 Wins in a Row!

❤️ Unlimited Hearts
15:00

[ KEEP PLAYING ]
```

Use:

- Aina celebration animation,
- warm sparkles,
- subtle Heart animation,
- no forced ad.

---

# 18. Analytics

Track the following.

## Heart Metrics

- Hearts spent per player/day
- percentage of players reaching zero
- average time before depletion
- refill frequency
- average Heart balance when session ends

## Rewarded Ads

- Heart ad opt-in rate
- average ads per user
- completion rate
- quit rate when ad option is shown

## Coin Refills

- number of coin refills
- Coins spent on Hearts
- Coins spent on boosters
- Full refill usage

## Free Play

- number of Free Play activations
- average session length during Free Play
- stages attempted during Free Play
- stages completed during Free Play
- player retention after Free Play reward

## Frustration Signals

- quits immediately after Heart depletion
- repeated failures on same stage
- ad refusal followed by session exit
- unusually high Heart consumption on specific stages

---

# 19. Soft-Launch Evaluation

Heart system should remain configurable.

Important questions to test:

1. Does Heart pacing increase return sessions?
2. Does it reduce session satisfaction?
3. How often do players naturally run out?
4. Do players voluntarily use rewarded ads?
5. Are Coins meaningful as an alternative refill path?
6. Does Free Play increase session length?
7. Does 30-minute refill feel fair?
8. Should maximum Hearts remain 5?
9. Are specific levels consuming too many Hearts?
10. Does the system improve monetization without hurting retention?

If Heart depletion causes significant player drop-off, loosen or disable the system.

---

# 20. UX Principle

The emotional tone should remain:

> **“Take a short rest, then come back for more kuih.”**

Not:

> **“You are out of Lives. Pay or leave.”**

Heart mechanics exist to pace gameplay and provide optional monetization opportunities while preserving the warm identity of **Kuih Empire**.

---

# Feature Summary

**Heart System**

```text
5 Hearts
↓
Lose = -1
Win = No Cost
↓
1 Heart / 30 min
↓
Wait / Ad / Coins
```

**Free Play Window**

```text
Win Streak / Milestone
          ↓
Unlimited Hearts
          ↓
15–30 Minutes
          ↓
Play & Retry Freely
```

**Economy**

```text
Coins = Spend
Stars = Progress
Hearts = Attempts
Free Play = Reward
```

---

## Design Principle

> **Soft pacing. Fair choices. Sweet rewards.**
