extends Node

## Campaign events, emitted by the session controller, never achievement logic in the board.
signal stage_completed(level_id: int, stars: int, score: int, used_booster: bool)
signal stage_failed(level_id: int)
signal order_served()
signal specials_used(count: int, combo: bool)
