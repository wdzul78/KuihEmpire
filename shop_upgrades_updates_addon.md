> Implemented policy after the user clarification: one base wallpaper per location, purchased structural layers and purchased/equipped accessories. Milestones unlock purchases; coin payment applies the visual change. Stage progress continues without requiring those purchases. See `design/Modular_Stall_Implementation.md` for the delivered architecture, costs, migration and remaining future content.

You are working on the existing Godot 4.x project:

KUIH EMPIRE

Before modifying code, inspect the current implementation of:

- Journey / Story progression
- Milestones
- Stage progression
- Shop
- Stall / Gerai UI
- Gameplay scene
- Gameplay background / wallpaper
- Save data
- Coins
- Stars
- Equipped cosmetics
- any existing location/world-state system

Do NOT assume the architecture.

First audit the current code and identify which systems already exist.

==================================================
OBJECTIVE
==================================================

Update Kuih Empire so that STALL STRUCTURAL UPGRADES are not only visible inside the Shop / My Gerai screen.

Structural Stall Upgrades must also directly change the gameplay wallpaper/background used during puzzle stages.

The game should visually reflect the player's Journey progression.

Core rule:

EVERY 10 STAGES
→ current stall/location visually progresses

EVERY 30 STAGES
→ current Story/location reaches its completed state
→ next Story/location becomes available

This progression must be shared consistently across:

- Journey
- Story
- Shop
- My Gerai
- Gameplay
- Story scenes
- Stage preview where applicable

==================================================
1. LOCKED PROGRESSION STRUCTURE
==================================================

Current progression structure:

Journey
→ Story / Chapter
→ 3 Milestones
→ 10 Stages per Milestone

1 Story = 30 Stages

Example:

STORY 1 — GERAI KELUARGA

Stage 1–10
Milestone 1:
Mula Bangkit

Stage 11–20
Milestone 2:
Kemas & Cantikkan Gerai

Stage 21–30
Milestone 3:
Kembangkan Bisnes

After Stage 30:
Gerai Keluarga is complete
Next Story/location unlocks

Example next Story:

Kantin Sekolah

==================================================
2. STRUCTURAL UPGRADE RULE
==================================================

Structural Stall Upgrade is a STORY / PROGRESSION feature.

It must NOT behave like ordinary cosmetic equipment.

Structural upgrades affect:

- stall structure
- counter
- awning
- shelves
- display cabinet
- signage
- lighting
- wall treatment
- background architecture
- preparation area
- customer pickup area
- general ambience

They create a noticeable visual transformation.

Example Story 1:

STRUCTURAL STATE 0
Stage 1 start

Gerai Lama

- old counter
- basic awning
- minimal display
- simple lighting
- sparse decoration

--------------------------------

STRUCTURAL STATE 1
After Stage 10

Gerai Bangkit

- cleaned counter
- new signboard
- improved trays
- repaired surfaces
- better lighting

--------------------------------

STRUCTURAL STATE 2
After Stage 20

Gerai Berseri

- improved awning
- shelving
- better display
- plants
- packaging area
- warmer lighting

--------------------------------

STRUCTURAL STATE 3
After Stage 30

Gerai Keluarga Baru

- complete stall
- larger counter
- proper display cabinet
- branded Kuih Empire signage
- improved preparation area
- customer pickup section
- polished lighting and decor

==================================================
3. GAMEPLAY BACKGROUND MUST FOLLOW STALL STATE
==================================================

The puzzle gameplay screen must load the current structural visual state.

Example:

Player is currently in Story 1.

If highest completed stage = 7:

Gameplay background:
Gerai State 0

If Stage 10 completed:

Gameplay background:
Gerai State 1

If Stage 20 completed:

Gameplay background:
Gerai State 2

If Stage 30 completed:

Gerai State 3

The player must immediately notice that their environment has improved.

==================================================
4. NEW STORY / LOCATION
==================================================

When the player moves into Story 2:

Gameplay background changes to the new Story location.

Example:

Story 2
Kantin Sekolah

The school canteen has its own:

structural_state_0
structural_state_1
structural_state_2
structural_state_3

Stages:

31–40
School Canteen State 0

After Stage 40:
State 1

After Stage 50:
State 2

After Stage 60:
State 3

