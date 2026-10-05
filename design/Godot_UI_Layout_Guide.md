# Editing the gameplay layout in Godot

The gameplay and tutorial layouts now come from named editor scenes. Existing image files keep their paths so imports and references remain valid.

## Open these scenes in Godot's FileSystem panel

- `res://scenes/layout/tutorial_gameplay_layout.tscn`: tutorial layout.
- `res://scenes/layout/campaign_gameplay_layout.tscn`: normal gameplay layout.

Select a named node in the Scene tree, then move/resize it in the 2D editor or edit **Inspector > Layout > Transform**. Save with Ctrl+S and run the game again. Anchors scale with the portrait viewport; offsets provide pixel adjustments in the 1080 x 1920 design canvas. Keep the root canvas size unchanged.

| Node | Purpose |
| --- | --- |
| Logo | Kuih Empire logo |
| HeartMeter | Heart status bar |
| ScoreMeter | Score and progress area |
| PauseButton | Settings/pause button |
| StageTitleFrame / StageTitle | Tutorial title frame and stage name |
| HintButton | Hint control |
| MovesPanel | Remaining moves (campaign only) |
| LessonBadge | Lesson badge (tutorial only) |
| CustomerQueue | Waiting customer thumbnails |
| OrderArea | Parent region for characters, dialogue and order |
| OrderArea/DialogueBubble | Speech bubble position and size |
| DialogueBubble/SpeakerName | Speaker/tutorial heading font size |
| DialogueBubble/InstructionText | Dialogue font size |
| OrderArea/CustomerCharacter | Customer size and position |
| OrderArea/AinaCharacter | Aina size and position |
| OrderArea/OrderBoard | Order card position and size |
| OrderBoard/OrderTitle | Order title layout/font size |
| OrderBoard/KuihItems | Area used by food icons, names and counts |
| PuzzleBoard | Match board area; cells remain square |
| SpecialItemsTray | Booster tray position and size |

The runtime tree uses the same names under `LevelScreen/GameplayHUD`. Special buttons are named `SpatulaButton`, `TrayButton`, `ShuffleButton`, and `TapauButton`; individual order entries use `Kuih_<id>/KuihIcon`, `KuihName`, `KuihBacking`, `RemainingCountBadge/OrderCount`, and `OrderCompletedTick`. The number badge shows the remaining quantity; a green graphical tick replaces it when that kuih is fulfilled.

## What is editable

Both scenes are the source of truth for the named gameplay rectangles, score label rectangles/font sizes, move label rectangles/font sizes, order title and dialogue font sizes. Choose a different layout scene through **LevelScreen > Inspector > Editable UI Layout** if you want a separate variant.

The scene artwork and sample text help you position the layout. Dynamic order contents, score/progress drawing, customer selection, tutorial copy and inventory badges still come from game data. Changing a preview texture or sample text does not change game data or replace production artwork. Dialogue contents flow in a container, so their child positions in the preview are illustrative; their font sizes are applied. Special button labels/icons are automatic; moving `SpecialItemsTray` moves the whole tray.

Tutorial characters and dialogue keep the tutorial scene layout after the instruction gates finish, until the lesson ends. Completing a swipe does not switch to the campaign scene or shrink Aina. Explicitly leaving tutorial mode can still restore the campaign layout.

Character previews show the same body clearance/counter clipping as gameplay. Heads keep a safety gap under the dialogue body. Moving a character upwards into the dialogue can therefore be clamped; move the bubble or resize its area if you need more headroom.

Edit the saved layout scenes, not just the running **Remote** tree: Remote changes last only for that run. Keep the named nodes and parent hierarchy intact; they are the connection points used by `GameUILayout`.

## Artwork references

Each preview node's Tooltip lists its original image path, and scene resource IDs use names such as `Art_Aina`, `Art_Order`, and `Art_Bubble`. Most textures are under `assets/ui`, full-body characters under `assets/characters/fullbody_v2`, and booster illustrations under `assets/boosters`. There is no need to rename/move PNG files to arrange the UI.
