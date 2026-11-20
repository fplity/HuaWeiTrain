import { systemDateTime } from '@kit.BasicServicesKit';
import { MusicTheme, PlayerStore } from '@cloudmusic/commons';
import { SpectrumFrames, TrackSpectrum } from '../service/TrackSpectrum';

const FRAME_INTERVAL_MS: number = 40;
const POSITION_LEAD_LIMIT_MS: number = 100;
const RESTING_LEVELS: number[] = [0.46, 0.39, 0.43, 0.36, 0.48, 0.43, 0.36, 0.44];

@ComponentV2
export struct SpectrumDecoration {
  @Require @Param player: PlayerStore;
  @Param active: boolean = false;
  @Param seekMs: number | undefined = undefined;
  @Local levels: number[] = RESTING_LEVELS;
  private readonly barHeights: number[] = [9, 12, 16, 20, 24, 27, 29, 30, 29, 27, 24, 20, 16, 12, 9];
  private profile: SpectrumFrames | undefined;
  private frameTimer: number = -1;
  private anchorMs: number = 0;
  private anchorTime: number = 0;

  aboutToAppear(): void {
    const resources = this.getUIContext().getHostContext()?.resourceManager;
    if (resources) {
      TrackSpectrum.load(resources);
    }
    this.syncState();
  }

  aboutToDisappear(): void {
    this.stopTimer();
  }

  @Monitor('active', 'seekMs', 'player.status', 'player.currentIndex', 'player.queue')
  syncState(): void {
    this.profile = TrackSpectrum.forSong(this.player.current);
    const run = this.active && !!this.profile && this.player.status === 'playing' && this.seekMs === undefined;
    if (!run) {
      this.stopTimer();
    }
    this.syncPosition();
    if (run && this.frameTimer === -1) {
      this.frameTimer = setInterval(() => {
        const elapsed = systemDateTime.getUptime(systemDateTime.TimeType.ACTIVE) - this.anchorTime;
        this.draw(this.anchorMs + Math.max(0, Math.min(POSITION_LEAD_LIMIT_MS, elapsed)));
      }, FRAME_INTERVAL_MS);
    }
  }

  @Monitor('player.positionMs')
  syncPosition(): void {
    if (!this.active) {
      this.levels = RESTING_LEVELS;
      return;
    }
    this.anchorMs = this.player.positionMs;
    this.anchorTime = systemDateTime.getUptime(systemDateTime.TimeType.ACTIVE);
    this.draw(this.seekMs ?? this.anchorMs);
  }

  private stopTimer(): void {
    if (this.frameTimer !== -1) {
      clearInterval(this.frameTimer);
      this.frameTimer = -1;
    }
  }

  private draw(positionMs: number): void {
    this.levels = this.profile?.at(positionMs) ?? RESTING_LEVELS;
  }

  private scaleFor(index: number): number {
    const band = Math.abs(index - 7);
    return 0.19 + this.levels[band] * 0.81;
  }

  build() {
    Row({ space: MusicTheme.xs }) {
      ForEach(this.barHeights, (height: number, index: number) => {
        Rect()
          .width(4)
          .height(height)
          .radius(2)
          .fill(MusicTheme.playerAccent)
          .scale({ y: this.scaleFor(index), centerY: '50%' })
      }, (_height: number, index: number) => index.toString())
    }
    .id('player-spectrum')
    .height(30)
    .alignItems(VerticalAlign.Center)
    .accessibilityLevel('no-hide-descendants')
  }
}
