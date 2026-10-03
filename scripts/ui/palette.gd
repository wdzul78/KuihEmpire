class_name Palette
extends RefCounted

## Colour language pulled straight from the character board and master plan:
## warm gerai wood, creamy coconut tones, Aina's pink and a lot of pandan green.

const CREAM := Color("fbf1dc")
const CREAM_DEEP := Color("f3e0bd")
const PAPER := Color("fffaf0")
const WOOD_DARK := Color("5b3a22")
const WOOD := Color("8a5a33")
const WOOD_LIGHT := Color("c9964f")
const WOOD_PALE := Color("e3bd82")

const PINK := Color("f76f8e")
const PINK_LIGHT := Color("ffb6c9")
const PINK_PALE := Color("ffe1e8")
const PINK_DARK := Color("d94f70")

const LEAF := Color("6fae45")
const LEAF_DARK := Color("3f7f2a")
const LEAF_LIGHT := Color("a8d16a")
const LEAF_DEEP := Color("2c5c1e")

const GOLD := Color("f0a93b")
const GOLD_DARK := Color("c8862a")
const GOLD_PALE := Color("ffe6b0")

const INK := Color("3b2a1c")
const INK_SOFT := Color("6b5545")
const WHITE := Color("fffdf6")
const SHADOW := Color(0.23, 0.14, 0.08, 0.22)

const SKIN := Color("e8b98f")
const SKIN_DARK := Color("d09a6d")

const COIN := Color("f5c542")
const STAR := Color("ffc94d")

## The board must never compete with the kuih, so the tray is warm bamboo rather
## than green. This single change is what makes every food colour read instantly.
const BOARD_CELL := Color("f0dcb4")
const BOARD_CELL_DEEP := Color("dcc28f")
const BOARD_TRAY := Color("a9743f")


## Slightly vary a colour so repeated panels never look flat.
static func jitter(base: Color, seed_value: int, amount: float = 0.04) -> Color:
	var n := (sin(float(seed_value) * 12.9898) * 43758.5453)
	n = n - floor(n)
	var d := (n - 0.5) * 2.0 * amount
	return Color(
		clampf(base.r + d, 0.0, 1.0),
		clampf(base.g + d * 0.8, 0.0, 1.0),
		clampf(base.b + d * 0.6, 0.0, 1.0),
		base.a
	)


static func lighten(c: Color, amount: float) -> Color:
	return c.lerp(Color.WHITE, amount)


static func darken(c: Color, amount: float) -> Color:
	return c.lerp(Color.BLACK, amount)
