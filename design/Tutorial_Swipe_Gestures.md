# Supplied tutorial swipe sprites

The four user supplied transparent sheets are copied unchanged into `assets/ui/gestures/swipe_left.png`, `swipe_right.png`, `swipe_down.png` and `swipe_up.png`. Each has four 543 by 724 frames. `SwipeIndicator` positions the fingertip on the guided start/destination tile centres, chooses the appropriate direction sheet, plays the left sheet in reverse to preserve its trail direction, pauses and fades before looping. The hand ignores pointer input.

Tutorial vertical/horizontal swaps and Tapau/Dulang lessons show the gesture immediately with focused tiles. Correct moves clear it; intro dialogue shows the separate tap animation. Campaign hints retain their existing behaviour.

Dialogue spotlight also raises Aina above the dim layer and restores her original colour and drawing order when dialogue ends. CharacterIcon's existing counter occlusion keeps her lower body behind the board. Regression checks direction selection, frame progression, successful-swap cleanup and Aina's highlight restoration. Render previews: `.shots/06_tutorial_01_3x3.png`, `.shots/07_tutorial_02_3x3.png`, `.shots/08_tutorial_04_4x4.png`, `.shots/33_tap_dialogue_highlight.png`.
