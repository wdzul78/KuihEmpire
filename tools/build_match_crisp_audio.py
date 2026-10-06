"""Original compact match sounds: warm impact, soft fragments, minimal tail.

No recordings from reference games. Refuses to overwrite existing audio;
back up with tools/backup_design.ps1 before revising an existing version.
"""
from pathlib import Path
import wave
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "audio/sfx/v4"
RATE = 44100


def noise(rng, count, low, high):
    signal = rng.normal(0, 1, count)
    spectrum = np.fft.rfft(signal)
    frequency = np.fft.rfftfreq(count, 1 / RATE)
    spectrum *= (1 - np.exp(-(frequency / low) ** 4)) * np.exp(-(frequency / high) ** 4)
    signal = np.fft.irfft(spectrum, n=count)
    return signal / max(np.max(np.abs(signal)), 1e-9)


def render(variant):
    rng = np.random.default_rng(1062026 + variant)
    t = np.arange(round(.22 * RATE)) / RATE
    signal = np.zeros_like(t)
    # A shallow pitch fall gives weight without the rubbery bubble wobble.
    phase = 2 * np.pi * (185 * t + 1.1 * (1 - np.exp(-t / .018)))
    signal += .32 * np.sin(phase) * (1 - np.exp(-t / .0009)) * np.exp(-t / .022)
    # Closely packed, differently filtered grains make a single soft crunch.
    for index, onset in enumerate([0, .004, .010, .018, .029, .043]):
        local = np.maximum(t - onset, 0)
        envelope = (1 - np.exp(-local / .0007)) * np.exp(-local / (.012 + index * .002))
        grain = noise(rng, len(t), 550 + index * 150, 3400 + variant * 130)
        signal += grain * envelope * (.30 - index * .028)
    # Quiet inharmonic resonances, rather than a musical bell/chime sequence.
    for index, frequency in enumerate([430, 713, 1129, 1811, 2573]):
        detune = rng.uniform(.975, 1.025)
        envelope = (1 - np.exp(-t / .0018)) * np.exp(-t / (.024 + index * .003))
        signal += np.sin(2 * np.pi * frequency * detune * t) * envelope * (.08 / (1 + index * .7))
    # A soft airy finish fills the particle tail without a high whistle.
    signal += noise(rng, len(t), 1200, 4800) * (1 - np.exp(-t / .008)) * np.exp(-t / .042) * .045
    signal -= signal.mean()
    signal *= .48 / max(np.max(np.abs(signal)), 1e-9)
    signal[:44] *= np.linspace(0, 1, 44)
    signal[-882:] *= np.linspace(1, 0, 882)
    return np.round(signal * 32767).astype("<i2")


def main():
    paths = [OUT / f"match_{index+1}.wav" for index in range(4)]
    if any(path.exists() for path in paths):
        raise SystemExit("Existing audio: back up originals and choose a new output version before regeneration.")
    OUT.mkdir(parents=True, exist_ok=True)
    for index, path in enumerate(paths):
        with wave.open(str(path), "wb") as output:
            output.setnchannels(1)
            output.setsampwidth(2)
            output.setframerate(RATE)
            output.writeframes(render(index).tobytes())
        print(path.relative_to(ROOT))


if __name__ == "__main__":
    main()
