import { common } from '@kit.AbilityKit';
import { audio } from '@kit.AudioKit';
import { media } from '@kit.MediaKit';
import { resourceManager } from '@kit.LocalizationKit';
import { AppContext, PlayerStore, Song } from '@cloudmusic/commons';
import { MediaSessionService } from './MediaSessionService';

interface RawSource {
  manager: resourceManager.ResourceManager;
  name: string;
}

interface PlayerTransition {
  player: media.AVPlayer;
  expected: media.AVPlayerState;
  finish: (error?: Error) => void;
}

export class PlayerService {
  static readonly store: PlayerStore = new PlayerStore();
  private static readonly mediaSession: MediaSessionService = new MediaSessionService();
  private static manager: resourceManager.ResourceManager | undefined;
  private static player: media.AVPlayer | undefined;
  private static rawSource: RawSource | undefined;
  private static pending: Promise<void> = Promise.resolve();
  private static requestId: number = 0;
  private static activeRequest: number = 0;
  private static transition: PlayerTransition | undefined;
  private static seekReady: ((position?: number) => void) | undefined;

  static attach(context: common.UIAbilityContext): void {
    PlayerService.manager = context.resourceManager;
    PlayerService.mediaSession.attach(context, {
      play: () => { PlayerService.resume().catch(() => {}); },
      pause: () => { PlayerService.pause().catch(() => {}); },
      previous: () => { PlayerService.skip(-1).catch(() => {}); },
      next: () => { PlayerService.skip(1).catch(() => {}); },
      seek: (position: number) => { PlayerService.seekTo(position).catch(() => {}); },
      stop: () => { PlayerService.clear(); }
    });
  }

  static detach(context: common.UIAbilityContext): void {
    PlayerService.clear();
    PlayerService.enqueue(async () => {
      PlayerService.mediaSession.detach(context);
    });
  }

  static playAll(songs: Song[], manager?: resourceManager.ResourceManager): Promise<void> {
    if (AppContext.session.current?.user.role !== 'listener' || !songs.length) {
      return Promise.reject(new Error('歌单没有可加入队列的歌曲。'));
    }
    if (manager) {
      PlayerService.manager = manager;
    }
    PlayerService.store.queue = songs.slice();
    return PlayerService.select(0);
  }

  static skip(direction: number): Promise<void> {
    const store = PlayerService.store;
    const count = store.queue.length;
    if (!count || (direction !== -1 && direction !== 1)) {
      return Promise.resolve();
    }
    return PlayerService.select((store.currentIndex + direction + count) % count);
  }

  static togglePlayPause(): Promise<void> {
    return PlayerService.store.status === 'playing' ? PlayerService.pause() : PlayerService.resume();
  }

  static seekTo(value: number): Promise<void> {
    const store = PlayerService.store;
    if (!store.current || store.durationMs <= 0 || !Number.isFinite(value)) {
      return Promise.resolve();
    }
    const id = PlayerService.requestId;
    const target = Math.round(Math.max(0, Math.min(value, store.durationMs)));
    return PlayerService.enqueue(async () => {
      const player = PlayerService.player;
      if (!player || id !== PlayerService.requestId || (player.state !== 'playing' && player.state !== 'paused')) {
        return;
      }
      await new Promise<void>((resolve) => {
        const timer = setTimeout(() => { PlayerService.seekReady?.(); }, 3000);
        PlayerService.seekReady = (position?: number) => {
          clearTimeout(timer);
          PlayerService.seekReady = undefined;
          if (id === PlayerService.requestId && position !== undefined && Number.isFinite(position)) {
            store.positionMs = Math.max(0, Math.min(position, store.durationMs));
            PlayerService.mediaSession.publish(store);
          }
          resolve();
        };
        try {
          player.seek(target, media.SeekMode.SEEK_CLOSEST);
        } catch (_) {
          PlayerService.seekReady?.();
        }
      });
    });
  }

  static clear(): void {
    ++PlayerService.requestId;
    PlayerService.cancelPendingSource();
    const store = PlayerService.store;
    store.queue = [];
    store.currentIndex = -1;
    store.positionMs = 0;
    store.durationMs = 0;
    store.status = 'idle';
    store.error = '';
    PlayerService.enqueue(async () => {
      try {
        await PlayerService.release();
      } finally {
        PlayerService.mediaSession.clear();
      }
    });
  }

  private static enqueue(action: () => Promise<void>): Promise<void> {
    const operation = PlayerService.pending.then(action);
    PlayerService.pending = operation.catch(() => {});
    return operation;
  }

