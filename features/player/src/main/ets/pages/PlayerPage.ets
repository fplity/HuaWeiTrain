import { AppContext, formatPlaybackTime, MusicIcon, MusicTheme, PlayerStore, windowBreakpoint,
  WindowBreakpoint } from '@cloudmusic/commons';
import { CommentPanel } from '../view/CommentPanel';
import { SpectrumDecoration } from '../view/SpectrumDecoration';
import { DiscCanvas } from '../view/DiscCanvas';
import { LyricView } from '../view/LyricView';
import { RingProgress } from '../view/RingProgress';
import { PlayerControls } from '../view/PlayerControls';

@ComponentV2
export struct PlayerPage {
  @Require @Param player: PlayerStore;
  @Require @Param onToggle: () => void;
  @Require @Param onStop: () => void;
  @Require @Param onPrevious: () => void;
  @Require @Param onNext: () => void;
  @Require @Param onSeek: (position: number) => Promise<void>;
  @Local draftPosition: number | undefined = undefined;
  @Local showingLyrics: boolean = false;
  @Local showingComments: boolean = false;
  @Local visible: boolean = false;
  private readonly session = AppContext.session;

  private get canComment(): boolean {
    return this.session.current?.offline === false && this.session.current.user.role === 'listener';
  }
  @Local breakpoint: WindowBreakpoint = 'compact';
  @Local shortWindow: boolean = false;
  private pathStack: NavPathStack | undefined = undefined;
  private seekRevision: number = 0;

  private get wide(): boolean {
    return this.breakpoint !== 'compact';
  }

  @Monitor('player.currentIndex', 'player.queue')
  onTrackChanged(): void {
    this.seekRevision++;
    this.draftPosition = undefined;
  }

  private seek(value: number, mode: SliderChangeMode): void {
    if (mode === SliderChangeMode.Begin || mode === SliderChangeMode.Moving) {
      this.seekRevision++;
      this.draftPosition = value;
    } else {
      const revision = ++this.seekRevision;
      this.draftPosition = value;
      this.onSeek(value).finally(() => {
        if (revision === this.seekRevision) {
          this.draftPosition = undefined;
        }
      }).catch(() => {});
    }
  }

