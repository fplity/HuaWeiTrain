import { LengthMetrics } from '@kit.ArkUI';
import { LyricLine, lyricIndexAt, MusicTheme } from '@cloudmusic/commons';
import { LyricService } from '../service/LyricService';

@ComponentV2
export struct LyricView {
  @Param source: string = '';
  @Param positionMs: number = 0;
  @Require @Param onSeek: (position: number) => void;
  @Local lines: LyricLine[] = [];
  @Local active: number = -1;
  @Local loading: boolean = false;
  @Local error: boolean = false;
  private readonly scroller: Scroller = new Scroller();
  private revision: number = 0;

  aboutToAppear(): void {
    this.load();
  }

  aboutToDisappear(): void {
    this.revision++;
  }

  @Monitor('source')
  onSourceChange(): void {
    this.load();
  }

  @Monitor('positionMs')
  onPositionChange(): void {
    this.followPosition();
  }

  private async load(): Promise<void> {
    const revision = ++this.revision;
    this.lines = [];
    this.active = -1;
    this.error = false;
    this.loading = !!this.source;
    try {
      const lines = await LyricService.load(this.getUIContext().getHostContext()?.resourceManager, this.source);
      if (revision === this.revision) {
        this.lines = lines;
        this.active = lyricIndexAt(lines, this.positionMs);
      }
    } catch (_) {
      if (revision === this.revision) {
        this.error = true;
      }
    } finally {
      if (revision === this.revision) {
        this.loading = false;
      }
    }
  }

  private followPosition(): void {
    const index = lyricIndexAt(this.lines, this.positionMs);
    if (index !== this.active) {
      this.active = index;
      this.scrollToActive();
    }
  }

  private scrollToActive(): void {
    if (this.active >= 0) {
      this.scroller.scrollToIndex(this.active, false, ScrollAlign.CENTER);
    }
  }

  build() {
    Column() {
      if (this.lines.length) {
        List({ scroller: this.scroller, space: MusicTheme.sm }) {
          ForEach(this.lines, (line: LyricLine, index: number) => {
            ListItem() {
              Text(line.text)
                .fontSize(this.active === index ? 22 : 16)
                .fontWeight(this.active === index ? FontWeight.Bold : FontWeight.Regular)
                .fontColor(this.active === index ? MusicTheme.playerAccent : MusicTheme.playerMuted)
                .textAlign(TextAlign.Center)
                .width('100%')
                .padding({ top: MusicTheme.sm, bottom: MusicTheme.sm })
            }
            .onClick(() => { this.onSeek(line.timeMs); })
          }, (line: LyricLine, index: number) => line.timeMs.toString() + ':' + index.toString())
        }
        .id('player-lyrics-list')
        .height('100%')
        .width('100%')
        .nestedScroll({
          scrollForward: NestedScrollMode.SELF_FIRST,
          scrollBackward: NestedScrollMode.SELF_FIRST
        })
        .scrollBar(BarState.Off)
        .fadingEdge(true, { fadingEdgeLength: LengthMetrics.vp(25) })
        .onAppear(() => { this.scrollToActive(); })
      } else if (this.loading) {
        LoadingProgress()
          .color(MusicTheme.playerAccent)
          .width(28)
          .height(28)
          .accessibilityText('正在加载歌词')
      } else {
        Text(this.error ? '歌词文件无法读取' : '这首歌还没有歌词文件')
          .id('player-lyrics-empty')
          .fontSize(MusicTheme.body)
          .fontColor(MusicTheme.playerMuted)
          .textAlign(TextAlign.Center)
      }
    }
    .justifyContent(FlexAlign.Center)
    .padding(MusicTheme.md)
    .width('100%')
    .height('100%')
    .backgroundColor('#12FFFFFF')
    .borderRadius(MusicTheme.radiusMd)
  }
}
