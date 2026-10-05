@tool
extends Control

## Editor-only representation of a counter character; no gameplay/autoload dependency.
@export var portrait_texture: Texture2D
var _texture: Texture2D
var _region := Rect2()

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    resized.connect(queue_redraw)

func _process(_delta: float) -> void:
    # Also follows sibling dialogue/board edits immediately in the 2D editor.
    if Engine.is_editor_hint():
        queue_redraw()

func _draw() -> void:
    if portrait_texture == null or size.x <= 0 or size.y <= 0:
        return
    if _texture != portrait_texture:
        _texture = portrait_texture
        _region = Rect2(_texture.get_image().get_used_rect())
    var region := _region
    var fit := minf(size.x / region.size.x, size.y / region.size.y)
    var fitted := region.size * fit
    var destination := Rect2((size - fitted) * .5, fitted)
    var bubble := get_node_or_null("../DialogueBubble") as Control
    if bubble != null:
        var minimum := bubble.get_global_transform().origin.y + bubble.size.y * .80 + 14 - get_global_transform().origin.y
        destination.position.y = maxf(destination.position.y, minimum)
    var board := get_node_or_null("../../PuzzleBoard") as Control
    if board != null:
        var edge := board.get_global_rect().position.y - get_global_rect().position.y
        var visible_height := clampf(edge - destination.position.y, 0, destination.size.y)
        region.size.y *= visible_height / destination.size.y
        destination.size.y = visible_height
    if destination.size.y > 0:
        draw_texture_rect_region(_texture, destination, region)