Then next location.

==================================================
5. DO NOT USE ONE STATIC GAMEPLAY BACKGROUND
==================================================

Refactor if the gameplay background currently uses:

one hardcoded TextureRect / Sprite

or:

one static wallpaper file.

The background system should be data-driven.

Suggested concept:

GameplayEnvironment

location_id
structural_state
equipped_decor

Example:

location_id:
gerai_keluarga

structural_state:
2

equipped_decor:
[
    hibiscus_sign,
    rattan_lamp,
    pastel_tray
]

==================================================
6. STRUCTURAL VS DECOR
==================================================

Maintain a strict distinction.

STRUCTURAL UPGRADE
= progression

DECOR
= personalisation

--------------------------------

STRUCTURAL:

Unlocked through:

Journey
Milestones
Stars
Story progress
Coins where required

Examples:

counter layout
awning
cabinet
wall
lighting structure
major signage
stall expansion

--------------------------------

DECOR:

Player selectable.

Examples:

flowers
small plants
menu boards
lamps
table cloth
small signs
trays
wall art
family photo
recipe frame
small ornaments

Decor must not alter progression.

==================================================
7. SHOP STRUCTURE
==================================================

Recommended Shop sections:

STALL
DECOR
AINA
SUPPLIES

STALL tab:

Shows structural progression.

Example:

GERAI KELUARGA

Upgrade 2 / 3
66%

[Current Stall Preview]

Next Upgrade:
Gerai Berseri

Requirements:

✓ Stage 20 Complete
✓ 45 Stars
1500 Coins

[ UPGRADE ]

--------------------------------

DECOR tab:

Player can:

Preview
Buy
Equip
Unequip

==================================================
8. STRUCTURAL UPGRADE REQUIREMENTS
==================================================

Use data-driven requirements.

Example Story 1:

UPGRADE 1

Unlock:
Stage 10 Complete

Suggested requirement:

20 Stars
800 Coins

--------------------------------

UPGRADE 2

Unlock:
Stage 20 Complete

Suggested requirement:

45 Stars
1500 Coins

--------------------------------

UPGRADE 3

Unlock:
Stage 30 Complete

Suggested requirement:

75 Stars
2500 Coins

These numbers are starting values only.

Do not hardcode them globally.

==================================================
9. IMPORTANT STORY PROGRESSION RULE
==================================================

Do not allow Coins alone to skip Story progression.

A player must first reach the relevant Milestone.

Example:

Even if player has 10,000 Coins:

Upgrade 2 must remain locked if Stage 20 has not been completed.

Progression requirement:

Story progress
+
Star requirement
+
Coin cost

==================================================
10. WORLD STATE
==================================================

Introduce or reuse a shared world-state representation.

Possible:

LocationState

location_id
structural_level
completion_percent

Example:

gerai_keluarga:
structural_level = 2

kantin_sekolah:
structural_level = 0

The gameplay scene and Shop must read from the SAME state.

Do not duplicate progression logic.

==================================================
11. DATA-DRIVEN LOCATION DEFINITION
==================================================

If no equivalent exists, consider:

LocationDefinition

Fields:

id
display_name
story_id
stage_start
stage_end

structural_states

upgrade_requirements

background_scene
background_layers

available_decor_slots

Example:

LocationDefinition:
gerai_keluarga

State 0:
old_stall

State 1:
revived_stall

State 2:
polished_stall

State 3:
completed_stall

==================================================
12. PREFERRED BACKGROUND ARCHITECTURE
==================================================

Avoid making every state one giant completely separate hardcoded gameplay scene unless necessary.

Prefer modular composition where practical.

Example:

GameplayBackground
├── BaseEnvironment
├── StructuralLayer
├── CounterLayer
├── SignageLayer
├── LightingLayer
├── DisplayLayer
├── DecorLayer
├── ForegroundProps
└── AmbientEffects

Structural state can determine which layers/assets are active.

Decor slots can overlay cosmetic items.

==================================================
13. ART IMPLEMENTATION FLEXIBILITY
==================================================

Support either:

A. modular layer assets

or

B. full pre-rendered background state images

depending on the art pipeline.

The code architecture should support both.

Example:

BackgroundStateDefinition

mode:
FULL_TEXTURE
or
LAYERED

