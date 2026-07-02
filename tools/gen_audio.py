"""Generate the placeholder SFX set as original synthesized WAVs.

Every sound in assets/audio/ is produced by this script — no external or
licensed material. Re-run after tweaking: python tools/gen_audio.py
"""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 22050
OUT = Path(__file__).resolve().parent.parent / "assets" / "audio"


def write(name, samples):
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / name), "w") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(b"".join(
            struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32000)) for s in samples))
    print("wrote", name)


def env(i, n, attack=0.01, release=0.3):
    t = i / RATE
    total = n / RATE
    a = min(t / attack, 1.0) if attack > 0 else 1.0
    r = min((total - t) / release, 1.0) if release > 0 else 1.0
    return a * min(r, 1.0)


def wave_loop():
    """Seamless shore-wash loop: slow amplitude swell over filtered noise."""
    rng = random.Random(7)
    n = RATE * 4
    out, low = [], 0.0
    for i in range(n):
        low += 0.02 * (rng.uniform(-1, 1) - low)  # one-pole lowpass noise
        swell = 0.55 + 0.45 * math.sin(2 * math.pi * i / n)  # period = loop length
        out.append(low * swell * 0.8)
    return out


def foghorn():
    n = int(RATE * 1.6)
    out = []
    for i in range(n):
        t = i / RATE
        s = 0.6 * math.sin(2 * math.pi * 110 * t) + 0.35 * math.sin(2 * math.pi * 165 * t)
        s += 0.1 * math.sin(2 * math.pi * 55 * t)
        out.append(s * env(i, n, 0.08, 0.5) * 0.7)
    return out


def rifle_crack():
    rng = random.Random(3)
    n = int(RATE * 0.3)
    out = []
    for i in range(n):
        t = i / RATE
        noise = rng.uniform(-1, 1) * math.exp(-t * 28)
        thump = 0.5 * math.sin(2 * math.pi * 75 * t) * math.exp(-t * 18)
        out.append((noise * 0.8 + thump) * 0.9)
    return out


def perfect_ding():
    n = int(RATE * 0.6)
    out = []
    for i in range(n):
        t = i / RATE
        s = math.sin(2 * math.pi * 1320 * t) + 0.5 * math.sin(2 * math.pi * 1980 * t)
        s += 0.25 * math.sin(2 * math.pi * 2640 * t)
        out.append(s * math.exp(-t * 7) * 0.5)
    return out


def hull_crunch():
    rng = random.Random(11)
    n = int(RATE * 0.45)
    out, low = [], 0.0
    for i in range(n):
        t = i / RATE
        low += 0.12 * (rng.uniform(-1, 1) - low)
        groan = 0.4 * math.sin(2 * math.pi * (90 - 40 * t) * t)
        out.append((low * 1.2 + groan) * math.exp(-t * 9) * 0.95)
    return out


def mine_thump():
    n = int(RATE * 0.35)
    out = []
    for i in range(n):
        t = i / RATE
        freq = 90 * math.exp(-t * 6) + 35  # falling pitch
        out.append(math.sin(2 * math.pi * freq * t) * math.exp(-t * 10) * 0.95)
    return out


def ui_click():
    n = int(RATE * 0.05)
    out = []
    for i in range(n):
        t = i / RATE
        out.append(math.sin(2 * math.pi * 1000 * t) * math.exp(-t * 90) * 0.5)
    return out


write("wave_loop.wav", wave_loop())
write("foghorn.wav", foghorn())
write("rifle_crack.wav", rifle_crack())
write("perfect_ding.wav", perfect_ding())
write("hull_crunch.wav", hull_crunch())
write("mine_thump.wav", mine_thump())
write("ui_click.wav", ui_click())
