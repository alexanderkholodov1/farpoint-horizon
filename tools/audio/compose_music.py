"""Composes the game's music (issue #12): synthesized here, no samples, nothing from outside.

Run:  python tools/audio/compose_music.py
Writes audio/music_horizon.ogg, a 46-second loop (16 bars) that joins without a seam: the reverb is applied around the loop
(circular convolution), so its tail flows back into the start. Needs numpy and ffmpeg (libvorbis).

The piece, "Horizon": 84 bpm, in D. Four chords of four bars each (Dmaj9, Bm9, Gmaj9, A6sus2), a pad of slightly
detuned saw waves through a soft low-pass that opens and closes over the loop, a warm sub bass on the roots, and a
quiet bell melody on the D major pentatonic that answers itself, all in a long stereo hall. Quiet by design: it sits
under the game's sounds.
"""
import os
import subprocess

import numpy as np

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT_DIR = os.path.join(ROOT, "audio")
WAV = os.path.join(ROOT, "build", "music_horizon.wav")
OGG = os.path.join(OUT_DIR, "music_horizon.ogg")

SR = 44100
BPM = 84.0
BEAT = 60.0 / BPM
BAR = 4 * BEAT
CHORDS = [  # MIDI notes, root first
    [38, 57, 61, 64, 66, 69],   # Dmaj9: D2 | A3 C#4 E4 F#4 A4
    [35, 54, 57, 61, 62, 66],   # Bm9:   B1 | F#3 A3 C#4 D4 F#4
    [31, 50, 54, 57, 59, 62],   # Gmaj9: G1 | D3 F#3 A3 B3 D4
    [33, 52, 57, 59, 61, 64],   # A6sus2: A1 | E3 A3 B3 C#4 E4
]
BARS_PER_CHORD = 4
N = int(round(len(CHORDS) * BARS_PER_CHORD * BAR * SR))
LOOP_S = N / SR
rng = np.random.default_rng(7)
t = np.arange(N) / SR


def hz(m):
    return 440.0 * 2.0 ** ((m - 69) / 12.0)


def lowpass(x, cut):
    """One-pole low-pass with a cutoff (Hz) that may change per sample, run in blocks."""
    y = np.empty_like(x)
    a = 1.0 - np.exp(-2.0 * np.pi * np.broadcast_to(cut, x.shape) / SR)
    s = 0.0
    for i in range(len(x)):
        s += a[i] * (x[i] - s)
        y[i] = s
    return y


def saw(f, phase=0.0):
    # band-limited enough at these pitches: a few harmonics with 1/n weights
    out = np.zeros(N)
    for n in range(1, 9):
        out += np.sin(2 * np.pi * f * n * t + phase * n) / n
    return out


def env_segments(starts, length, attack, release):
    """1 inside each [start, start+length), with soft attack and release, wrapping around the loop."""
    e = np.zeros(N)
    for s in starts:
        i0 = int(s * SR)
        L = int(length * SR)
        a = int(attack * SR)
        r = int(release * SR)
        seg = np.ones(L)
        seg[:a] = np.sin(np.linspace(0, np.pi / 2, a)) ** 2
        seg[L - r:] *= np.cos(np.linspace(0, np.pi / 2, r)) ** 2
        idx = (np.arange(L) + i0) % N
        e[idx] += seg
    return e


def pad():
    left = np.zeros(N)
    right = np.zeros(N)
    span = BARS_PER_CHORD * BAR
    for ci, ch in enumerate(CHORDS):
        e = env_segments([ci * span], span + 1.5, 1.8, 2.2)   # chords overlap a little at the changes
        for m in ch[1:]:
            f = hz(m)
            det = 0.0035
            vl = saw(f * (1 - det), rng.uniform(0, 6.28)) + saw(f * (1 + det * 0.6), rng.uniform(0, 6.28))
            vr = saw(f * (1 + det), rng.uniform(0, 6.28)) + saw(f * (1 - det * 0.6), rng.uniform(0, 6.28))
            left += vl * e
            right += vr * e
    # the filter breathes once over the loop
    cut = 700.0 + 900.0 * (0.5 - 0.5 * np.cos(2 * np.pi * t / LOOP_S))
    return lowpass(left, cut) * 0.05, lowpass(right, cut) * 0.05


