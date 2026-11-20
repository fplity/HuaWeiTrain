import { resourceManager } from '@kit.LocalizationKit';
import { Log, Song } from '@cloudmusic/commons';

const BAND_COUNT: number = 8;
const FRAME_BYTES: number = 4;
const HEADER_BYTES: number = 12;
const INDEX_RECORD_BYTES: number = 12;
const SPECTRUM_MAGIC: number = 0x31305145; // EQ01

export class SpectrumFrames {
  private readonly packed: Uint8Array;
  private readonly framePeriodMs: number;

  constructor(packed: Uint8Array, framePeriodMs: number) {
    this.packed = packed;
    this.framePeriodMs = framePeriodMs;
  }

  private value(frame: number, band: number): number {
    const byte = this.packed[frame * FRAME_BYTES + Math.floor(band / 2)];
    return (band % 2 === 0 ? byte & 15 : byte >> 4) / 15;
  }

  at(positionMs: number): number[] {
    const lastFrame = this.packed.length / FRAME_BYTES - 1;
    const position = Math.min(lastFrame, Math.max(0, positionMs / this.framePeriodMs));
    const lower = Math.floor(position);
    const upper = Math.min(lastFrame, lower + 1);
    const t = position - lower;
    const levels: number[] = [];
    for (let band = 0; band < BAND_COUNT; band++) {
      const from = this.value(lower, band);
      levels.push(from + (this.value(upper, band) - from) * t);
    }
    return levels;
  }
}

export class TrackSpectrum {
  private static loaded: boolean = false;
  private static readonly profiles = new Map<number, SpectrumFrames>();

  static load(resources: resourceManager.ResourceManager): void {
    if (TrackSpectrum.loaded) {
      return;
    }
    TrackSpectrum.loaded = true;
    try {
      const bytes = resources.getRawFileContentSync('track-spectrum.bin');
      const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
      if (bytes.length < HEADER_BYTES || view.getUint32(0, true) !== SPECTRUM_MAGIC) {
        return;
      }
      const period = view.getUint32(4, true);
      const count = view.getUint32(8, true);
      const indexEnd = HEADER_BYTES + count * INDEX_RECORD_BYTES;
      if (period === 0 || indexEnd > bytes.length) {
        return;
      }
      for (let i = 0; i < count; i++) {
        const index = HEADER_BYTES + i * INDEX_RECORD_BYTES;
        const songId = view.getUint32(index, true);
        const frames = view.getUint32(index + 4, true);
        const offset = view.getUint32(index + 8, true);
        const end = offset + frames * FRAME_BYTES;
        if (frames > 0 && offset >= indexEnd && end <= bytes.length) {
          TrackSpectrum.profiles.set(songId, new SpectrumFrames(bytes.subarray(offset, end), period));
        }
      }
    } catch (_) {
      Log.warning('Player', 'Unable to read bundled spectrum data');
    }
  }

  static forSong(song: Song | undefined): SpectrumFrames | undefined {
    if (song && song.playUrl === 'rawfile:track-' + song.id.toString() + '.mp3') {
      return TrackSpectrum.profiles.get(song.id);
    }
    return undefined;
  }
}
