# Kuih Empire — Add-on: Journey, Story & Level Progression

**Project:** Kuih Empire  
**Document Type:** Feature Add-on  
**Feature Group:** Journey / Story / Milestone / Stage Progression  
**Engine:** Godot 4.x  
**Status:** Locked Design Direction

---

# 1. Locked Progression Structure

Kuih Empire menggunakan progression hierarchy berikut:

```text
JOURNEY
  ↓
STORY / CHAPTER
  ↓
MILESTONE
  ↓
STAGE
```

Setiap **Story / Chapter** mengandungi:

- **30 Stages**
- Dibahagikan kepada **3 Milestones**
- Setiap Milestone mempunyai **10 Stages**
- Setiap 10 Stage mesti menghasilkan perubahan yang boleh dirasai pada dunia, gerai, cerita, pelanggan atau bisnes
- Setiap Story berakhir dengan finale besar pada Stage 30
- Selesai satu Story membuka lokasi / cerita seterusnya

Formula rasmi:

```text
1 Story
= 30 Stages
= 3 Milestones
= 10 Stages setiap Milestone
```

---

# 2. Progression Philosophy

Player tidak sepatutnya merasa mereka sekadar melalui nombor level.

Setiap 10 Stage perlu memberi rasa:

> “Aku sudah capai sesuatu.”

Setiap 30 Stage pula perlu memberi rasa:

> “Aku sudah habiskan satu cerita dan membuka bab hidup Aina yang baru.”

Progression mesti kelihatan secara visual melalui:

- perubahan gerai
- background / lokasi
- pelanggan
- unlock kuih
- unlock recipe
- unlock mechanic
- Story scene
- decoration
- business growth
- route map

---

# 3. Milestone Rhythm

Setiap blok 10 Stage menggunakan pacing berikut sebagai baseline:

```text
Stage 1       Introduce
Stage 2–3     Practice
Stage 4–6     Combine
Stage 7–8     Challenge
Stage 9       Breather
Stage 10      Milestone Challenge
```

Ini bukan rule mutlak, tetapi digunakan sebagai rhythm asas level design.

---

# 4. Milestone Rewards

Setiap Stage 10, 20 dan 30 mesti memberi reward yang lebih bermakna daripada Coins sahaja.

Possible milestone rewards:

- Gerai visual upgrade
- New Recipe
- New Kuih
- New Customer Type
- New Booster / Special
- New Story Scene
- New Decoration
- New Mechanic
- New Background State
- Free Play Window
- Chapter collectible
- Reputation increase

Stage 30 perlu mempunyai reward yang lebih besar:

- major visual change
- Story finale
- new location unlock
- new route branch
- new customer group
- new chapter mechanic

---

# 5. Story 1 — Gerai Keluarga

## Overall Theme

Aina menghidupkan semula gerai kuih keluarga yang sederhana dan perlahan-lahan menjadikannya kembali kemas, hidup dan berkembang.

Total:

**Stage 1–30**

---

## Milestone 1 — Mula Bangkit

**Stage 1–10**

Theme:

> Aina mula membuka semula gerai dan belajar mengurus customer order.

Focus:

- Match-3 tutorial
- basic customer orders
- 3–4 jenis kuih awal
- simple move limits
- first special match
- first customers
- first win / fail flow
- onboarding

Visual State:

- gerai masih sederhana
- papan tanda lama
- tray minimum
- ruang jualan belum teratur

Stage 10:

**First Busy Morning**

Possible rewards:

- signboard baru
- Recipe unlock
- small Gerai upgrade
- Story beat

---

## Milestone 2 — Kemas & Cantikkan Gerai

**Stage 11–20**

Theme:

> Aina mula melabur semula hasil jualan untuk memperbaiki gerai.

Gameplay progression:

- introduce blocker
- introduce customer queue
- packaging objective
- more kuih
- stronger combos
- slightly tighter move count

Visual upgrades:

- awning
- counter
- rack
- decoration
- better presentation

Stage 20:

**Weekend Market Rush**

Possible rewards:

- Gerai visual state 2
- new recipe
- new customer type
- Free Play reward

---

## Milestone 3 — Kembangkan Bisnes

**Stage 21–30**

Theme:

> Gerai Aina semakin dikenali dan order mula meningkat.

Gameplay progression:

- larger orders
- multi-customer
- stronger Specials
- combo objectives
- more advanced blockers
- first high-pressure but still cozy challenges

Story progression:

- regular customers
- word-of-mouth grows
- local community support
- opportunity to sell outside the gerai

