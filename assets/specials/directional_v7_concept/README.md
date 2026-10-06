# Selected Tapau box with separate direction markers

- `tapau_base.png`: exact original image supplied and selected by the user, copied without pixel changes.
- `triangle_right.png`: separate green/gold right marker generated using built-in imagegen. Mirror horizontally for the left marker in Godot.
- `tapau_horizontal.png`: built-in imagegen composition proposal. Runtime graphics have not been replaced.

Original assets were backed up before design edits. Separate base and marker support later outward movement and pulsing without moving the box.

## Final composition prompt

Use case: compositing. Image 1 is the USER-SELECTED kraft takeaway box and must be preserved exactly in shape, color, lid and flap geometry, front notch, proportions, near-front viewpoint and cartoon shading. Image 2 is the green gold-bordered RIGHT-pointing triangular marker. Add TWO matching markers to Image 1: a horizontally mirrored LEFT-pointing triangle on the left and a RIGHT-pointing triangle on the right. Place both on the large middle front panel, matching size on one horizontal baseline. Make them prominent: triangle height about 32 percent of the whole box height, marker pair together spans roughly 75 percent of box width including a modest middle gap. Keep clear kraft margins and the front notch visible. Preserve image 2's green fill and gold rim. No chevrons, no shafts, no label, no ribbon, no seal, no text. The box fills nearly all the square canvas with small transparent margin, fully visible, no clipping. Fully opaque object with clean fully transparent exterior. No glow, no particles, no background or shadow cloud. One finished Tapau Horizontal mobile game sprite.

## Separate marker prompt

Use case: background-extraction. Extract and redraw ONLY the RIGHT-facing green triangular marker from this exact Tapau Horizontal icon as one isolated transparent sprite. Preserve the solid rounded green triangle, thick gold rim, cream top-left highlight, dark brown contour, precise proportions, lighting and cartoon finish. Delete the entire box, left marker and all other content. Exactly one RIGHT-facing solid triangle, centered with small transparent margin, fully opaque symbol, fully transparent exterior. No shaft, no chevron, no text, no glow, no shadow cloud. Left marker will be rendered by horizontal mirroring in Godot.

