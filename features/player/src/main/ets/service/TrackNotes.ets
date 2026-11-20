import { util } from '@kit.ArkTS';
import { resourceManager } from '@kit.LocalizationKit';
import { Log } from '@cloudmusic/commons';

export interface TrackNote {
  id: number;
  genre: string;
  tempo?: number;
  rhythm: string;
  introduction: string;
}

export class TrackNotes {
  private static readonly notes: Map<number, TrackNote> = new Map<number, TrackNote>();
  private static loaded: boolean = false;

  static load(resources: resourceManager.ResourceManager): void {
    if (TrackNotes.loaded) {
      return;
    }
    try {
      const bytes = resources.getRawFileContentSync('track-notes.json');
      const notes = JSON.parse(util.TextDecoder.create('utf-8').decodeToString(bytes)) as TrackNote[];
      for (const note of notes) {
        TrackNotes.notes.set(note.id, note);
      }
      TrackNotes.loaded = true;
    } catch (_) {
      Log.warning('Player', 'Unable to read bundled track notes');
    }
  }

  static find(id: number): TrackNote | undefined {
    return TrackNotes.notes.get(id);
  }
}
