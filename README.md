# KUIH EMPIRE
### Malaysian Cozy Food Puzzle Adventure

> Simple puzzle. Beautiful food. Meaningful progression. Malaysian soul.

A 2D portrait mobile match-3 game built in **Godot 4.3 / GDScript**, following
`Kuih_Empire_Master_Plan_v1.0.md`. Aina takes over her family's kuih stall, serves
customers, fills her recipe book, upgrades the gerai and works her way across
Malaysia.

**Tagline: Match. Serve. Grow.**

---

## Running it

Open the folder in **Godot 4.3+** and press F5. The main scene is
`res://scenes/boot/boot.tscn`.

* Design resolution: `1080 x 1920` portrait, `canvas_items` stretch, `keep` aspect.
* Renderer: **GL Compatibility** (chosen for low-end Android coverage).
* Mouse is emulated as touch, so the game is fully playable on desktop.

### Verification harnesses

The harnesses are runnable and use only project code.

Current audit and MVP priorities: [MVP_STATUS.md](MVP_STATUS.md).

```bash
# Rules, board invariants, specials, obstacles + a 30-stage balance report
godot --headless --script res://tools/test_runner.gd

# Builds every screen, plays real swaps, fires every booster (needs a GL context
# for the _draw paths to actually execute)
godot --rendering-driver opengl3 res://tools/smoke_scene.tscn

# Regression checks: results, story navigation, boosters, serving and finale
godot --headless res://tools/regression_scene.tscn

# Save round trip, malformed data, backup recovery, reset and write failure
godot --headless res://tools/persistence_scene.tscn

# Renders every screen to res://.shots/*.png for art review
godot --rendering-driver opengl3 --resolution 540x960 res://tools/screenshot_scene.tscn
```

`test_runner.gd` plays every stage with a greedy bot that only chases the current
order, so the reported win rate is a **floor**, not a prediction of human skill.

`find_layout.gd` is a small authoring tool, not a test: it generates and verifies
board layouts for a target size so hand-authored tutorial stages are known to be
solvable instead of guessed at.

---

## First-run flow

```
Splash → Prologue (story) → Tutorial T1-T8 → Home → campaign stages 1-30
```

The **storyline** and the **tutorial** are two separate steps, in that order, and
neither one renumbers the campaign. `StoryScreen` shows a short multi-page
prologue; `Skip` only appears once the player has actually read it, and the whole
thing stays reachable afterwards from Home and the Journey Map.

The **tutorial** is its own flow of 8 stages, not stage 1-8 of the campaign. The
board grows one step at a time so the player learns each idea at the size where it
is easiest to see:

| Stage | Board | Teaches |
|---|---|---|
| T1 | 3x3 | swipe up and down |
| T2 | 3x3 | swipe left and right |
| T3 | 3x3 | collect, and your first customer |
| T4 | 4x4 | match 4 to make a Tapau Pack |
| T5 | 5x5 | L and T shapes make a Dulang |
| T6 | 6x6 | banana leaf covers |
| T7 | 7x7 | the steamer and the queue |
| T8 | 8x8 | the real tray |

Three rules make the tutorial safe rather than a wall:

* **It cannot be lost.** Every tutorial stage is unwinnable-to-lose (`allow_fail`
  is off) and always awards three stars. The stage ends when the goal is met, not
  when the moves run out.
* **Input is never locked.** A wrong-direction swap still happens and still
  bounces; the coach reacts with a corrective hint instead of refusing the input.
  A player who ignores the lesson can still finish, they just get nudged.
* **It cannot soft-lock.** The harness proves every stage has at least one legal
  move and that the move the coach asks for actually exists, so the coach can
  always be satisfied.

`test_runner.gd` prints a per-stage report for all eight, including an
`achievable n/4` score, so a layout regression shows up as a number rather than as
a player complaint.

---

## What is implemented