  private static cancelPendingSource(): void {
    const transition = PlayerService.transition;
    if (transition?.expected === 'initialized') {
      transition.finish(new Error('音源已切换。'));
    }
    PlayerService.seekReady?.();
  }

  private static select(index: number): Promise<void> {
    const session = AppContext.session.current;
    const store = PlayerService.store;
    const song = store.queue[index];
    if (!session || session.user.role !== 'listener' || !song) {
      return Promise.resolve();
    }
    const id = ++PlayerService.requestId;
    PlayerService.cancelPendingSource();
    store.currentIndex = index;
    store.positionMs = 0;
    store.durationMs = Number.isFinite(song.duration) ? Math.max(0, song.duration) : 0;
    store.status = 'loading';
    store.error = '';
    PlayerService.mediaSession.publish(store);
    return PlayerService.enqueue(async () => {
      if (id === PlayerService.requestId && AppContext.session.current === session) {
        await PlayerService.start(song, id);
      }
    });
  }

  private static resume(): Promise<void> {
    const store = PlayerService.store;
    if (!store.current || store.status === 'loading' || store.status === 'playing') {
      return Promise.resolve();
    }
    if (store.status === 'error' || store.status === 'completed') {
      return PlayerService.select(store.currentIndex);
    }
    return PlayerService.setPlaying(true);
  }

  private static pause(): Promise<void> {
    return PlayerService.setPlaying(false);
  }

  private static setPlaying(play: boolean): Promise<void> {
    const id = PlayerService.requestId;
    return PlayerService.enqueue(async () => {
      const player = PlayerService.player;
      if (!player || id !== PlayerService.requestId) {
        return;
      }
      try {
        if (play && player.state === 'paused') {
          await PlayerService.waitForState(player, 'playing', () => player.play());
        } else if (!play && player.state === 'playing') {
          await PlayerService.waitForState(player, 'paused', () => player.pause());
        }
      } catch (_) {
        if (id === PlayerService.requestId) {
          PlayerService.setError('无法切换播放状态，请重试。');
        }
      }
    });
  }

  private static async start(song: Song, id: number): Promise<void> {
    try {
      const player = await PlayerService.getPlayer();
      if (player.state !== 'idle') {
        await PlayerService.waitForState(player, 'idle', () => player.reset());
      }
      await PlayerService.closeRawSource();
      if (id !== PlayerService.requestId) {
        return;
      }

      const uri = song.playUrl?.trim() ?? '';
      const manager = PlayerService.manager;
      if (uri.startsWith('rawfile:') && manager) {
        const name = uri.substring('rawfile:'.length);
        if (!/^[a-zA-Z0-9_-]+\.[a-zA-Z0-9]+$/.test(name)) {
          throw new Error('本地音频文件名无效。');
        }
        const fd = await manager.getRawFd(name);
        PlayerService.rawSource = { manager: manager, name: name };
        if (id !== PlayerService.requestId) {
          await PlayerService.closeRawSource();
          return;
        }
        PlayerService.activeRequest = id;
        await PlayerService.waitForState(player, 'initialized', () => {
          player.fdSrc = { fd: fd.fd, offset: fd.offset, length: fd.length };
        });
      } else if (uri.startsWith('https://')) {
        PlayerService.activeRequest = id;
        await PlayerService.waitForState(player, 'initialized', () => { player.url = uri; });
      } else {
        throw new Error('此曲暂无可用的音源。');
      }
      if (id !== PlayerService.requestId) {
        return;
      }
      player.audioRendererInfo = { usage: audio.StreamUsage.STREAM_USAGE_MUSIC, rendererFlags: 0 };
      await PlayerService.waitForState(player, 'prepared', () => player.prepare());
      if (id === PlayerService.requestId) {
        await PlayerService.waitForState(player, 'playing', () => player.play());
      }
    } catch (error) {
      if (id === PlayerService.requestId) {
        const message = (error as Error).message || '无法播放此曲。';
        await PlayerService.release().catch(() => {});
        if (id === PlayerService.requestId) {
          PlayerService.setError(message);
          throw new Error(message);
        }
      }
    }
  }

  private static matches(player: media.AVPlayer): boolean {
    return PlayerService.player === player && PlayerService.activeRequest === PlayerService.requestId;
  }