def bass():
    out = np.zeros(N)
    span = BARS_PER_CHORD * BAR
    for ci, ch in enumerate(CHORDS):
        for b in range(BARS_PER_CHORD):
            start = ci * span + b * BAR
            e = env_segments([start], BAR * 0.95, 0.08, 1.2)
            f = hz(ch[0])
            out += (np.sin(2 * np.pi * f * t) + 0.25 * np.sin(4 * np.pi * f * t)) * e
    return out * 0.10


def bells():
    """A pentatonic melody that answers itself: a phrase, then its echo a fifth lower and softer."""
    scale = [62, 64, 66, 69, 71, 74, 76, 78, 81]   # D major pentatonic, D4 to A5
    phrase = [(0, 5), (1.5, 4), (2, 6), (3, 5), (5, 3), (6, 4), (7.5, 2)]   # (beat, scale degree)
    left = np.zeros(N)
    right = np.zeros(N)
    span = BARS_PER_CHORD * BAR
    for ci in range(len(CHORDS)):
        for half, (shift, gain) in enumerate([(0, 1.0), (-3, 0.55)]):
            base = ci * span + half * 2 * BAR + BAR * 0.5
            for beat, deg in phrase:
                d = min(max(deg + shift + (ci % 2), 0), len(scale) - 1)
                f = hz(scale[d])
                st = base + beat * BEAT
                i0 = int(st * SR)
                L = int(3.5 * SR)
                tt = np.arange(L) / SR
                tone = (np.sin(2 * np.pi * f * tt) + 0.35 * np.sin(2 * np.pi * f * 2.0 * tt) * np.exp(-tt * 3)
                        + 0.12 * np.sin(2 * np.pi * f * 3.01 * tt) * np.exp(-tt * 6))
                tone *= np.exp(-tt * 1.6) * np.minimum(1.0, tt / 0.004) * gain
                pan = 0.5 + 0.35 * np.sin(st * 1.3)
                idx = (np.arange(L) + i0) % N
                left[idx] += tone * (1 - pan)
                right[idx] += tone * pan
    return left * 0.07, right * 0.07


def hall(x, seconds=4.5, seed=1):
    """A long hall: decaying stereo noise as impulse, convolved around the loop (FFT), so the loop has no seam."""
    r = np.random.default_rng(seed)
    L = int(seconds * SR)
    ir = r.standard_normal(L) * np.exp(-np.arange(L) / SR * 6.9 / seconds)
    ir = lowpass(ir, 5000.0)
    ir[: int(0.012 * SR)] = 0.0
    ir /= np.sqrt(np.sum(ir ** 2))
    h = np.zeros(N)
    h[:L] = ir
    return np.real(np.fft.ifft(np.fft.fft(x) * np.fft.fft(h)))


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    os.makedirs(os.path.dirname(WAV), exist_ok=True)
    pl, pr = pad()
    bl, br = bells()
    b = bass()
    dry_l = pl + bl + b
    dry_r = pr + br + b
    wet_l = hall(pl + bl * 1.3, seed=1)
    wet_r = hall(pr + br * 1.3, seed=2)
    left = dry_l * 0.55 + wet_l * 0.9
    right = dry_r * 0.55 + wet_r * 0.9
    st = np.stack([left, right], axis=1)
    st /= np.max(np.abs(st)) / 0.8
    pcm = (st * 32767).astype(np.int16)
    import wave
    with wave.open(WAV, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", WAV, "-c:a", "libvorbis", "-q:a", "4", OGG], check=True)
    print("wrote", OGG, "%.1f s" % LOOP_S, os.path.getsize(OGG) // 1024, "KB")


if __name__ == "__main__":
    main()
