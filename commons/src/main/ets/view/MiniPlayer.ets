import { PlayerStore } from '../store/PlayerStore';
import { formatPlaybackTime } from '../utils/PlaybackTime';
import { MusicIcon } from './MusicIcon';
import { MusicTheme } from './MusicTheme';

@ComponentV2
struct MiniPlayerImage {
  @Require @Param source: string;
  @Local failed: boolean = false;

  build() {
    if (!this.failed) {
      Image(this.source.startsWith('rawfile:') ? $rawfile(this.source.substring(8)) : this.source)
        .width('100%')
        .height('100%')
        .sourceSize({ width: 144, height: 144 })
        .objectFit(ImageFit.Cover)
        .draggable(false)
        .onError(() => { this.failed = true; })
        .accessibilityLevel('no')
    }
  }
}

@ComponentV2
export struct MiniPlayer {
  @Require @Param player: PlayerStore;
  @Require @Param onOpen: () => void;
  @Require @Param onToggle: () => void;
  @Require @Param onStop: () => void;

  private get coverSources(): string[] {
    const source = this.player.current?.coverUrl ?? '';
    return source.startsWith('rawfile:') || source.startsWith('https://') ? [source] : [];
  }

  private status(): string {
    if (this.player.status === 'error') {
      return this.player.error;
    }
    if (this.player.status === 'loading') {
      return '正在加载…';
    }
    return formatPlaybackTime(this.player.positionMs) + ' / ' + formatPlaybackTime(this.player.durationMs);
  }

  @Builder
  artwork() {
    Stack({ alignContent: Alignment.Center }) {
      MusicIcon({ name: 'disc', iconSize: 22, tint: '#F7ABBF' })
      ForEach(this.coverSources, (source: string) => {
        MiniPlayerImage({ source: source })
      }, (source: string) => source)
    }
    .id('mini-player-artwork')
    .width(39)
    .height(39)
    .backgroundColor(MusicTheme.wine)
    .borderRadius(9)
    .clip(true)
  }

  build() {
    if (this.player.current) {
      Column() {
        Row({ space: 3 }) {
          Button({ type: ButtonType.Normal }) {
            Row({ space: 10 }) {
              this.artwork()
              Column({ space: 3 }) {
                Text(this.player.current?.title ?? '')
                  .id('mini-player-title')
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(MusicTheme.playerText)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(this.status())
                  .id('mini-player-time')
                  .fontSize(11)
                  .fontColor(this.player.status === 'error' ? '#FFC3BA' : MusicTheme.playerMuted)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
            }
            .width('100%')
          }
          .id('mini-player-open')
          .backgroundColor(Color.Transparent)
          .padding({ left: 0, right: 5 })
          .layoutWeight(1)
          .height(49)
          .accessibilityText('打开播放器')
          .onClick(() => { this.onOpen(); })

          Button({ type: ButtonType.Circle }) {
            MusicIcon({ name: this.player.status === 'playing' ? 'pause' : 'play', iconSize: 20,
              tint: MusicTheme.ink })
          }
          .id('mini-player-toggle')
          .backgroundColor(MusicTheme.playerAccent)
          .width(42)
          .height(42)
          .enabled(this.player.status !== 'loading')
          .accessibilityText(this.player.status === 'playing' ? '暂停' : '播放')
          .onClick(() => { this.onToggle(); })

          Button({ type: ButtonType.Circle }) {
            MusicIcon({ name: 'stop', iconSize: 17, tint: MusicTheme.playerMuted })
          }
          .id('mini-player-stop')
          .backgroundColor(Color.Transparent)
          .width(42)
          .height(42)
          .accessibilityText('停止')
          .onClick(() => { this.onStop(); })
        }
        .padding({ left: 9, right: 4, top: 4, bottom: 3 })
        .width('100%')

        Progress({ value: this.player.positionMs, total: Math.max(1, this.player.durationMs) })
          .id('mini-player-progress')
          .color(MusicTheme.playerAccent)
          .backgroundColor(MusicTheme.playerTrack)
          .style({ strokeWidth: 2 })
          .width('100%')
          .height(2)
      }
      .width('100%')
      .constraintSize({ maxWidth: 808 })
      .backgroundColor('#291D28')
      .borderRadius(14)
      .clip(true)
    }
  }
}
