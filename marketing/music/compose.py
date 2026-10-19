#!/usr/bin/env python3
"""
Composes FIRST CHAIR's soundtrack from scratch with numpy (no samples, nothing to license),
then uses ffmpeg for reverb, loudness and OGG encoding.

    python3 marketing/music/compose.py          -> marketing/music/*.ogg (+ .wav kept out of git)

Tracks
  valence.ogg      title screen + lobby   warm electric-piano arpeggios over a soft pad, 84 BPM
  case-file.ogg    investigation          pulsing bass, muted plucks, slow pad swells, 98 BPM
  northbridge.ogg  courtroom              low strings, distant timpani, tremolo tension, 66 BPM
  verdict.ogg      results stinger        gavel strike into a rising brass resolution, 7 s
"""
import math, os, subprocess, wave
import numpy as np

SR = 44100
OUT = os.path.dirname(os.path.abspath(__file__))
rng = np.random.default_rng(7)

# ----------------------------------------------------------------- building blocks
def midi(n):  # midi note -> Hz
    return 440.0 * 2 ** ((n - 69) / 12)

def times(dur):
    return np.arange(int(dur * SR)) / SR

def adsr(n, a, d, s, r):
    env = np.ones(n)
    a_n, d_n, r_n = int(a * SR), int(d * SR), int(r * SR)
    a_n = min(a_n, n); env[:a_n] = np.linspace(0, 1, a_n, endpoint=False) if a_n else env[:0]
    d_end = min(a_n + d_n, n)
    if d_end > a_n: env[a_n:d_end] = np.linspace(1, s, d_end - a_n, endpoint=False)
    env[d_end:] = s
    r_n = min(r_n, n)
    if r_n: env[-r_n:] *= np.linspace(1, 0, r_n)
    return env

def lowpass(x, cutoff, order=2):
    """Zero-phase low-pass via FFT (fast, no scipy needed)."""
    spec = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / SR)
    spec *= 1 / np.sqrt(1 + (f / cutoff) ** (2 * order))
    return np.fft.irfft(spec, n=len(x))

def saw(freq, t, harmonics=24, detune=0.0):
    """Band-limited saw. `freq` may be a scalar or a per-sample array (vibrato)."""
    out = np.zeros_like(t)
    f = np.asarray(freq, dtype=float) * (1 + detune)
    phase = 2 * math.pi * (np.cumsum(f) / SR if f.ndim else f * t)
    fmax = float(np.max(f))
    for k in range(1, harmonics + 1):
        if fmax * k > SR / 2: break
        out += np.sin(phase * k) / k
    return out * (2 / math.pi)

# ----------------------------------------------------------------- instruments (return mono arrays)
def ep(note, dur, vel=0.8):  # electric piano
    t = times(dur + 0.6); f = midi(note)
    x = (np.sin(2 * math.pi * f * t) * np.exp(-t * 2.6)
         + 0.32 * np.sin(2 * math.pi * 2 * f * t + 0.3) * np.exp(-t * 4.5)
         + 0.10 * np.sin(2 * math.pi * 3 * f * t) * np.exp(-t * 7)
         + 0.18 * np.sin(2 * math.pi * 7.01 * f * t) * np.exp(-t * 38))
    x *= adsr(len(t), 0.004, 0.0, 1.0, 0.25)
    return x * vel * 0.5

def pad(note, dur, vel=0.5, cutoff=1400, attack=1.0):
    t = times(dur); f = midi(note)
    x = saw(f, t, 20, 0.0035) + saw(f, t, 20, -0.004) + 0.6 * saw(f * 0.5, t, 12)
    x = lowpass(x, cutoff) * adsr(len(t), attack, 0.6, 0.85, min(1.6, dur * 0.4))
    return x * vel * 0.16

def strings(note, dur, vel=0.5, cutoff=2200):
    t = times(dur); f = midi(note)
    vib = 1 + 0.0028 * np.sin(2 * math.pi * 5.2 * t) * np.minimum(1, t / 1.5)
    x = saw(f * vib, t, 30, 0.002) + saw(f * vib, t, 30, -0.0025) + 0.5 * saw(f * vib * 2, t, 14, 0.001)
    x = lowpass(x, cutoff) * adsr(len(t), min(1.8, dur * 0.35), 0.4, 0.9, min(2.0, dur * 0.4))
    return x * vel * 0.14

def bass(note, dur, vel=0.8):
    t = times(dur + 0.2); f = midi(note)
    x = np.sin(2 * math.pi * f * t) + 0.35 * np.sin(2 * math.pi * 2 * f * t) * np.exp(-t * 6)
    x += 0.25 * saw(f, t, 8) * np.exp(-t * 5)
    x *= adsr(len(t), 0.006, 0.12, 0.7, 0.15) * np.exp(-t * 1.2)
    return x * vel * 0.55