Stage 30:

# Gerai Keluarga Finale

Possible challenge:

**Big Community Order**

Major rewards:

- Gerai Level 2
- Story finale
- new Recipe
- next location unlocked
- next Story introduced

---

# 6. Story 2 — Kantin Sekolah

## Overall Theme

Aina menerima peluang untuk membekalkan atau membuka temporary stall di kantin sekolah.

Total:

**Stage 31–60**

Location:

**School Canteen**

---

## Milestone 1 — Percubaan Pertama

**Stage 31–40**

Theme:

> Aina mencuba berniaga di lokasi baru buat kali pertama.

Gameplay ideas:

- new customer profile: students
- smaller fast orders
- lunch-break feel
- limited packaging
- faster order sequencing

New mechanic candidate:

**Lunch Break Rush**

Stage 40:

First successful school day.

Possible rewards:

- School Stall visual state 1
- new recipe
- new customer group

---

## Milestone 2 — Jadi Kegemaran

**Stage 41–50**

Theme:

> Kuih Aina mula menjadi kegemaran pelajar dan guru.

Gameplay progression:

- repeat / regular customers
- teacher order
- multiple order types
- new kuih
- packaging becomes more important
- more complex board layouts

Story beats:

- students recommend Aina
- teacher places larger order
- school event invitation

Stage 50:

**School Order Rush**

Possible rewards:

- School Stall upgrade
- new Recipe
- reputation increase

---

## Milestone 3 — Hari Kantin

**Stage 51–60**

Theme:

> Aina bersedia untuk Hari Kantin / school festival.

Gameplay:

- larger customer queues
- special objectives
- special combo stages
- event-style levels
- more advanced specials

Stage 60:

# Hari Kantin Finale

Major rewards:

- major School Story completion
- new Recipe
- special cosmetic / decoration
- next location unlocked

---

# 7. Story 3 — Pasar Pagi

Suggested range:

**Stage 61–90**

Milestones:

### Stage 61–70
**Cari Tapak**

Aina mula berniaga di pasar pagi.

### Stage 71–80
**Tarik Pelanggan**

Build recognition and repeat customers.

### Stage 81–90
**Weekend Market**

Final market challenge.

Possible progression:

- denser customer queue
- more packaging
- market-specific blockers
- special orders
- new regional kuih

---

# 8. Story 4 — Pekan

Suggested range:

**Stage 91–120**

Milestones:

### Stage 91–100
**Supply Kedai Kopi**

### Stage 101–110
**Tempahan Pejabat**

### Stage 111–120
**Festival Pekan**

Focus:

- bigger commercial orders
- packaging
- office orders
- delivery-style objectives
- more modern stall presentation

---

# 9. Story 5 — Bandar

Suggested range:

**Stage 121–150**

Milestones:

### Stage 121–130
**Pop-up Booth**

### Stage 131–140
**Corporate Orders**

### Stage 141–150
**City Food Festival**

Theme:

> Aina moves from local recognition to city exposure.

Possible unlocks:

- modern gerai style
- premium customer orders
- advanced Specials
- city-based Recipe entries

---

# 10. Story 6 — Festival Kuih Kita

Suggested range:

**Stage 151–180**

This becomes the Season 1 finale.

Milestones:

### Stage 151–160
**Persiapan Festival**

### Stage 161–170
**Festival Days**

### Stage 171–180
**Grand Finale**

Finale should feel larger than previous chapters.

Possible final challenge:

- multi-customer
- multiple objective types
- special combo requirements
- large order
- Festival visual spectacle

Stage 180:

# Season 1 Finale

Possible rewards:

- Festival Kuih Kita Award
- major Gerai visual evolution
- special Aina cosmetic
- Season 1 achievement
- teaser for next Journey / Season

---


## Future location addition — Bazaar Ramadan

Requested addition: **Bazaar Ramadan** (Bazaar Ramadhan), a future Journey story after the six locations in the visual reference.

- Location ID: `bazaar_ramadan`.
- English display name: **Ramadan Bazaar**; Malay display name: **Bazaar Ramadan**.
- Proposed Story 7, stages **181–210**, after Festival Kuih Kita. This is a planning range, not playable content yet. Existing Story 1–6 stage IDs remain unchanged.
- Preserve the existing Season 1 finale at stage 180; the bazaar is a future extension. Any seasonal event version should be separate from permanent Journey progression and must not reset Journey stars or rank.