| Master plan phase | Status |
|---|---|
| **1 - Core puzzle** (grid, swap, match, cascade, refill, moves, win/lose, restart) | Done |
| **2 - Kuih system** (specials, combos, blockers, particles, game feel) | Done |
| **3 - Customer order system** (queue, counter, serve, surplus carry-over) | Done |
| **4 - Meta game** (journey map, stars, recipe book, gerai, story, unlocks) | Done |
| **5 - Content** (30 curated stages, tutorial flow, difficulty curve, story beats, chapter finale) | Done |
| **6 - Polish** (particles, transitions, synthesised audio, haptics) | Done, procedural art only |
| **7 - Monetisation** (ads, IAP, remove ads) | Stubbed, deliberately last per plan |
| **8 - Soft launch / analytics** | Not started |

### Core loop

```
Match → Serve → Earn → Upgrade → Discover → Travel → Repeat
```

### Match mechanics (plan section 15)

* **Match 3** - basic collection.
* **Match 4** → **Tapau Pack** - clears a full row *and* column.
* **L / T** → **Dulang** - clears a 3x3 area.
* **Match 5** → **Special Order** - collects every tile of one kuih type.
* Combos: Tapau+Tapau, Dulang+Tapau, Special Order+kuih, Special Order+Special
  Order (full board wipe).

### Obstacles (plan section 18)

| Blocker | Rule |
|---|---|
| Banana Leaf | Opened by matching beside it |
| Food Cover | Two layers, one per neighbouring match |
| Steamer | Opened by matching beside the basket |
| Sticky Syrup | Cell cannot be swapped until cleaned |
| Packaging Box | Needs N of one kuih type to fill |
| Empty Tray | Needs N of one kuih type to fill |

### Boosters (plan section 38)

Sudip (scoop one), Dulang (scoop 3x3), Shuffle, Tapau (auto-collect the order),
+5 Moves. Failing always offers a **free** +5 moves - the paid option is never
forced (plan sections 44 and 45).

---

## Project structure

