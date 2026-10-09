"""Original short electric buzz and crackling zaps for the match-five veins."""
from pathlib import Path
import wave
import numpy as np

RATE = 44100
ROOT = Path(__file__).resolve().parents[1]


def build():
    t = np.arange(round(.78 * RATE)) / RATE
    rng = np.random.default_rng(5106)
    noise = rng.normal(size=len(t))
    spectrum = np.fft.rfft(noise)
    frequency = np.fft.rfftfreq(len(t), 1 / RATE)
    spectrum *= (1 - np.exp(-(frequency / 350) ** 4)) * np.exp(-(frequency / 4200) ** 4)
    crackle = np.fft.irfft(spectrum, n=len(t))
    crackle /= max(np.max(np.abs(crackle)), 1e-9)
    phase = 2 * np.pi * (155 * t + 16 * np.sin(2 * np.pi * 6 * t) / (2 * np.pi * 6))
    buzz = np.sin(phase + 1.7 * np.sin(phase * 3))
    envelope = np.minimum(t / .012, 1) * np.clip((.78 - t) / .12, 0, 1)
    pulses = (.35 + .65 * (.5 + .5 * np.sin(2 * np.pi * 24 * t)) ** 3)
    signal = (buzz * .22 + crackle * pulses * .5) * envelope
    for onset in [.015, .13, .25, .39, .52, .64]:
        local = np.maximum(t - onset, 0)
        zap_env = (t >= onset) * (1 - np.exp(-local / .001)) * np.exp(-local / .026)
        sweep = np.sin(2 * np.pi * (2400 * local - 13000 * local ** 2))
        signal += (sweep * .32 + crackle * .28) * zap_env
    signal *= .48 / max(np.max(np.abs(signal)), 1e-9)
    output = ROOT / "audio/sfx/electric_order_v1/zap.wav"
    output.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(output), "wb") as audio:
        audio.setnchannels(1)
        audio.setsampwidth(2)
        audio.setframerate(RATE)
        audio.writeframes(np.round(signal * 32767).astype("<i2").tobytes())
    print(f"Created {output.name}: 0.78s PCM, peak 0.48")


if __name__ == "__main__":
    build()
