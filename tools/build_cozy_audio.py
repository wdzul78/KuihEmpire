"""Reproducible original puzzle SFX. No third-party audio samples or AI API.

Run with the workspace Python (requires numpy); output: audio/sfx/v2.
"""
from pathlib import Path
import hashlib
import json
import wave
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'audio/sfx/v2'
RATE = 22050
RNG = np.random.default_rng(5102026)


def time(duration):
    return np.arange(round(duration * RATE)) / RATE


def envelope(t, decay=.14, attack=.004):
    return (1 - np.exp(-t / attack)) * np.exp(-t / decay)


def bell(freq, duration=.35, bright=.16):
    t = time(duration)
    return (np.sin(2*np.pi*freq*t) * envelope(t, duration*.25)
            + bright*np.sin(2*np.pi*freq*2.76*t) * envelope(t, duration*.11)
            + .04*np.sin(2*np.pi*freq*5.4*t) * envelope(t, duration*.07))


def noise(duration, low=450, high=4000):
    n = RNG.normal(size=round(duration*RATE))
    spectrum = np.fft.rfft(n)
    f = np.fft.rfftfreq(len(n), 1/RATE)
    # Smooth spectral boundaries avoid a harsh narrow-band hiss.
    spectrum *= (1 - np.exp(-(f/low)**4)) * np.exp(-(f/high)**4)
    n = np.fft.irfft(spectrum, n=len(n))
    return n / max(np.max(np.abs(n)), 1e-9)


def pop(variant=0):
    t = time(.15)
    start = 650 + variant*22
    end = 225 + variant*5
    phase = 2*np.pi*(end*t + (start-end)*.021*(1-np.exp(-t/.021)))
    return np.sin(phase)*envelope(t,.028,.0015) + noise(.15,700,3000)*envelope(t,.016)*.15


def sweep(duration=.4, strength=1):
    t = time(duration)
    wind = noise(duration,400,3500)
    shape = np.sin(np.pi*t/duration)**1.8
    return wind*shape*.52*strength


def paper(duration=.12):
    t = time(duration)
    return noise(duration,1700,6500)*envelope(t,.03,.002)*(.65+.35*np.sin(2*np.pi*45*t))*.22


def thump(duration=.27):
    t = time(duration)
    return (np.sin(2*np.pi*(100*t+50*.025*(1-np.exp(-t/.025))))
            *envelope(t,.046,.002)*.7 + noise(duration,300,1500)*envelope(t,.025)*.22)


def mix(duration, *events):
    result = np.zeros(round(duration*RATE))
    for at, signal, gain in events:
        start = round(at*RATE)
        count = min(len(signal),len(result)-start)
        if count > 0:
            result[start:start+count] += signal[:count]*gain
    return result


def melody(notes, gap=.09, tail=.35, gain=.4):
    return mix(gap*(len(notes)-1)+tail,
               *((i*gap,bell(freq,tail),gain) for i,freq in enumerate(notes)))


def room(signal, wet=.1):
    result = signal.copy()
    for delay, gain in [(.023,wet),(.043,wet*.6),(.071,wet*.3)]:
        shift = round(delay*RATE)
        result[shift:] += signal[:-shift]*gain
    return result


