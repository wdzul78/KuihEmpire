# Cozy puzzle audio v2

Implemented 2026-10-05. The approved direction uses original soft pop/chime SFX and a CC0 puzzle music loop. Audio from Homescapes/Gardenscapes is not sampled.

## Music

Gameplay and tutorial now use `audio/music/cozy_puzzle_gameplay.ogg`: **Cozy Puzzle In-Game 3** by MintoDog, CC0. Source and processing information: `audio/licenses/Music_CC0.md`. The menu theme remains `menu.ogg`. The previous gameplay file `gameplay.ogg` remains available for comparison or rollback. Existing music crossfade, result ducking, mute and application pause continue to apply.

Source music was normalized at -16 LUFS and encoded OGG Vorbis quality 4. Runtime applies the existing -20 dB gameplay gain. Measured mean volume is -17.8 dBFS and sample peak -4.7 dBFS. The artist labels the 108 BPM track loopable; device listening still determines preference and perceived loop smoothness.

## New SFX

Nineteen original WAVs are in `audio/sfx/v2`, approximately 545 KiB total. Original sources and deterministic generator: `tools/build_cozy_audio.py`; no external samples are used. Godot import compression is disabled so the short transients remain PCM. Existing v1 files are retained.

- Match: four slightly different soft pops with a short mallet/chime layer. Consecutive variants never repeat.
- Cascade: pitch follows semitone offsets `[0,2,4,7,9,12,14,16]`, then caps. This forms an ascending pentatonic progression instead of a chromatic climb.
- Special creation: paper rustle and three-note reveal.
- Directional Tapau: packaging rustle, soft directional whoosh and a bright trailing note.
- Dulang: low rounded thump, airy burst and rising mallet notes.
- Cross: two staggered whooshes, warm central impact and ascending sparkle chord.
- Special Order: airy upward melody.
- Hantar: separate packaging, launch and arrival cues, preserving the board's existing .45-second timing.
- Spatula: gentle woody impact and scoop sweep.
- Shuffle: three soft sweeps and a settling chime.
- Order served: four-note completion melody.
- Reward/unlock: distinct short ascending cues.
- Success: a 1.78-second celebratory major chord/melody.

Menu tap, swap, invalid, failure, pack and drop continue using their existing v1 audio. Runtime map: `AudioManager.FILE_SFX`; match variation uses `_match_variants`. Files have short fades, bounded tails and peak headroom at or below 0.52. Rebuild with the workspace Python and NumPy. After initial import, preserve `compress/mode=0` in each WAV's `.import` file.

## Listening previews

Local previews are deliberately excluded from export:

- `.audio_preview/cozy_sfx_demo.mp3`: match ×4 → special creation → directional Tapau → Dulang → cross → Special Order → Hantar create/launch/hit → Spatula → Shuffle → order served → reward → success.
- `.audio_preview/cozy_music_preview.mp3`: twenty seconds of the new gameplay theme, with preview fades.

Preview gain is for comparison. The game's individual SFX gain and quieter music balance are applied separately at runtime.

## Validation

`tools/audio_install_test_scene.tscn` checks PCM assets, peaks, durations, loaded variants, variant non-repetition, cascade pitch/cap, mute, looping, interrupted crossfades, result ducking, application background/resume and VFX cleanup. WAV boundary samples are zero; all generated SFX fit within 1.78 seconds. Subjective timbre and phone speaker balance should be assessed using the previews and device play.