  private static onStateChange(player: media.AVPlayer, state: media.AVPlayerState): void {
    const transition = PlayerService.transition;
    if (transition?.player === player && transition.expected === state) {
      transition.finish();
    }
    if (!PlayerService.matches(player)) {
      return;
    }
    const store = PlayerService.store;
    if (state === 'prepared' && Number.isFinite(player.duration) && player.duration > 0) {
      store.durationMs = player.duration;
    } else if (state === 'playing' || state === 'paused') {
      if (state === 'paused') {
        PlayerService.updatePosition(player.currentTime);
      }
      store.status = state;
      PlayerService.mediaSession.publish(store);
    } else if (state === 'completed' && store.status === 'playing') {
      store.positionMs = store.durationMs;
      store.status = 'completed';
      PlayerService.skip(1).catch(() => {});
    }
  }

  private static updatePosition(position: number): void {
    if (Number.isFinite(position)) {
      const store = PlayerService.store;
      store.positionMs = Math.max(0, store.durationMs > 0 ? Math.min(position, store.durationMs) : position);
    }
  }

  private static setError(message: string): void {
    const store = PlayerService.store;
    store.status = 'error';
    store.error = message;
    PlayerService.mediaSession.publish(store);
  }

  private static async getPlayer(): Promise<media.AVPlayer> {
    if (PlayerService.player) {
      return PlayerService.player;
    }
    const player = await media.createAVPlayer();
    PlayerService.player = player;
    player.on('stateChange', (state: media.AVPlayerState) => { PlayerService.onStateChange(player, state); });
    player.on('error', () => {
      const transition = PlayerService.transition;
      if (transition?.player === player) {
        transition.finish(new Error('播放设备未能完成状态切换。'));
      } else if (PlayerService.matches(player)) {
        PlayerService.seekReady?.();
        PlayerService.setError('播放时发生错误。');
      }
    });
    player.on('timeUpdate', (position: number) => {
      if (PlayerService.matches(player) && PlayerService.store.status === 'playing' && !PlayerService.seekReady) {
        PlayerService.updatePosition(position);
      }
    });
    player.on('durationUpdate', (duration: number) => {
      if (PlayerService.matches(player) && Number.isFinite(duration) && duration > 0) {
        PlayerService.store.durationMs = duration;
      }
    });
    player.on('seekDone', (position: number) => {
      if (PlayerService.matches(player)) {
        PlayerService.seekReady?.(position);
      }
    });
    player.on('audioInterrupt', (event: audio.InterruptEvent) => {
      if (!PlayerService.matches(player)) {
        return;
      }
      if (event.hintType === audio.InterruptHint.INTERRUPT_HINT_PAUSE && PlayerService.store.status === 'playing') {
        if (event.forceType === audio.InterruptForceType.INTERRUPT_FORCE) {
          PlayerService.updatePosition(player.currentTime);
          PlayerService.store.status = 'paused';
          PlayerService.mediaSession.publish(PlayerService.store);
        } else {
          PlayerService.pause().catch(() => {});
        }
      } else if (event.hintType === audio.InterruptHint.INTERRUPT_HINT_STOP) {
        PlayerService.clear();
      }
    });
    return player;
  }

  private static async waitForState(player: media.AVPlayer, expected: media.AVPlayerState,
    action: () => void | Promise<void>): Promise<void> {
    let finish: (error?: Error) => void = () => {};
    const arrival = new Promise<Error | undefined>((resolve) => {
      const timer = setTimeout(() => { finish(new Error('播放状态切换超时。')); }, 12000);
      finish = (error?: Error) => {
        clearTimeout(timer);
        if (PlayerService.transition?.finish === finish) {
          PlayerService.transition = undefined;
        }
        resolve(error);
      };
      PlayerService.transition = { player: player, expected: expected, finish: finish };
    });
    try {
      await action();
      // On some versions the command promise completes before the state callback.
      if (player.state === expected) {
        finish();
      }
      const failure = await arrival;
      if (failure) {
        throw failure;
      }
    } finally {
      finish();
    }
  }

  private static async closeRawSource(): Promise<void> {
    const source = PlayerService.rawSource;
    PlayerService.rawSource = undefined;
    if (source) {
      try {
        await source.manager.closeRawFd(source.name);
      } catch (_) {
        // AVPlayer can close the descriptor while resetting or releasing the source.
      }
    }
  }

  private static async release(): Promise<void> {
    const player = PlayerService.player;
    PlayerService.player = undefined;
    try {
      if (player && player.state !== 'released') {
        await player.release();
      }
    } finally {
      await PlayerService.closeRawSource();
    }
  }
}
