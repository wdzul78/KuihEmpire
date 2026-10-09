"""Original deterministic short water-bomb SFX; no external samples."""
import math
import random
import struct
import wave
from pathlib import Path

rate = 44100
duration = 0.58
rng = random.Random(817)
low = 0.0
samples = []
for n in range(int(rate * duration)):
    t = n / rate
    noise = rng.uniform(-1, 1)
    low += 0.16 * (noise - low)
    # Deep falling impact followed by a broad wet noise splash.
    boom = math.sin(2 * math.pi * (110 * t - 55 * t * t)) * math.exp(-t * 24)
    splash = (low * 2.2 + noise * 0.12) * (1 - math.exp(-t * 220)) * math.exp(-t * 8)
    droplets = 0.0
    for start, pitch in [(0.09, 1150), (0.15, 820), (0.23, 1450), (0.31, 950)]:
        age = t - start
        if age >= 0:
            droplets += 0.12 * math.sin(2 * math.pi * (pitch * age + 950 * age * age)) * math.exp(-age * 65)
    fade = min(1, (duration - t) / 0.04)
    samples.append((0.65 * boom + 0.7 * splash + droplets) * fade)
peak = max(abs(v) for v in samples)
target = Path(__file__).resolve().parents[1] / 'audio/sfx/coconut_v1/water_bomb.wav'
target.parent.mkdir(parents=True, exist_ok=True)
with wave.open(str(target), 'wb') as output:
    output.setparams((1, 2, rate, 0, 'NONE', 'not compressed'))
    output.writeframes(b''.join(struct.pack('<h', round(v / peak * 28000)) for v in samples))
print(target)
