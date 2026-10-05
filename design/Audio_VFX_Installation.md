# Music, special SFX and VFX installation

Updated audio direction: see `design/Cozy_Audio_v2.md` for the new gameplay music and original pop/chime special effects. The notes below document the initial v1 installation.

Implemented 2026-10-05. The paid WOW Sound and CartoonCoffee packs are **not** included. No purchase was made. This implementation uses shipped CC0 recordings, custom sound layers, and native Godot visual animation.

## Music

Menu, journey, shop and other navigation screens: `audio/music/menu.ogg` (relax_background1, joaquinton).
Gameplay/tutorial: `audio/music/gameplay.ogg` (Happy Beat, burabotti).
Credits and source links: `audio/licenses/Music_CC0.md`.

Two AudioStreamPlayer voices crossfade over 1.4 seconds. Re-entering the same theme does not restart it. Music is reduced on result overlays, then restored when the overlay closes. Existing Music/SFX settings apply independently. Application focus loss/background pauses music and stops short effects; returning resumes according to the saved toggle.

## Sound files

22 mono PCM WAVs at 22050 Hz, under `audio/sfx`, total approximately 647 KiB. Their peak is normalized to 0.55 so layered cascades have headroom. Existing SfxSynth provides a fallback for the original events.

Kenney sources (CC0, archived license text shipped):
- https://kenney.nl/assets/interface-sounds
- https://kenney.nl/assets/impact-sounds

Direct samples: tap=click_003, swap=switch_002, invalid=error_003, pack=scratch_001, drop=drop_001, match=pluck_001.
Layered samples: glass_003, pluck_002, scratch_002, switch_003, impactSoft_medium_000, impactPlate_light_001 and impactPlate_light_002.
Whooshes and melodic chimes/jingles are original deterministic noise/tone synthesis, layered with these CC0 samples. Custom tones are not from WOW Sound or Kenney music jingles.

AudioManager.FILE_SFX maps readable event names to the files. Each special and cross combination has its own sound. Cascade pitch rises gradually. Spatula and Shuffle now have activation cues.

## Visual effects

Kenney Particle Pack: https://kenney.nl/assets/particle-pack (CC0).
Only transparent `star_04.png` and `light_02.png` are shipped in `assets/vfx/kenney`. License text: `audio/licenses/particle-pack.txt`.

GameVfx uses these as soft glow and star sprites with native animated geometry:
- Match: narrow warm sweep.
- Directional Tapau: brighter sweep following its actual row/column, moving star front and leaf fragments.
- Cross Tapau: paired beams, central flash and expanding ring after existing package combination animation.
- Dulang: expanding gold ring and local sparkle highlights.
- Order: curved pink/gold light connections to its targets.
- Hantar: curved parcel flight, fading trail, delayed arrival sparkle synchronized to the existing .45-second hit cue.
- Spatula: upward scoop sparkle.
- Shuffle: rotating leaf-green trails.
- Success: pastel flower/leaf confetti and two warm side flashes.

The approved slow idle wiggle is unchanged. Drawing remains input-transparent, inherits board pause, uses no screen-sized shaders, and is capped at 240 particles/48 effects. Rendering stops when all effects expire.

## Validation

`tools/audio_install_test_scene.tscn`: audio files, PCM headroom/duration, looping, crossfade interruption, independent mute, result ducking, phone pause/resume and VFX cleanup.
`tools/vfx_test_scene.tscn`: special footprints, pause, cleanup, bounded particles, mute and result visuals.
`tools/directional_special_test_scene.tscn`: directional rules and two cross beams.

Phone performance and subjective music/sound preference still require device playtesting.