```
res://
├── project.godot              # 1080x1920 portrait, gl_compatibility, autoloads
├── icon.svg
│
├── scenes/
│   ├── boot/boot.tscn                 # splash
│   ├── story/story_screen.tscn        # prologue pages + chapter decks
│   ├── menu/home.tscn                 # hub
│   ├── game/level_screen.tscn         # gameplay
│   ├── world/journey_map.tscn
│   ├── stall/gerai_screen.tscn
│   └── ui/                            # recipe book, settings
│
├── scripts/
│   ├── core/                          # autoloads
│   │   ├── game_manager.gd            #   session hub + input map
│   │   ├── scene_manager.gd           #   navigation with fades
│   │   ├── save_manager.gd            #   local JSON save, debounced
│   │   ├── progression_manager.gd     #   stars, chapters, recipes, gerai
│   │   ├── economy_manager.gd         #   coins + boosters
│   │   └── audio_manager.gd           #   sfx pool, music, haptics
│   │
│   ├── data/                          # resources, never image filenames
│   │   ├── kuih_data.gd               #   12 kuih, shape drives the art
│   │   ├── kuih_library.gd
│   │   ├── customer_data.gd           #   6 archetypes
│   │   ├── customer_library.gd
│   │   ├── order_item.gd
│   │   ├── customer_order_spec.gd
│   │   ├── objective_spec.gd
│   │   ├── blocker_spec.gd
│   │   ├── level_definition.gd
│   │   ├── story_beat.gd                #   in-level dialogue beats
│   │   ├── story_page.gd                #   one story page
│   │   └── tutorial_step_data.gd        #   coach step + gate enum
│   │
│   ├── board/                         # match-3 engine
│   │   ├── board_cell.gd              #   tile + special + obstacle state
│   │   ├── board_state.gd             #   PURE rules, zero nodes/tweens
│   │   ├── match_board.gd             #   input + animation pipeline
│   │   ├── tile_view.gd
│   │   └── overlay_view.gd
│   │
│   ├── gameplay/
│   │   ├── level_controller.gd        # orders, moves, boosters, win/lose
│   │   ├── customer_order.gd          #   surplus carries to the next guest
│   │   └── tutorial_coach.gd          #   soft hints, never locks input
│   │
│   ├── levels/
│   │   ├── level_library.gd           #   the 30 stages + .tres exporter
│   │   └── tutorial_library.gd        #   T1-T8, layouts verified by find_layout.gd
│   │
│   ├── story/
│   │   ├── story_screen.gd            #   paged reader, skip/replay
│   │   ├── story_library.gd           #   prologue pages + chapter decks
│   │   └── beat_library.gd            #   in-level beats, separate from pages
│   │
│   ├── art/                           # procedural placeholder art
│   │   ├── kuih_icon.gd               #   one distinct silhouette per kuih
│   │   ├── character_icon.gd          #   Aina, Ibu, Farah, Daniel, customers
│   │   └── board_art.gd               #   blockers + special tiles
│   │
│   ├── ui/
│   │   ├── palette.gd                 #   colour language
│   │   ├── ui_kit.gd                  #   theme, wood buttons, cards
│   │   ├── hud.gd
│   │   ├── order_panel.gd
│   │   ├── booster_bar.gd
│   │   ├── result_overlay.gd
│   │   ├── story_popup.gd
│   │   ├── tutorial_hint.gd
│   │   ├── coin_display.gd
│   │   ├── star_display.gd
│   │   └── *_screen.gd                #   home, journey, recipe book, gerai, settings
│   │
│   └── audio/sfx_synth.gd             # every sound generated at boot
│
├── tools/                             # not shipped in the build
│   ├── test_runner.gd                 # rules + tutorial gates + 30-stage balance report
│   ├── smoke_test.gd / smoke_scene.tscn
│   ├── find_layout.gd                 # authoring: generate + verify board layouts
│   └── screenshot_tool.gd / screenshot_scene.tscn
│
├── resources/                         # .tres export target for the level editor
├── assets/                            # final art drop-in folders
└── audio/                             # music/sfx drop-in folders
```

### Why scenes are thin

Every `.tscn` is a single root node plus a script. The layout is built in code
because the whole UI is generated from one shared theme - this keeps the art
direction in exactly one place (`palette.gd` / `ui_kit.gd`) and makes every screen
re-skin from a single edit.

### Signals are wired in code, not in the .tscn

Because the scenes are this thin, nothing is connected in the editor. Every
screen wires its own outgoing signal in `_ready()` - `StoryScreen` connects
`finished` to `SceneManager.finish_story()` and reads its deck from
`SceneManager.story_group`.

That makes a missing connection invisible at a glance: the screen still builds,
still draws, and only fails when the player presses a button. `StoryScreen` once
shipped exactly that way - it rendered a blank card whose Continue and Skip both
did nothing, stranding the player on the prologue forever.

Two rules keep that from happening again:

* A screen never navigates on its own. It emits, and `SceneManager` decides where
  that goes. An empty or unknown deck makes the screen inert rather than making it
  fire `finished`, so opening a scene by hand cannot hijack navigation.
* `smoke_test.gd` walks the deck to the exit button instead of just building it
  (`story deck walked ok (3 pages)`). Building a screen proves nothing about
  whether its buttons do anything.

---

## Notable design decisions

**`BoardState` is node-free.** No tweens, no timers, no signals. It returns
resolution steps and the view plays them. This is what lets the headless harness
play thousands of levels per second, and it is why gameplay and monetisation code
never touch each other (plan section 55).

**The view is keyed by cell, and `from` is not `to`.** `MatchBoard` keeps one
`TileView` per occupied cell. Gravity returns a `FallMove` with `from` (the cell
the kuih is leaving) and `to` (where it lands), and the view must be looked up by
`from`. Reading it by `to` grabs an empty cell, erases the real entry and orphans
the falling tile - the cell then renders blank and the next refill stacks a second
kuih on top of the stranded one. `smoke_test.gd` asserts the invariant directly:
one view per occupied cell, and no view node the board has forgotten about.