If FULL_TEXTURE:
background_texture

If LAYERED:
layer configuration

Do not force the art team into only one approach.

==================================================
14. DECOR SLOTS
==================================================

Suggested optional decor slots:

SIGNBOARD
AWNING_ACCENT
LIGHTING_1
LIGHTING_2
PLANT_1
PLANT_2
COUNTER_DECOR
WALL_DECOR_1
WALL_DECOR_2
DISPLAY_ACCENT

Not every location must support every slot.

LocationDefinition should configure available slots.

==================================================
15. GAMEPLAY READABILITY
==================================================

Gameplay readability is more important than showing every decor.

The puzzle board must remain visually dominant.

During gameplay:

- reduce background contrast if required
- reduce saturation behind puzzle board
- use subtle blur / darkening overlay if needed
- hide decor that visually overlaps puzzle tiles
- keep customer/order UI readable

The Stall preview screen may show full visual detail.

Gameplay may use a slightly simplified version of the same stall state.

==================================================
16. STAGE PREVIEW
==================================================

If Stage Preview currently exists:

it may show:

- current location
- current Stall state
- selected Specials
- Start button

Do NOT duplicate detailed Shop controls here.

==================================================
17. UPGRADE CEREMONY
==================================================

When a structural upgrade is completed:

show a short upgrade sequence.

Suggested:

OLD STALL
↓
small hammer / sparkle transition
↓
screen wipe
↓
NEW STALL

Then:

STALL UPGRADED!

Show:

Before
→
After

Aina may perform a celebration animation.

Duration should remain short.

Suggested:
2–4 seconds.

==================================================
18. WORLD CHANGE AFTER MILESTONE
==================================================

After each 10-stage milestone:

1. complete Stage result
2. save milestone completion
3. unlock Stall upgrade
4. player purchases/completes upgrade if required
5. update shared LocationState
6. refresh Shop preview
7. refresh gameplay wallpaper
8. refresh relevant Story scenes

If the upgrade is mandatory for Story progression:

document that clearly.

If optional purchase is allowed:

ensure Journey progression rules remain coherent.

==================================================
19. RECOMMENDED DESIGN DECISION
==================================================

Preferred behavior:

Milestone completion unlocks the upgrade.

Player then spends required Coins to complete it.

However:

the player should NOT become permanently blocked from Story progression because they spent Coins elsewhere.

Evaluate whether:

A. structural upgrades are automatically awarded after requirements

or

B. Coin costs are low enough to guarantee practical progression

or

C. Story continues while upgrade remains available

Audit current economy before deciding.

Do not introduce an accidental economy deadlock.

==================================================
20. STALL COMPLETION
==================================================

Each location should have its own structural completion.

Example:

GERAI KELUARGA

Structural Upgrades:
2 / 3

Completion:
66%

Decor Collection:
7 / 12

Story:
20 / 30

Important:

Structural completion and decor completion are separate.

100% structural completion must NOT require purchasing every cosmetic.

==================================================
21. MY STALLS
==================================================

Prepare architecture for future multiple locations.

Example:

MY STALLS

Gerai Keluarga
100%

Kantin Sekolah
66%

Pasar Pagi
Locked

Pekan
Locked

Bandar
Locked

Previous locations remain accessible after progressing.

==================================================
22. SAVE DATA
==================================================

Do not duplicate data already available.

Possible additions:

location_states:
{
  gerai_keluarga:
  {
    structural_level: 3,
    equipped_decor: [...]
  },

  kantin_sekolah:
  {
    structural_level: 1,
    equipped_decor: [...]
  }
}

Persist:

- structural upgrade state
- owned decor
- equipped decor
- stall completion
- selected customization

==================================================
23. GAMEPLAY BACKGROUND LOADING FLOW
==================================================

Suggested:

Stage selected
    ↓
Read StageDefinition
    ↓
Resolve Story
    ↓
Resolve Location
    ↓
Load LocationState
    ↓
Resolve Structural State
    ↓
Apply Equipped Decor
    ↓
Render Gameplay Background
    ↓
Start Puzzle

==================================================
24. SIGNALS
==================================================

Possible signals:

stall_upgrade_unlocked(location_id, level)

stall_upgraded(location_id, level)

