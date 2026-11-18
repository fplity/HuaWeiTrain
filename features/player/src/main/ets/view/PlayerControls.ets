import { MusicIcon, MusicTheme, PlaybackStatus } from '@cloudmusic/commons';

@ComponentV2
export struct PlayerControls {
  @Param status: PlaybackStatus = 'idle';
  @Param queueCount: number = 0;
  @Param currentIndex: number = 0;
  @Require @Param onPrevious: () => void;
  @Require @Param onNext: () => void;
  @Require @Param onToggle: () => void;
  @Require @Param onStop: () => void;

  @Styles
  pressed() {
    .scale({ x: 0.91, y: 0.91 })
    .opacity(0.72)
  }

  private label(): string {
    switch (this.status) {
      case 'loading': return '加载中';
      case 'playing': return '暂停';
      case 'paused': return '继续播放';
      case 'completed': return '重新播放';
      case 'error': return '重试播放';
      default: return '播放';
    }
  }

  @Builder
  secondary(icon: string, label: string, id: string, enabled: boolean, action: () => void) {
    Button({ type: ButtonType.Circle }) {
      MusicIcon({ name: icon, iconSize: icon === 'stop' ? 19 : 26, tint: MusicTheme.playerText })
    }
    .id(id)
    .width(45)
    .height(45)
    .backgroundColor(Color.Transparent)
    .opacity(enabled ? 1 : 0.32)
    .enabled(enabled)
    .stateStyles({ pressed: this.pressed })
    .accessibilityText(label)
    .onClick(() => { action(); })
  }

  build() {
    Column({ space: 9 }) {
      Row() {
        Blank().layoutWeight(1)
        this.secondary('previous', '上一首', 'player-previous', this.queueCount > 1, this.onPrevious)
        Blank().layoutWeight(1)
        Button({ type: ButtonType.Circle }) {
          if (this.status === 'loading') {
            LoadingProgress().color(MusicTheme.ink).width(28).height(28)
          } else {
            MusicIcon({ name: this.status === 'playing' ? 'pause' : 'play', iconSize: 30, tint: MusicTheme.ink })
          }
        }
        .id('player-toggle')
        .width(66)
        .height(66)
        .backgroundColor(MusicTheme.playerAccent)
        .stateStyles({ pressed: this.pressed })
        .enabled(this.status !== 'loading' && this.status !== 'idle')
        .accessibilityText(this.label())
        .onClick(() => { this.onToggle(); })
        Blank().layoutWeight(1)
        this.secondary('next', '下一首', 'player-next', this.queueCount > 1, this.onNext)
        Blank().layoutWeight(1)
      }
      .width('100%')
      Row() {
        Text(this.queueCount > 0 ? '播放队列  ' + (this.currentIndex + 1).toString() + ' / ' + this.queueCount.toString() :
          '暂无播放队列')
          .fontSize(12)
          .fontColor(MusicTheme.playerMuted)
        Blank()
        this.secondary('stop', '停止', 'player-stop', this.status !== 'idle', this.onStop)
      }
      .width('100%')
      .padding({ left: 12, right: 3 })
      .backgroundColor('#12FFFFFF')
      .borderRadius(13)
    }
    .width('100%')
  }
}