**The board is bamboo, not green.** An early pass used green cells, and green kuih
(onde-onde, ketayap) vanished into them. Warm cream slots make every food colour
read instantly at a glance - the single biggest readability win in the project.

**One silhouette per kuih.** Circle (onde-onde), slab (kuih lapis), pyramid
(seri muka), diamond (ketayap), flower (ang ku kueh), cluster (vadai), dome in
cup (penyaram), nest (kuih cina), slices (acar), block (dodol), flower in leaf cup
(kuih kukus), ring (kuih goreng). The art rule is that a player knows the kuih from
a tiny tile alone.

**Art stays food.** No eyes, mouths, hands or feet on any kuih - the locked rule
from the character board. Humans carry all the emotion.

**Surplus kuih carries to the next customer.** If a match completes the current
order and overfills it, the extra goes to whoever is next in the queue. The player
is never punished for a good cascade.

**Cultural wording is careful.** Recipe notes use "Popular in..." / "Commonly
found across..." and never claim an origin the plan does not have a source for
(plan section 23).

**Never write `a.kuih = b.kuih`.** GDScript 4.3 fails member lookup when the
property name on the left of an assignment also appears on the right, and it fails
*silently* at runtime - `Invalid assignment of property or key 'kuih'` once per
tile, every frame, with the game still otherwise looking fine. It bit three
separate bugs at once (`apply_layout`, gravity fallbacks, and `TileView` icons all
rendered empty tiles for a while). The rule is always to hoist the right-hand side
into a differently named local first:

```gdscript
var carried: KuihData = source.kuih
target.kuih = carried
```

`board_state.gd` follows this everywhere, including inside dictionary literals that
use `"kuih"` as a key. If a tile ever renders blank again, grep for `\.kuih\s*=`
first.

---

## Balance snapshot

Greedy bot, 8 seeds per stage, difficulty curve from the plan's
teach / practice / combine / challenge / relax cycle:

| Stages | Win rate |
|---|---|
| 1-19 (prologue + Kuching) | 75-100% |
| 20-30 (challenge + finale) | 75-100% |
| **Overall** | **95%**, no stage below 75% |

---

## Next steps

1. **Final kuih art** - put each approved PNG in `assets/kuih/` using its data ID
   (`onde_onde.png`, `kuih_lapis.png`, `seri_muka.png`, `kuih_ketayap.png`,
   `ang_ku_kueh.png`, `vadai.png`), let Godot import it, and restart the game.
   `KuihLibrary` loads these textures automatically; missing files retain the
   procedural fallback. The special sprite integration remains a separate task.
2. **In-game level editor** (`@tool`) - `LevelLibrary.export_all()` already writes
   `resources/levels/level_XXX.tres` so stages can be hand-tuned.
3. **Audio pass** - real music and foley into `audio/`.
4. **Monetisation** - rewarded ads first, then limited interstitials, then IAP.
   `ResultOverlay` already has the free-option-first flow wired.
5. **Analytics** - the events are already counted in `ProgressionManager.stats()`.

### Temporary logo and gameplay pause

The supplied logo is copied without modification to `assets/ui/logo_temp.png`
and displayed with preserved proportions on Boot and Home. The original remains
in `design/`.

The level pause menu freezes board tweens and serve timers, prevents duplicate
menus and blocks restart/booster actions. Resume continues the current animation;
Quit returns to Home without leaving the scene tree paused. Application background
notifications pause an active level and flush pending save data. Actual Android
suspend/resume still needs a device test.

Local saves validate nested values, write a temporary file before replacement,
and retain the previous good save as a `.bak`. A corrupt primary loads the backup;
Reset Progress replaces both copies with a fresh game. Failed writes keep pending
data dirty for another flush.