| Progress | Milestone | Structural appearance |
|---|---|---|
| Starting at stage 181 | Bazaar setup | Simple canopy, basic kuih counter, warm late-afternoon atmosphere |
| After stage 190 | Preparing for Iftar / Persiapan Berbuka | Improved counter, Ramadan bazaar sign and clearer display trays |
| After stage 200 | A Lively Bazaar / Bazaar Meriah | Better canopy, display cabinet, lanterns and a dedicated takeaway area |
| After stage 210 | Sweetness Together / Manis Bersama | Completed Kuih Empire bazaar stall with welcoming signage and a polished pickup counter |

Art direction: a Malaysian Ramadan bazaar around late afternoon and dusk, warm lantern lighting, colourful kuih trays and a friendly community atmosphere. Keep the puzzle-board area calm and readable; crowds, bunting and decorative lighting belong around the edges.

Future implementation should use the shared location/structural-state system: Shop, My Gerai, gameplay wallpaper, Journey and applicable story/preview screens read the same state 0–3. Optional decor can personalise the stall without changing milestone progress. Recipes, customers, costs and rewards will be authored when this story enters production.

Status: **future playable content; preview implemented**. Ramadan Bazaar is registered in My Stalls with its own base wallpaper and shared modular upgrade components. Stages 181–210 remain unreleased; no artificial completion or unlock progress is granted.

---

# 11. Season 1 Overview

Suggested structure:

| Story | Stage Range | Milestone 1 | Milestone 2 | Milestone 3 |
|---|---:|---|---|---|
| Gerai Keluarga | 1–30 | Mula Bangkit | Kemas & Cantikkan Gerai | Kembangkan Bisnes |
| Kantin Sekolah | 31–60 | Percubaan Pertama | Jadi Kegemaran | Hari Kantin |
| Pasar Pagi | 61–90 | Cari Tapak | Tarik Pelanggan | Weekend Market |
| Pekan | 91–120 | Supply Kedai Kopi | Tempahan Pejabat | Festival Pekan |
| Bandar | 121–150 | Pop-up Booth | Corporate Orders | City Food Festival |
| Festival Kuih Kita | 151–180 | Persiapan Festival | Festival Days | Grand Finale |

Season 1 target:

# 180 Stages

This is a long-term content target.

The game does **not** need all 180 stages before MVP release.

---

# 12. Recommended Release Strategy

## MVP

Story 1 only:

**Stage 1–30**

This validates:

- Match-3
- customer system
- Story pacing
- milestone progression
- Gerai progression
- Stars
- Coins
- Hearts
- Specials
- route UI

---

## Content Expansion

### v0.2
Story 2  
Stage 31–60

### v0.3
Story 3  
Stage 61–90

### v0.4+
Continue expanding Story by Story.

This makes development manageable.

---

# 13. Route Map UI

Route map must support **scrollable journey progression**.

The map should show:

- stage nodes
- completed stages
- stars earned
- current stage
- locked future stages
- milestone marker
- Story / location sections

Example:

```text
GERAI KELUARGA

●1 ─ ●2 ─ ●3 ─ ... ─ ★10
                        │
                  MULA BANGKIT

●11 ─ ●12 ─ ... ─ ★20
                   │
             KEMAS GERAI

●21 ─ ●22 ─ ... ─ ★30
                   │
             STORY FINALE
                   ↓
             NEXT LOCATION
                   ↓
           KANTIN SEKOLAH
```

---

# 14. Scroll View Behaviour

Use a vertically scrollable route.

Recommended behavior:

- open map centered near current stage
- player can scroll backward to replay old levels
- future locked section remains visible
- milestone areas visually change background
- Story transition has a stronger visual divider

Possible environments:

```text
Gerai
  ↓
Kampung
  ↓
Sekolah
  ↓
Pasar
  ↓
Pekan
  ↓
Bandar
  ↓
Festival
```

---

# 15. Stage Node States

Each route node should support:

## Completed

```text
Stage 3
⭐⭐⭐
```

## Completed but imperfect

```text
Stage 4
⭐⭐☆
```

## Current

- highlighted
- animated pulse
- "Here!" marker

## Available

- selectable
- no lock

## Locked

- muted
- lock icon

---

# 16. Milestone Nodes

Stage 10, 20 and 30 should visually stand out.

They may use:

- larger node
- flower / ribbon
- landmark icon
- Gerai icon
- special glow
- badge

Example:

```text
★ 10
GERAI SIGNBOARD

★ 20
GERAI UPGRADE

★ 30
STORY FINALE
```

---

# 17. Story Transition

After Stage 30:

