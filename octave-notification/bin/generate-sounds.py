#!/usr/bin/env python3
# /// script
# requires-python = ">=3.9"
# ///
"""Generate bell-like notification WAV files.

Index 0 = B3 (one note below C4), then index 1-21 = C4 through B6.
Do-Re-Mi-Fa-So-La-Ti (7 notes) x 3 octaves + 1 leading note = 22 files.
Each file corresponds to a tmux window index (0-21).
Uses only Python standard library (wave, struct, math).
"""

import math
import os
import struct
import wave

SAMPLE_RATE = 44100
DURATION = 0.4  # seconds
AMPLITUDE = 0.6

# Derive C4 from the A4 = 440 Hz concert pitch (ISO 16) standard.
# C4 is 9 semitones below A4: 440 / 2**(9/12) = 261.6256 Hz.
A4_FREQ = 440.0
BASE_FREQ = A4_FREQ * (2 ** (-9 / 12.0))

# Major scale semitone offsets: C D E F G A B
MAJOR_SCALE = [0, 2, 4, 5, 7, 9, 11]
NOTE_NAMES = ["C", "D", "E", "F", "G", "A", "B"]


def generate_bell_tone(freq: float) -> bytes:
    """Generate a bell-like tone with harmonics and exponential decay."""
    n_samples = int(SAMPLE_RATE * DURATION)
    samples = []

    harmonics = [
        (1.0, 1.0),  # fundamental
        (2.0, 0.5),  # octave
        (3.0, 0.3),  # fifth above octave
        (5.0, 0.1),  # two octaves + major third
    ]

    for i in range(n_samples):
        t = i / SAMPLE_RATE
        envelope = math.exp(-t * 8.0)

        sample = 0.0
        for harmonic_mult, harmonic_amp in harmonics:
            h_envelope = math.exp(-t * 8.0 * harmonic_mult * 0.5)
            sample += (
                harmonic_amp
                * h_envelope
                * math.sin(2 * math.pi * freq * harmonic_mult * t)
            )

        sample *= envelope * AMPLITUDE
        sample = max(-1.0, min(1.0, sample))
        samples.append(struct.pack("<h", int(sample * 32767)))

    return b"".join(samples)


def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    sounds_dir = os.path.join(script_dir, "..", "sounds")
    os.makedirs(sounds_dir, exist_ok=True)

    index = 0

    # Index 0: B3 (one note below C4)
    b3_semitones = -1  # B3 is 1 semitone below C4
    b3_freq = BASE_FREQ * (2 ** (b3_semitones / 12.0))
    filename = os.path.join(sounds_dir, f"bell_{index}.wav")
    data = generate_bell_tone(b3_freq)
    with wave.open(filename, "w") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(data)
    print(f"bell_{index:>2}.wav  B3   {b3_freq:7.2f} Hz")
    index += 1

    # Index 1-21: C4-B6 (3 octaves)
    for octave in range(3):
        for note_idx, semitone in enumerate(MAJOR_SCALE):
            total_semitones = octave * 12 + semitone
            freq = BASE_FREQ * (2 ** (total_semitones / 12.0))
            note_name = f"{NOTE_NAMES[note_idx]}{4 + octave}"
            filename = os.path.join(sounds_dir, f"bell_{index}.wav")

            data = generate_bell_tone(freq)

            with wave.open(filename, "w") as wf:
                wf.setnchannels(1)
                wf.setsampwidth(2)
                wf.setframerate(SAMPLE_RATE)
                wf.writeframes(data)

            print(f"bell_{index:>2}.wav  {note_name:<3}  {freq:7.2f} Hz")
            index += 1

    print(f"\nGenerated {index} files in {sounds_dir}")


if __name__ == "__main__":
    main()
