"""Original light cartoon rotor, claw click and departure whoosh, PCM mono."""
from pathlib import Path
import wave
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "audio/sfx/delivery_rotor_v1"
RATE = 44100


def air(count, seed, low=120, high=2600):
    rng = np.random.default_rng(seed)
    spectrum = np.fft.rfft(rng.normal(size=count))
    frequency = np.fft.rfftfreq(count, 1/RATE)
    spectrum *= (1-np.exp(-(frequency/low)**4)) * np.exp(-(frequency/high)**4)
    result = np.fft.irfft(spectrum, n=count)
    return result / max(np.max(np.abs(result)), 1e-9)


def flight(departing=False):
    duration = .50 if departing else .52
    t = np.arange(round(duration*RATE)) / RATE
    progress = t/duration
    speed = 42+48*progress if departing else 18+42*(1-np.exp(-t/.11))
    phase = np.cumsum(speed)*2*np.pi/RATE
    blades = (.5+.5*np.sin(phase))**3
    envelope = np.sin(np.pi*progress)**.8
    rotor = air(len(t), 410 if departing else 409, 90, 2100) * (.22+.78*blades)
    sweep = air(len(t), 414 if departing else 413, 750, 4200) * np.sin(np.pi*progress)**2
    body = np.sin(phase*2.1)*.045 + np.sin(2*np.pi*110*t)*.025
    return (rotor*.60+sweep*.18+body) * envelope


def claw():
    t = np.arange(round(.14*RATE))/RATE
    texture = air(len(t), 420, 650, 5000)
    result = np.zeros_like(t)
    for onset, gain in [(0,.8),(.024,.5)]:
        local = np.maximum(t-onset,0)
        envelope = (1-np.exp(-local/.0006))*np.exp(-local/.007)
        result += (texture*.7+np.sin(2*np.pi*1450*local)*.13)*envelope*gain
    return result


def write(name, signal):
    path = OUT / (name+".wav")
    if path.exists():
        raise SystemExit("Refusing to overwrite existing audio; back up and use a new version.")
    signal -= signal.mean()
    signal *= .42/max(np.max(np.abs(signal)),1e-9)
    signal[:44] *= np.linspace(0,1,44)
    signal[-441:] *= np.linspace(1,0,441)
    with wave.open(str(path), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(np.round(signal*32767).astype("<i2").tobytes())
    print(path.relative_to(ROOT))


if __name__ == "__main__":
    OUT.mkdir(parents=True,exist_ok=True)
    write("rotor_launch",flight())
    write("claw_pickup",claw())
    write("rotor_exit",flight(True))
