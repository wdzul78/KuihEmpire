# Deferred banana leaf and visible Dulang lesson

The opening tutorial now follows stable lesson IDs 1, 2, 3, 4, 5, 7, 8. Lesson 6 (Under the Leaf) is deferred; campaign Stage 7 already has the banana-leaf introduction dialogue and obstacles. Historical tutorial IDs remain stable, and a save paused at lesson 6 resumes at the queue lesson (7) without resetting any progress.

Dulang removes the 3×3 area centred on its destination after a swap. The previous activation hint chose the first playable neighbour, which could put the centre at an edge and clip the area. The hint now prefers an inward destination. Activation outlines the actual blast area in gold, then clears its kuih together and holds the empty area briefly before gravity/refill. Other positions in regular gameplay continue to clip naturally at board boundaries.

Validation: the regression test creates Dulang through the real tutorial swap, then activates the guided special. It verifies an interior destination, a nine-cell preview and nine kuih in the first actual collection batch, plus Aina's recap before the lesson finishes. It also checks skipping the deferred lesson and resuming an old lesson-6 save. A rendered test captured `.shots/dulang_preview.png` and `.shots/dulang_cleared.png` for visual inspection.