def pluck(note, dur, vel=0.6):
    t = times(dur + 0.3); f = midi(note)
    x = lowpass(saw(f, t, 30), 2600) * np.exp(-t * 7.5) * adsr(len(t), 0.002, 0.0, 1.0, 0.1)
    return x * vel * 0.5

def brass(note, dur, vel=0.6):
    t = times(dur); f = midi(note)
    x = saw(f, t, 30, 0.003) + saw(f, t, 30, -0.002) + 0.5 * saw(f * 2, t, 16)
    spec = np.fft.rfft(x); fr = np.fft.rfftfreq(len(x), 1 / SR)
    spec *= 1 / np.sqrt(1 + (fr / 1800) ** 4)
    x = np.fft.irfft(spec, n=len(x)) * adsr(len(t), 0.25, 0.3, 0.9, min(1.5, dur * 0.5))
    return x * vel * 0.2

def noise_hit(dur, cutoff, decay, vel=0.3, highpass=None):
    t = times(dur)
    x = rng.standard_normal(len(t)) * np.exp(-t * decay)
    x = lowpass(x, cutoff)
    if highpass:
        x -= lowpass(x, highpass)
    return x * vel

def timpani(note, vel=0.7):
    t = times(2.2); f = midi(note)
    sweep = f * (1 + 0.5 * np.exp(-t * 28))
    phase = 2 * math.pi * np.cumsum(sweep) / SR
    x = np.sin(phase) * np.exp(-t * 2.2) + 0.4 * np.sin(phase * 1.5) * np.exp(-t * 6)
    x += 0.5 * noise_hit(2.2, 500, 18, 1.0)[:len(t)] * np.exp(-t * 9)
    return x * vel * 0.7

def gavel(vel=1.0):
    t = times(0.5)
    x = noise_hit(0.5, 1800, 22, 1.0) + 0.7 * np.sin(2 * math.pi * 180 * t) * np.exp(-t * 35)
    x += 0.4 * noise_hit(0.5, 6000, 60, 1.0)
    return x * vel * 0.8

# ----------------------------------------------------------------- mixer
class Mix:
    def __init__(self, seconds):
        self.n = int(seconds * SR)
        self.L = np.zeros(self.n); self.R = np.zeros(self.n)
    def add(self, x, at, pan=0.0, gain=1.0):
        start = int(at * SR); end = min(self.n, start + len(x))
        if start >= self.n: return
        seg = x[: end - start] * gain
        lg, rg = math.cos((pan + 1) * math.pi / 4), math.sin((pan + 1) * math.pi / 4)
        self.L[start:end] += seg * lg; self.R[start:end] += seg * rg
    def write(self, path):
        peak = max(np.abs(self.L).max(), np.abs(self.R).max(), 1e-9)
        L, R = np.tanh(self.L / peak * 1.6) * 0.9, np.tanh(self.R / peak * 1.6) * 0.9
        data = (np.stack([L, R], axis=1) * 32767).astype(np.int16)
        with wave.open(path, "wb") as w:
            w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR); w.writeframes(data.tobytes())

def encode(wav, ogg, loop=True):
    reverb = "aecho=0.72:0.5:38|91|163:0.22|0.16|0.1"
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", wav, "-af",
                    f"{reverb},lowpass=f=15000,loudnorm=I=-17:TP=-1.5:LRA=9",
                    "-c:a", "libvorbis", "-q:a", "5", ogg], check=True)

# ----------------------------------------------------------------- tracks
def valence():
    bpm, bars = 84, 16
    beat = 60 / bpm; bar = beat * 4
    m = Mix(bars * bar + 3)
    chords = [[62, 65, 69, 72], [58, 62, 65, 69], [53, 57, 60, 64], [60, 64, 67, 74]]  # Dm7 Bbmaj7 Fmaj7 Cadd9
    bass_roots = [38, 46, 41, 36]
    for b in range(bars):
        ch = chords[b % 4]; t0 = b * bar
        for i, n in enumerate(ch):
            m.add(pad(n - 12 if i == 0 else n, bar * 1.05, 0.5, 1300, 0.9), t0, pan=(-0.4 + 0.27 * i))
        m.add(bass(bass_roots[b % 4], beat * 1.6, 0.8), t0)
        m.add(bass(bass_roots[b % 4], beat * 1.4, 0.6), t0 + 2 * beat)
        if b % 2 == 1:
            m.add(bass(bass_roots[b % 4] + 7, beat * 0.8, 0.5), t0 + 3.5 * beat)
        # swung eighth-note arpeggio
        pattern = [0, 2, 1, 3, 2, 0, 3, 1]
        for k, idx in enumerate(pattern):
            note = ch[idx] + (12 if k in (3, 7) else 0)
            swing = 0.06 * beat if k % 2 else 0
            vel = 0.75 if k % 4 == 0 else 0.5
            m.add(ep(note, beat * 0.9, vel), t0 + k * beat / 2 + swing, pan=0.25 * math.sin(k))
        # brushed hat on 2 and 4
        for k in (1, 3):
            m.add(noise_hit(0.12, 6000, 40, 0.05, highpass=2500), t0 + k * beat, pan=0.3)
    # melody in bars 5-8 and 13-16
    melody = [(74, 1.5), (72, 0.5), (69, 1.0), (72, 1.0), (77, 2.0), (76, 1.0), (72, 1.0),
              (74, 1.5), (69, 0.5), (65, 2.0), (67, 1.0), (69, 1.0), (72, 3.0), (0, 1.0)]
    for start_bar in (4, 12):
        t = start_bar * bar
        for note, beats in melody:
            if note: m.add(ep(note + 12, beats * beat, 0.62), t, pan=-0.15)
            t += beats * beat
    return m

