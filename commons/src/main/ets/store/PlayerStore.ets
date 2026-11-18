import { Song } from '../model/Song';

export type PlaybackStatus = 'idle' | 'loading' | 'playing' | 'paused' | 'completed' | 'error';

@ObservedV2
export class PlayerStore {
  @Trace queue: Song[] = [];
  @Trace currentIndex: number = -1;
  @Trace status: PlaybackStatus = 'idle';
  @Trace error: string = '';
  @Trace positionMs: number = 0;
  @Trace durationMs: number = 0;

  get current(): Song | undefined {
    return this.queue[this.currentIndex];
  }
}