1. Show result screen.
2. Show Story completion scene.
3. Apply major world progression change.
4. Award unlocks.
5. Reveal next location.
6. Transition route map to next Story.

Example:

```text
STORY COMPLETE
Gerai Keluarga

↓
NEW LOCATION

Kantin Sekolah
```

---

# 18. World Change Rule

Every 10 levels:

**Small-to-medium visible change**

Every 30 levels:

**Major location / Story change**

Example:

```text
Stage 1
Old Gerai

Stage 10
New Signboard

Stage 20
Better Counter + Awning

Stage 30
Fully Improved Gerai

Stage 31
New Location: School Canteen
```

This visual progression is a core part of the game reward loop.

---

# 19. Integration With Stars

Stars remain permanent progression.

Recommended:

```text
Stage Clear
→ 1–3 Stars
```

Stars can support milestone bonus rewards.

Example:

```text
Milestone 1

20 / 30 Stars
Reward Locked

24 / 30 Stars
Recipe Reward

30 / 30 Stars
Perfect Milestone Reward
```

Important:

Player should not need perfect stars to continue the main Story.

Completionist rewards can require higher star counts.

---

# 20. Integration With Hearts

Hearts control repeated puzzle attempts, not route access.

Rules:

- current unlocked stage remains available while player has Hearts
- failure consumes 1 Heart unless Free Play is active
- completed stages can be replayed
- replay uses the same Heart rules if the stage is failed

---

# 21. Integration With Specials

Before starting a selected stage:

```text
Select Stage
    ↓
Stage Preview
    ↓
Choose Pre-Level Specials
    ↓
START
```

Route screen may show currently owned Specials near the Start button.

Do not place Order details directly on the journey map unless needed.

The journey map's primary job is:

- navigation
- progression
- stage selection
- Story context

Detailed Order objectives belong in the Stage Preview / gameplay UI.

---

# 22. Story Content Density

Do not show full dialogue after every stage.

Recommended:

- short story beats every 3–5 stages
- larger scene at Stage 10
- larger scene at Stage 20
- major Story scene at Stage 30

This keeps pacing light.

---

# 23. Design Rule

Each Story should answer three questions:

### Milestone 1
> What is Aina trying to start?

### Milestone 2
> How does Aina improve or gain recognition?

### Milestone 3
> What challenge proves she is ready for the next step?

This gives each 30-stage Story a simple narrative arc.

---

# 24. Content Planning Template

Use this template for every future Story.

```text
STORY NAME:
LOCATION:
STAGE RANGE:

MILESTONE 1:
Stages:
Narrative Goal:
New Mechanic:
Visual Change:
Reward:
Stage 10 Challenge:

MILESTONE 2:
Stages:
Narrative Goal:
New Mechanic:
Visual Change:
Reward:
Stage 20 Challenge:

MILESTONE 3:
Stages:
Narrative Goal:
New Mechanic:
Visual Change:
Reward:
Stage 30 Finale:

NEXT STORY:
NEXT LOCATION:
```

---

# 25. Technical Data Model Suggestion

Each Story can use:

```text
StoryDefinition

id
display_name
location_id
start_stage
end_stage
milestones
background_states
story_scenes
unlock_conditions
next_story_id
```

Each Milestone:

```text
MilestoneDefinition

id
story_id
start_stage
end_stage
display_name
world_state
reward
final_stage
```

Each Stage remains data-driven using existing `LevelDefinition`.

---

# 26. MVP Technical Priority

For Story 1, implement support for:

1. 30 Stage route
2. 3 milestone markers
3. stage unlock progression
4. stars per stage
5. scroll-to-current-stage
6. replay completed stage
7. Story milestone rewards
8. world-state changes
9. Stage 30 next-location unlock
10. Stage Preview + Specials selection

---

# 27. Locked Design Summary

Kuih Empire progression is now officially:

```text
JOURNEY
  ↓
STORY / CHAPTER
  ↓
3 MILESTONES
  ↓
10 STAGES EACH
```

Therefore:

```text
1 Story = 30 Stages
1 Milestone = 10 Stages
3 Milestones = 1 Complete Story
```

Key rules:

- visible progression every 10 levels
- major Story/location change every 30 levels
- meaningful reward at each milestone
- stage route is scrollable
- Stage 10, 20 and 30 are special challenge points
- route navigation remains separate from detailed Order UI
- Story 1 MVP = Gerai Keluarga
- Story 2 = Kantin Sekolah
- future Stories follow the same structure

---

## Design Mantra

> **Every 10 stages, something changes.  
> Every 30 stages, Aina takes a bigger step forward.**
