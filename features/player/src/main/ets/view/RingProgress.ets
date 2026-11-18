import { MusicTheme } from '@cloudmusic/commons';

@ComponentV2
export struct RingProgress {
  @Param positionMs: number = 0;
  @Param durationMs: number = 0;

  private fraction(): number {
    if (!Number.isFinite(this.positionMs) || !Number.isFinite(this.durationMs) || this.durationMs <= 0) {
      return 0;
    }
    return Math.max(0, Math.min(1, this.positionMs / this.durationMs));
  }

  private arc(): string {
    const fraction = this.fraction();
    if (fraction >= 1) {
      return 'M 50 1 A 49 49 0 0 1 50 99 A 49 49 0 0 1 50 1';
    }
    const radians = fraction * 2 * Math.PI;
    const x = 50 + 49 * Math.sin(radians);
    const y = 50 - 49 * Math.cos(radians);
    return 'M 50 1 A 49 49 0 ' + (fraction > 0.5 ? '1' : '0') + ' 1 ' + x.toFixed(4) + ' ' + y.toFixed(4);
  }

  build() {
    Shape() {
      Path({ commands: 'M 50 1 A 49 49 0 0 1 50 99 A 49 49 0 0 1 50 1' })
        .fill(Color.Transparent)
        .stroke(MusicTheme.playerTrack)
        .strokeWidth(0.75)
      if (this.fraction() > 0) {
        Path({ commands: this.arc() })
          .fill(Color.Transparent)
          .stroke(MusicTheme.playerAccent)
          .strokeWidth(0.75)
          .strokeLineCap(LineCapStyle.Round)
      }
    }
    .id('player-progress-ring')
    .width('100%')
    .height('100%')
    .viewPort({ x: 0, y: 0, width: 100, height: 100 })
    .accessibilityText('播放进度 ' + Math.floor(this.fraction() * 100).toString() + '%')
  }
}