decor_equipped(location_id, slot, decor_id)

decor_unequipped(location_id, slot)

location_state_changed(location_id)

Gameplay background should respond cleanly to state changes.

==================================================
25. SHOP PREVIEW
==================================================

The Shop needs preview functionality.

Player selects item:

[ PREVIEW ]

Show item temporarily.

Actions:

BUY
EQUIP
CANCEL

Do not modify save data until purchase/equip is confirmed.

==================================================
26. COINS
==================================================

Coins remain:

SPENDABLE CURRENCY

Used for:

- Stall upgrades
- Decor
- Boosters
- Specials
- Heart refill
- selected cosmetics

Stars remain:

PROGRESSION

Do not use Stars as consumable currency.

==================================================
27. ACHIEVEMENT INTEGRATION
==================================================

Structural progression can trigger achievements.

Examples:

First Renovation

Complete the first Stall upgrade.

--------------------------------

Gerai Keluarga Complete

Complete all 3 structural upgrades.

--------------------------------

Kuih Empire Builder

Complete multiple locations.

Rare decor can also be achievement rewards.

==================================================
28. GAMEPLAY PERFORMANCE
==================================================

Background composition must be optimized for mobile.

Avoid:

- unnecessarily large textures loaded simultaneously
- hidden full-resolution state assets remaining in memory
- excessive animation
- expensive shader effects

Unload previous location/state resources where appropriate.

==================================================
29. FALLBACK
==================================================

If a specific structural asset is missing:

do not crash.

Fallback:

- nearest valid structural state
or
- location default

Log a warning for development builds.

==================================================
30. DEBUG TOOLS
==================================================

Provide a development/debug method to preview:

location
structural state
decor combination

without playing 30 stages.

Example development controls:

Gerai Keluarga
State:
0 / 1 / 2 / 3

This is important for art and UI testing.

Do not expose debug controls in production.

==================================================
31. TEST CASES
==================================================

CASE A

New player
Stage 1

Expected:
Gerai State 0 gameplay background

--------------------------------

CASE B

Stage 10 milestone completed
Upgrade 1 completed

Expected:
Gerai State 1 appears in:
Shop
Gameplay
Story background where applicable

--------------------------------

CASE C

Stage 20 upgrade completed

Expected:
State 2 everywhere

--------------------------------

CASE D

Stage 30 upgrade complete

Expected:
Gerai State 3
100% structural completion

--------------------------------

CASE E

Story 2 Stage 31

Expected:
School Canteen State 0

--------------------------------

CASE F

Player equips Hibiscus Decor

Expected:
visible in Shop preview
visible in gameplay if slot is gameplay-safe

--------------------------------

CASE G

Player changes Decor

Expected:
structural level does not change

--------------------------------

CASE H

Player lacks milestone progression but has enough Coins

Expected:
future Structural Upgrade remains locked

==================================================
32. DELIVERY PROCESS
==================================================

Before coding:

Provide an audit:

1. Current Shop architecture
2. Current Stall system
3. Gameplay background implementation
4. Journey / Milestone implementation
5. Save data
6. Coin and Star systems
7. Existing customization support

Then provide:

IMPLEMENTATION PLAN

Identify:

- systems to reuse
- files to modify
- new resources/classes needed
- migration needs
- asset placeholders needed

Then implement.

==================================================
33. DELIVERY REPORT
==================================================

After implementation provide:

1. Files changed
2. New files
3. New data resources
4. Stall state architecture
5. Gameplay background loading flow
6. Shop changes
7. Save data changes
8. Milestone integration
9. Decor integration
10. Debug tools
11. Tests performed
12. Remaining art placeholders / TODOs

==================================================
FINAL DESIGN RULE
==================================================

Kuih Empire must follow:

JOURNEY
determines where Aina is.

MILESTONE
determines when the Stall evolves.

STRUCTURAL UPGRADE
changes the world.

DECOR
personalises the world.

SHOP
lets the player manage upgrades and customization.

GAMEPLAY
must visually reflect the player's current Stall.

Therefore:

Every 10 stages, something visibly changes.

Every 30 stages, Aina moves into a larger chapter of her journey.

The player's Kuih Empire should be visible behind the puzzle board — not only inside a menu.

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
