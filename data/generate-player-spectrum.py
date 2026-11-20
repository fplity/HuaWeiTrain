"""Generate the player's timed spectrum from the bundled MP3 files.

Run with Python and the numpy and imageio-ffmpeg packages installed.
"""
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import json
import re
import struct
import subprocess

import numpy as np
from imageio_ffmpeg import get_ffmpeg_exe


ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "features/home/src/main/resources/rawfile/catalog-seed.json"
RAWFILE = ROOT / "features/player/src/main/resources/rawfile"
SAMPLE_RATE = 22050
PERIOD_MS = 40
HOP = SAMPLE_RATE * PERIOD_MS // 1000
WINDOW_SIZE = 2048
BANDS = ((35, 100), (100, 220), (220, 440), (440, 900),
         (900, 1800), (1800, 3600), (3600, 6200), (6200, 10100))


def measure_track(track):
    track_id = track["id"]
    name = track["playUrl"].removeprefix("rawfile:")
    if not re.fullmatch(r"track-\d+\.mp3", name):
        raise ValueError(f"Unsupported local audio name for {track_id}")
    command = [get_ffmpeg_exe(), "-nostdin", "-v", "error", "-i", str(RAWFILE / name),
               "-ac", "1", "-ar", str(SAMPLE_RATE), "-f", "f32le", "-"]
    samples = np.frombuffer(subprocess.check_output(command), dtype="<f4")
    if not len(samples):
        raise ValueError(f"Empty audio for {track_id}")
    padding = WINDOW_SIZE // 2
    windows = np.lib.stride_tricks.sliding_window_view(
        np.pad(samples, (padding, padding - 1)), WINDOW_SIZE)[::HOP]
    spectrum = np.abs(np.fft.rfft(windows * np.hanning(WINDOW_SIZE), axis=1))
    hz = np.fft.rfftfreq(WINDOW_SIZE, d=1 / SAMPLE_RATE)
    levels = np.column_stack([
        np.sqrt(np.mean(spectrum[:, (hz >= low) & (hz < high)] ** 2, axis=1))
        for low, high in BANDS
    ])
    relative_db = 20 * np.log10(np.maximum(levels, 1e-5))
    band_reference = np.percentile(relative_db, 93, axis=0)
    band_activity = np.clip((relative_db - band_reference + 27) / 27, 0, 1) ** 1.35

    rms = np.sqrt(np.mean(windows ** 2, axis=1))
    audible = np.clip((20 * np.log10(np.maximum(rms, 1e-5)) + 48) / 30, 0, 1)
    combined = band_activity * audible[:, None]
    for index in range(1, len(combined)):
        combined[index] = np.maximum(combined[index], combined[index - 1] * 0.72)

    quantized = np.rint(combined * 15).astype(np.uint8)
    packed = quantized[:, 0::2] | (quantized[:, 1::2] << 4)
    return track_id, len(packed), packed.tobytes()


def main():
    tracks = json.loads(CATALOG.read_text(encoding="utf-8"))
    with ThreadPoolExecutor(max_workers=3) as executor:
        measured = list(executor.map(measure_track, tracks))

    # Versioned header, followed by (song ID, frame count, absolute byte offset).
    header = bytearray(struct.pack("<4sII", b"EQ01", PERIOD_MS, len(measured)))
    position = len(header) + 12 * len(measured)
    for track_id, frame_count, packed in measured:
        header.extend(struct.pack("<III", track_id, frame_count, position))
        position += len(packed)
    path = RAWFILE / "track-spectrum.bin"
    path.write_bytes(bytes(header) + b"".join(packed for _, _, packed in measured))
    print(f"{len(measured)} tracks, {sum(count for _, count, _ in measured)} frames, {position} bytes")


if __name__ == "__main__":
    main()