def case_file():
    bpm, bars = 98, 16
    beat = 60 / bpm; bar = beat * 4
    m = Mix(bars * bar + 3)
    chords = [[57, 60, 64, 67], [53, 57, 60, 64], [50, 53, 57, 60], [52, 56, 59, 62]]  # Am7 Fmaj7 Dm7 E7
    roots = [33, 29, 26, 28]
    for b in range(bars):
        ch = chords[b % 4]; t0 = b * bar; root = roots[b % 4]
        m.add(pad(ch[0], bar * 1.02, 0.55, 900 + 60 * (b % 8), 1.4), t0, pan=-0.2)
        m.add(pad(ch[2], bar * 1.02, 0.4, 900, 1.4), t0, pan=0.3)
        for k in range(8):  # pulsing bass eighths
            note = root if k % 2 == 0 else root + 12
            m.add(bass(note, beat * 0.45, 0.85 if k == 0 else 0.6), t0 + k * beat / 2)
        for k in range(16):  # muted pluck ostinato in sixteenths
            idx = [0, 2, 3, 2][k % 4]
            vel = 0.55 if k % 4 == 0 else 0.3
            if b >= 4 or k % 2 == 0:
                m.add(pluck(ch[idx] + 12, beat * 0.3, vel), t0 + k * beat / 4, pan=0.35 * math.sin(k * 0.9))
        for k in (1, 3):  # rim click
            m.add(noise_hit(0.05, 3200, 90, 0.18, highpass=800), t0 + k * beat, pan=-0.25)
        if b % 4 == 3:  # swell into the next phrase
            m.add(strings(ch[1] + 12, bar * 1.2, 0.35, 1800), t0 + bar * 0.4, pan=0.1)
    return m

def northbridge():
    bpm, bars = 66, 12
    beat = 60 / bpm; bar = beat * 4
    m = Mix(bars * bar + 4)
    chords = [[48, 51, 55], [44, 48, 51], [41, 44, 48], [43, 47, 50]]  # Cm Ab Fm G
    for b in range(bars):
        ch = chords[b % 4]; t0 = b * bar
        m.add(strings(ch[0] - 12, bar * 1.1, 0.6, 1400), t0, pan=-0.1)  # cello
        for i, n in enumerate(ch):
            m.add(strings(n, bar * 1.1, 0.45, 2000), t0, pan=(-0.5 + 0.5 * i))
        if b % 2 == 0:
            m.add(timpani(ch[0] - 24, 0.75), t0)
        if b >= 4:  # tremolo violins build
            t = times(bar * 1.1)
            trem = strings(ch[2] + 24, bar * 1.1, 0.22 + 0.03 * (b - 4), 3200)
            trem = trem[: len(t)] * (0.65 + 0.35 * np.sign(np.sin(2 * math.pi * 8 * t)))
            m.add(trem, t0, pan=0.45)
        if b in (7, 11):
            m.add(gavel(0.5), t0 + 3.5 * beat, pan=0.2)
    return m

def verdict():
    m = Mix(7.5)
    m.add(gavel(1.0), 0.0)
    m.add(gavel(0.8), 0.28)
    steps = [([50, 53, 57], 0.0), ([46, 50, 53], 1.1), ([48, 52, 55], 2.2), ([50, 54, 57, 62], 3.3)]  # Dm Bb C -> D major
    for notes, at in steps:
        last = at == 3.3
        for i, n in enumerate(notes):
            m.add(brass(n, 3.8 if last else 1.5, 0.75 if last else 0.55), at, pan=(-0.4 + 0.3 * i))
            m.add(strings(n + 12, 3.8 if last else 1.5, 0.3, 2400), at, pan=(0.4 - 0.3 * i))
    for i, n in enumerate([74, 78, 81, 86]):
        m.add(ep(n, 1.8, 0.6), 3.4 + i * 0.11, pan=0.3 - 0.2 * i)
    m.add(timpani(26, 0.8), 3.3)
    return m

if __name__ == "__main__":
    for name, fn, loop in (("valence", valence, True), ("case-file", case_file, True),
                           ("northbridge", northbridge, True), ("verdict", verdict, False)):
        wav = os.path.join(OUT, name + ".wav"); ogg = os.path.join(OUT, name + ".ogg")
        fn().write(wav)
        encode(wav, ogg, loop)
        os.remove(wav)
        print("wrote", ogg)