  @Builder
  playerHeader() {
    Row() {
      Button({ type: ButtonType.Circle }) {
        MusicIcon({ name: 'down', iconSize: 23, tint: MusicTheme.playerText })
      }
      .height(44)
      .width(44)
      .backgroundColor('#22FFFFFF')
      .accessibilityText('收起播放器')
      .onClick(() => { this.pathStack?.pop(); })

      Column({ space: 3 }) {
        Text('正在播放')
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor(MusicTheme.playerAccent)
        Text(this.player.current?.album || '回声音乐')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(MusicTheme.playerText)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      Blank().width(44)
    }
    .width('100%')
    .constraintSize({ maxWidth: 1016 })
    .padding({ left: 19, right: 19, top: 8, bottom: 10 })
  }

  @Builder
  art() {
    Column() {
      Stack({ alignContent: Alignment.Center }) {
        if (this.showingComments && this.visible && this.canComment && this.player.current) {
          CommentPanel({ songId: this.player.current.id })
        } else if (this.showingLyrics) {
          LyricView({
            source: this.player.current?.lyricUrl ?? '',
            positionMs: this.draftPosition ?? this.player.positionMs,
            onSeek: (position: number) => { this.onSeek(position).catch(() => {}); }
          })
        } else {
          Stack({ alignContent: Alignment.Center }) {
            Row()
              .width('84%')
              .height('84%')
              .backgroundColor('#100B12')
              .borderRadius(999)
              .shadow({ radius: 28, color: '#78050206', offsetY: 13 })
              .accessibilityLevel('no')
            DiscCanvas({
              coverUrl: this.player.current?.coverUrl ?? '',
              artworkId: this.player.current?.id ?? 0,
              spinning: this.visible && this.player.status === 'playing'
            })
            RingProgress({ positionMs: this.draftPosition ?? this.player.positionMs, durationMs: this.player.durationMs })
          }
          .width('100%')
          .height('100%')
          .onClick(() => { this.showingLyrics = true; })
        }
      }
      .width('100%')
      .constraintSize({ maxWidth: this.shortWindow ? 230 : (this.wide ? 368 : 320) })
      .aspectRatio(1)
    }
    .width(this.wide ? '50%' : '100%')
    .padding({ right: this.wide ? 18 : 0 })
  }

  @Builder
  identity() {
    Row({ space: 10 }) {
      Column({ space: 5 }) {
        Text(this.player.current?.title ?? '')
          .fontSize(27)
          .fontWeight(FontWeight.Bold)
          .fontColor(MusicTheme.playerText)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.player.current?.artist ?? '')
          .fontSize(14)
          .fontColor(MusicTheme.playerMuted)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Button(this.showingLyrics ? '封面' : '歌词')
        .id('player-lyrics-toggle')
        .height(38)
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor(MusicTheme.playerText)
        .backgroundColor('#26FFFFFF')
        .onClick(() => {
          this.showingLyrics = this.showingComments || !this.showingLyrics;
          this.showingComments = false;
        })
      if (this.canComment) {
        Button(this.showingComments ? '封面' : '评论')
          .id('player-comments-toggle')
          .height(38)
          .fontSize(12)
          .fontColor(MusicTheme.playerText)
          .backgroundColor('#26FFFFFF')
          .onClick(() => {
            this.showingComments = !this.showingComments;
            this.showingLyrics = false;
          })
      }
    }
    .width('100%')
  }

  @Builder
  transport() {
    Column({ space: 11 }) {
      Column() {
        Slider({
          value: this.draftPosition ?? this.player.positionMs,
          min: 0,
          max: Math.max(1, this.player.durationMs),
          step: 100
        })
          .id('player-seek')
          .trackColor(MusicTheme.playerTrack)
          .selectedColor(MusicTheme.playerAccent)
          .blockColor(MusicTheme.playerText)
          .trackThickness(3)
          .blockSize({ width: 11, height: 11 })
          .height(35)
          .accessibilityText('播放进度')
          .enabled(this.player.durationMs > 0 && (this.player.status === 'playing' || this.player.status === 'paused'))
          .onChange((value: number, mode: SliderChangeMode) => { this.seek(value, mode); })
          .width('100%')
        Row() {
          Text(formatPlaybackTime(this.draftPosition ?? this.player.positionMs))
            .id('player-elapsed')
            .fontSize(11)
            .fontColor(MusicTheme.playerMuted)
          Blank()
          Text(formatPlaybackTime(this.player.durationMs))
            .id('player-duration')
            .fontSize(11)
            .fontColor(MusicTheme.playerMuted)
        }
        .width('100%')
      }
      .width('100%')

      if (this.player.status === 'error') {
        Text(this.player.error).fontSize(13).fontColor('#FFC1BD')
      }
      PlayerControls({
        status: this.player.status,
        queueCount: this.player.queue.length,
        currentIndex: this.player.currentIndex,
        onToggle: this.onToggle,
        onStop: this.onStop,
        onPrevious: this.onPrevious,
        onNext: this.onNext
      })
    }
    .width('100%')
  }

  @Builder
  nowPlaying() {
    Flex({ direction: this.wide ? FlexDirection.Row : FlexDirection.Column,
      alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      this.art()
      Column({ space: this.wide ? 22 : 10 }) {
        this.identity()
        this.transport()
        if (!this.shortWindow && !this.showingComments) {
          SpectrumDecoration().opacity(0.55)
        }
      }
      .width(this.wide ? '50%' : '100%')
    }
    .width('100%')
    .constraintSize({ maxWidth: this.wide ? 960 : 440 })
    .padding({ left: 24, right: 24, top: this.wide ? 20 : 9, bottom: 24 })
    .borderRadius(this.wide ? 26 : 0)
    .backgroundColor(this.wide ? '#A6221721' : Color.Transparent)
    .border({ width: this.wide ? 1 : 0, color: '#29FFFFFF' })
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Top }) {
        Row()
          .width('100%')
          .height('100%')
          .linearGradient({ direction: GradientDirection.Bottom,
            colors: [['#553146', 0], ['#2E202D', 0.46], ['#181219', 1]] })
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
        if (this.player.current?.coverUrl?.startsWith('rawfile:')) {
          Stack() {
            Image($rawfile(this.player.current?.coverUrl?.substring(8) ?? ''))
              .sourceSize({ width: 144, height: 144 })
              .objectFit(ImageFit.Cover)
              .width('100%')
              .height('100%')
              .blur(48)
              .opacity(0.45)
              .draggable(false)
            Row()
              .width('100%')
              .height('100%')
              .linearGradient({ direction: GradientDirection.Bottom,
                colors: [['#553146', 0], ['#C4553146', 0.045], ['#30181219', 0.24], ['#58181219', 0.48], ['#F0181219', 1]] })
          }
          .width('100%')
          .height('100%')
          .clip(true)
          .accessibilityLevel('no-hide-descendants')
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
        }

        Column() {
          this.playerHeader()
          if (this.player.current) {
            Scroll() {
              Column() {
                this.nowPlaying()
              }
              .id(this.wide ? 'player-wide-card' : 'player-compact-content')
              .width('100%')
              .padding({ left: this.wide ? 20 : 0, right: this.wide ? 20 : 0, bottom: this.wide ? 14 : 0 })
            }
            .width('100%')
            .layoutWeight(1)
            .align(this.wide ? Alignment.Center : Alignment.Top)
            .scrollBar(this.wide ? BarState.Auto : BarState.Off)
          } else {
            Text('当前没有歌曲')
              .fontSize(15)
              .fontColor(MusicTheme.playerMuted)
              .padding(MusicTheme.xl)
              .layoutWeight(1)
          }
        }
        .width('100%')
        .height('100%')
      }
      .width('100%')
      .height('100%')
      .backgroundColor(MusicTheme.ink)
      .onAreaChange((_oldArea: Area, area: Area) => {
        this.breakpoint = windowBreakpoint(Number(area.width));
        this.shortWindow = Number(area.height) < 500;
      })
    }
    .hideTitleBar(true)
    .systemTransition(NavigationSystemTransitionType.SLIDE_BOTTOM)
    .onShown(() => { this.visible = true; })
    .onHidden(() => { this.visible = false; })
    .systemBarStyle({ statusBarContentColor: '#FFFFFF' })
    .onReady((context: NavDestinationContext) => { this.pathStack = context.pathStack; })
  }
}