def write(name, signal, peak=.52):
    signal = room(signal)
    signal -= np.mean(signal)
    signal *= peak / max(np.max(np.abs(signal)),1e-9)
    # Quiet ramp at both boundaries; no hard cuts or looping clicks.
    fade = min(round(.012*RATE),len(signal)//4)
    signal[:fade] *= np.linspace(0,1,fade)
    signal[-fade:] *= np.linspace(1,0,fade)
    path = OUT / (name+'.wav')
    with wave.open(str(path),'wb') as file:
        file.setnchannels(1)
        file.setsampwidth(2)
        file.setframerate(RATE)
        file.writeframes(np.round(signal*32767).astype('<i2').tobytes())
    return {'file':path.relative_to(ROOT).as_posix(), 'duration':round(len(signal)/RATE,3),
            'peak':round(float(np.max(np.abs(signal))),4),
            'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}


def main():
    OUT.mkdir(parents=True,exist_ok=True)
    sounds = {}
    for i in range(4):
        sounds[f'match_{i+1}'] = mix(.28,(0,pop(i),.75),(.025,bell(523.251,.25,.10+i*.015),.30))
    sounds['line_clear'] = mix(.27,(0,paper(.09),.40),(.015,sweep(.24),.26))
    sounds['special_create'] = mix(.68,(0,paper(),.7),(.035,melody([523.251,659.255,783.991],.07,.48),1))
    sounds['directional_tapau'] = mix(.68,(0,paper(.16),1),(.06,sweep(.42),.9),(.23,bell(783.991,.40),.28))
    sounds['tray_burst'] = mix(.76,(0,thump(),.7),(.045,sweep(.4),.6),(.11,melody([391.995,523.251,659.255],.06,.40),.9))
    sounds['cross_tapau'] = mix(.94,(0,thump(),.7),(.04,paper(.16),.8),(.07,sweep(.40),.7),(.24,sweep(.4),.6),(.35,melody([523.251,783.991,1046.502],.08,.43),.9))
    sounds['order_burst'] = mix(1.02,(0,sweep(.42),.4),(.03,melody([523.251,587.33,659.255,783.991,1046.502],.10,.5),1))
    sounds['hantar_create'] = mix(.60,(0,paper(.18),1),(.05,melody([659.255,783.991],.09,.40),.9))
    sounds['hantar_launch'] = mix(.45,(0,paper(.14),.8),(.01,sweep(.4),.8),(.06,bell(659.255,.24),.2))
    sounds['hantar_hit'] = mix(.43,(0,pop(2),.6),(.025,bell(1046.502,.38),.45))
    sounds['spatula'] = mix(.52,(0,thump(.17),.45),(.04,sweep(.27),.6),(.13,bell(659.255,.34),.32))
    sounds['shuffle'] = mix(.83,(0,sweep(.31),.55),(.19,sweep(.31),.50),(.38,sweep(.32),.45),(.47,melody([659.255,783.991],.09,.25),.6))
    sounds['serve'] = mix(.88,(0,pop(),.3),(.02,melody([523.251,659.255,783.991,1046.502],.10,.48),1))
    sounds['reward'] = melody([659.255,783.991,1046.502],.12,.55)
    sounds['unlock'] = melody([391.995,523.251,659.255,783.991],.11,.55)
    sounds['success'] = mix(1.78,(0,melody([523.251,659.255,783.991],.13,.58),1),
        (.49,bell(523.251,1.1),.3),(.49,bell(659.255,1.1),.25),
        (.49,bell(783.991,1.1),.22),(.69,bell(1046.502,.9),.4))
    manifest = [write(name,data) for name,data in sounds.items()]
    (OUT/'manifest.json').write_text(json.dumps({'generator':'tools/build_cozy_audio.py',
        'seed':5102026,'origin':'Original deterministic synthesis; no external audio samples.',
        'sample_rate':RATE,'files':manifest},indent=2)+'\n',encoding='utf-8')
    # Preview: four increasingly musical clears, then creation, each special,
    # order completion, reward and success, with a breath between events.
    sequence = []
    elapsed = 0.0
    for name in ['match_1','match_2','match_3','match_4','special_create',
                 'directional_tapau','tray_burst','cross_tapau','order_burst',
                 'hantar_create','hantar_launch','hantar_hit','spatula','shuffle',
                 'serve','reward','success']:
        data = sounds[name]
        if name.startswith('match_'):
            shift = [0,2,4,7][int(name[-1])-1]
            factor = 2**(shift/12)
            data = np.interp(np.arange(0,len(data),factor),np.arange(len(data)),data)
        sequence.append((elapsed,data,.52/max(np.max(np.abs(data)),1e-9)))
        elapsed += len(data)/RATE + .38
    preview = ROOT/'.audio_preview'
    preview.mkdir(exist_ok=True)
    demo = mix(elapsed+.4,*sequence)
    with wave.open(str(preview/'cozy_sfx_demo.wav'),'wb') as file:
        file.setnchannels(1); file.setsampwidth(2); file.setframerate(RATE)
        file.writeframes(np.round(demo*32767).astype('<i2').tobytes())
    print(f'Generated {len(manifest)} original SFX; preview {elapsed:.1f}s; PCM mono {RATE} Hz.')


if __name__ == '__main__':
    main()
