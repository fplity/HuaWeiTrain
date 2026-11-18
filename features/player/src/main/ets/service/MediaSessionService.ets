import { common, wantAgent, WantAgent } from '@kit.AbilityKit';
import { avSession } from '@kit.AVSessionKit';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { PlaybackStatus, PlayerStore, Song } from '@cloudmusic/commons';

export interface MediaCommands {
  play: () => void;
  pause: () => void;
  previous: () => void;
  next: () => void;
  seek: (position: number) => void;
  stop: () => void;
}

interface MediaSnapshot {
  song: Song;
  status: PlaybackStatus;
  duration: number;
  position: number;
}

const DOMAIN: number = 0x0021;
const TAG: string = 'HuaWeiTrainMedia';

export class MediaSessionService {
  private context: common.UIAbilityContext | undefined;
  private commands: MediaCommands | undefined;
  private session: avSession.AVSession | undefined;
  private launch: WantAgent | undefined;
  private background: boolean = false;
  private metadataKey: string = '';
  private pending: Promise<void> = Promise.resolve();

  attach(context: common.UIAbilityContext, commands: MediaCommands): void {
    this.context = context;
    this.commands = commands;
  }

  publish(store: PlayerStore): void {
    if (!store.current) {
      return;
    }
    const snapshot: MediaSnapshot = {
      song: store.current,
      status: store.status,
      duration: store.durationMs,
      position: store.positionMs
    };
    this.enqueue(() => this.apply(snapshot));
  }

  clear(): void {
    this.enqueue(() => this.close());
  }

  detach(context: common.UIAbilityContext): void {
    this.enqueue(async () => {
      if (this.context === context) {
        try {
          await this.close();
        } finally {
          this.context = undefined;
          this.commands = undefined;
        }
      }
    });
  }

  private enqueue(action: () => Promise<void>): void {
    this.pending = this.pending.then(action).catch((error: BusinessError) => {
      hilog.error(DOMAIN, TAG, 'Media session operation failed: %{public}d', error.code ?? -1);
    });
  }

  private async apply(snapshot: MediaSnapshot): Promise<void> {
    const context = this.context;
    if (!context || !this.commands || (!this.session && snapshot.status !== 'playing')) {
      return;
    }
    if (snapshot.status === 'paused' || snapshot.status === 'completed' || snapshot.status === 'error') {
      await this.stopBackground(context);
    }
    const session = this.session ?? await this.create(context, this.commands);
    const key = snapshot.song.id.toString() + ':' + snapshot.duration.toString() + ':' + snapshot.song.title;
    if (key !== this.metadataKey) {
      await session.setAVMetadata({
        assetId: snapshot.song.id.toString(),
        title: snapshot.song.title,
        artist: snapshot.song.artist,
        duration: snapshot.duration
      });
      this.metadataKey = key;
    }
    await session.setAVPlaybackState({
      state: this.systemState(snapshot.status),
      speed: 1,
      position: { elapsedTime: snapshot.position, updateTime: Date.now() },
      duration: snapshot.duration
    });
    if (snapshot.status === 'playing' && !this.background && this.launch &&
      canIUse('SystemCapability.ResourceSchedule.BackgroundTaskManager.ContinuousTask')) {
      await backgroundTaskManager.startBackgroundRunning(context, backgroundTaskManager.BackgroundMode.AUDIO_PLAYBACK,
        this.launch);
      this.background = true;
      hilog.info(DOMAIN, TAG, 'Continuous audio task started');
    }
  }

  private async create(context: common.UIAbilityContext, commands: MediaCommands): Promise<avSession.AVSession> {
    const session = await avSession.createAVSession(context, 'CloudMusicPlayback', 'audio');
    try {
      const info = context.abilityInfo;
      this.launch = await wantAgent.getWantAgent({
        wants: [{ bundleName: info.bundleName, moduleName: info.moduleName, abilityName: info.name }],
        actionType: wantAgent.OperationType.START_ABILITY,
        requestCode: 1,
        actionFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
      });
      session.on('play', commands.play);
      session.on('pause', commands.pause);
      session.on('playPrevious', commands.previous);
      session.on('playNext', commands.next);
      session.on('seek', commands.seek);
      session.on('stop', commands.stop);
      await session.setLaunchAbility(this.launch);
      await session.activate();
      this.session = session;
      return session;
    } catch (error) {
      await session.destroy().catch(() => {});
      throw new Error('无法建立系统媒体会话。');
    }
  }

  private async stopBackground(context: common.UIAbilityContext): Promise<void> {
    if (!this.background) {
      return;
    }
    this.background = false;
    if (canIUse('SystemCapability.ResourceSchedule.BackgroundTaskManager.ContinuousTask')) {
      try {
        await backgroundTaskManager.stopBackgroundRunning(context);
        hilog.info(DOMAIN, TAG, 'Continuous audio task stopped');
      } catch (error) {
        // The system may already have cancelled the task after an audio interruption.
        hilog.warn(DOMAIN, TAG, 'Continuous audio task stop result: %{public}d', (error as BusinessError).code ?? -1);
      }
    }
  }

  private async close(): Promise<void> {
    const context = this.context;
    const session = this.session;
    this.session = undefined;
    this.launch = undefined;
    this.metadataKey = '';
    if (context) {
      await this.stopBackground(context);
    }
    if (session) {
      await session.destroy();
    }
  }

  private systemState(status: PlaybackStatus): avSession.PlaybackState {
    switch (status) {
      case 'playing': return avSession.PlaybackState.PLAYBACK_STATE_PLAY;
      case 'paused': return avSession.PlaybackState.PLAYBACK_STATE_PAUSE;
      case 'loading': return avSession.PlaybackState.PLAYBACK_STATE_BUFFERING;
      case 'completed': return avSession.PlaybackState.PLAYBACK_STATE_COMPLETED;
      case 'error': return avSession.PlaybackState.PLAYBACK_STATE_ERROR;
      default: return avSession.PlaybackState.PLAYBACK_STATE_IDLE;
    }
  }
}
