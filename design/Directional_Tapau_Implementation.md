# Directional Tapau specials

Implemented 2026-10-04. Match four horizontally creates TAPAU (row clear); match four vertically creates TAPAU_VERTICAL (column clear). Stable numeric enum IDs preserved. L/T Dulang, 5+ Special Order and 2x2 Hantar retain their priorities.

A deliberate adjacent swap of any two directional specials (H/H, H/V, V/H, V/V) produces a single row-plus-column cross centered at the swap destination. Each source activates once. Ordinary chain hits retain the struck special's own direction, without treating the chain as a cross combo.

## Artwork
Generated with built-in imagegen, original RGBA pixels/alpha preserved. Closed kraft Tapau packages with banana-leaf ribbon and prominent green arrow tags, no visible kuih.
- assets/specials/directional_v1/tapau_horizontal.png
- assets/specials/directional_v1/tapau_vertical.png

BoardArt maps the two directions separately. KuihIcon fits the transparent used region without stretching. Original assets/boosters/tapau.png is retained for the booster and cross-combination transformation.

## Cross animation
After the swap animation, both directional tiles converge and fade over 0.12s. A transient TextureRect named CrossComboTapauPackage displays the original boosters/tapau.png, popping in and settling over 0.26s, then holding briefly. Cross VFX and blast sound start after this transformation. The transient package is removed after the blast lead-in. Input remains locked through resolution; visuals inherit scene pause and ownership. No new logical special or persistent asset is introduced by the animation.

Lesson 4 text now teaches one horizontal row, the vertical variant, and swapping two directional specials for a cross.

## Validation
- Directional tests PASS: native lines at center/corner, all four pair combinations with horizontal/vertical/corner adjacency, destination-centered cross, unique activations, ordinary chains, nonadjacent seeds, blocker preservation, directional/cross beams, distinct assets.
- Rules harness PASS: creation rules, blockers, all tutorials T1–T9 achievable 4/4 seeds.
- Delivery, regression and score tests PASS. Existing delivery/score fixtures report ObjectDB exit warnings.
- Actual 360x640 gameplay screenshots/assertions verify distinct sprites, busy input during transformation, no cross effects before transformation, two beams afterward, and transient package cleanup.
- Full campaign balance and Android performance were not measured.

The remaining enhanced combo matrix, Sweet Meter and Super Order from the earlier full plan are pending.

## Exact horizontal prompt
Use case: stylized-concept. Asset: single transparent mobile match-3 game sprite for KUIH EMPIRE. Reference image: existing Tapau gift package, use as design and style reference. Draw a CLOSED tan kraft takeaway gift box with bright green banana-leaf ribbon and small leaf bow, polished cartoon shading and clean dark brown outline like reference. NO kuih or food visible. Replace crown tag with a LARGE front-facing cream badge showing ONE bold green HORIZONTAL double-headed arrow LEFT and RIGHT (↔), strictly screen horizontal. Badge centered, clear at 48 pixel size, takes half front face. Smaller bow so arrow dominates. Compact square centered package, slight top view, all edges contained, minimal padding. Actual transparent alpha background, no shadow outside sprite, no text, no crown, no vertical arrows, no cross symbol, no airplane.

## Exact vertical prompt
Use case: stylized-concept. Asset: single transparent mobile match-3 game sprite for KUIH EMPIRE. Reference image: existing Tapau gift package, use as design and style reference. Draw a CLOSED tan kraft takeaway gift box with bright green banana-leaf ribbon and small leaf bow, polished cartoon shading and clean dark brown outline like reference. NO kuih or food visible. Replace crown tag with a LARGE front-facing cream badge showing ONE bold green VERTICAL double-headed arrow UP and DOWN (↕), strictly screen vertical. Badge centered, clear at 48 pixel size, takes half front face. Smaller bow so arrow dominates. Compact square centered package, slight top view, all edges contained, minimal padding. Actual transparent alpha background, no shadow outside sprite, no text, no crown, no horizontal arrows, no cross symbol, no airplane. Draw package upright, do not rotate whole box.


## Special artwork idle motion
All board special sprites (directional Tapau, Dulang, Order, Hantar) use a subtle 1.0–1.045 breathing scale on the icon child over a 1.5s loop. Ordinary kuih stay still. Symbol orientation is preserved. The loop inherits pause and is killed/reset when the tile becomes ordinary; swap/clear animations continue to own the parent tile.
