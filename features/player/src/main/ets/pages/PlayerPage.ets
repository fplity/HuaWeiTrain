import { curves } from '@kit.ArkUI';
import { AppContext, formatPlaybackTime, MusicIcon, MusicTheme, PlayerStore, SongFavorites, windowBreakpoint,
  WindowBreakpoint } from '@cloudmusic/commons';
import { CommentPanel } from '../view/CommentPanel';
import { SpectrumDecoration } from '../view/SpectrumDecoration';
import { DiscCanvas } from '../view/DiscCanvas';
import { LyricView } from '../view/LyricView';
import { PlayerControls } from '../view/PlayerControls';
import { SongDetails } from '../view/SongDetails';
import { allowsPlayerMotion } from '../service/PlayerMotion';
import { TrackNotes } from '../service/TrackNotes';

const DETAILS_SCROLL_MS: number = 240;

@ComponentV2
export struct PlayerPage {
  @Require @Param player: PlayerStore;
  @Require @Param favorites: SongFavorites;
  @Require @Param onToggle: () => void;
  @Require @Param onStop: () => void;
  @Require @Param onPrevious: () => void;
  @Require @Param onNext: () => void;
  @Require @Param onSeek: (position: number) => Promise<void>;
  @Local draftPosition: number | undefined = undefined;
  @Local showingLyrics: boolean = false;
  @Local showingComments: boolean = false;
  @Local visible: boolean = false;
  @Local motionEnabled: boolean = true;
  @Local viewportHeight: number = 0;
  @Local playbackHeight: number = 0;
  @Local scrollY: number = 0;
  private readonly playerScroller: Scroller = new Scroller();
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

  aboutToAppear(): void {
    const context = this.getUIContext().getHostContext();
    this.motionEnabled = allowsPlayerMotion(context);
    if (context) {
      TrackNotes.load(context.resourceManager);
    }
  }

  private get detailProgress(): number {
    const controlsOverflow = Math.max(0, this.playbackHeight - this.viewportHeight);
    const fadeDistance = Math.max(1, this.viewportHeight * 0.72);
    return Math.min(1, Math.max(0, (this.scrollY - controlsOverflow) / fadeDistance));
  }

  private scrollToSection(details: boolean): void {
    this.playerScroller.scrollTo({
      xOffset: 0,
      yOffset: details ? this.playbackHeight : 0,
      animation: this.motionEnabled ? { duration: DETAILS_SCROLL_MS, curve: curves.cubicBezierCurve(0.23, 1, 0.32, 1) } :
        false
    });
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
              spinning: this.visible && this.detailProgress < 0.95 && this.player.status === 'playing'
            })
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

  private get isFavorite(): boolean {
    const song = this.player.current;
    return !!song && this.favorites.isFavorite(song.id);
  }

  @Builder
  favoriteButton() {
    Button({ type: ButtonType.Circle }) {
      SymbolGlyph(this.isFavorite ? $r('sys.symbol.heart_fill') : $r('sys.symbol.heart'))
        .fontSize(20)
        .fontColor([this.isFavorite ? MusicTheme.playerAccent : MusicTheme.playerText])
        .accessibilityLevel('no')
    }
    .id('player-favorite-toggle')
    .width(42)
    .height(42)
    .backgroundColor(this.isFavorite ? '#40F7A0B5' : '#26FFFFFF')
    .accessibilityText(this.isFavorite ? '取消喜欢' : '添加到我喜欢的音乐')
    .onClick(() => {
      const song = this.player.current;
      if (song) {
        this.favorites.toggleFavorite(song.id);
      }
    })
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
      if (this.player.current) {
        this.favoriteButton()
      }
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
          SpectrumDecoration({
            player: this.player,
            active: this.visible && this.motionEnabled && this.detailProgress < 0.95,
            seekMs: this.draftPosition
          }).opacity(0.62)
        }
      }
      .width(this.wide ? '50%' : '100%')
    }
    .width('100%')
    .constraintSize({ maxWidth: this.wide ? 960 : 440 })
    .padding({ left: 24, right: 24, top: this.wide ? 20 : 9, bottom: this.wide ? 20 : 8 })
    .borderRadius(this.wide ? 26 : 0)
    .backgroundColor(this.wide ? '#A6221721' : Color.Transparent)
    .border({ width: this.wide ? 1 : 0, color: '#29FFFFFF' })
  }

  @Builder
  scrollablePlayer() {
    Scroll(this.playerScroller) {
      Column() {
        Column({ space: 4 }) {
          this.nowPlaying()
          Button({ type: ButtonType.Normal }) {
            Row({ space: 7 }) {
              MusicIcon({ name: 'down', iconSize: 15, tint: MusicTheme.playerMuted })
              Text('上滑查看歌曲资料')
                .fontColor(MusicTheme.playerMuted)
                .fontSize(13)
            }
          }
          .id('player-show-track-details')
          .height(44)
          .padding({ left: 12, right: 12 })
          .backgroundColor(Color.Transparent)
          .borderRadius(12)
          .accessibilityText('查看歌曲资料')
          .onClick(() => { this.scrollToSection(true); })
        }
        .id(this.wide ? 'player-wide-card' : 'player-compact-content')
        .width('100%')
        .constraintSize({ minHeight: this.viewportHeight })
        .justifyContent(this.wide ? FlexAlign.Center : FlexAlign.Start)
        .padding({ left: this.wide ? 20 : 0, right: this.wide ? 20 : 0, bottom: this.wide ? 14 : 0 })
        .opacity(this.motionEnabled ? 1 - this.detailProgress : 1)
        .accessibilityLevel(this.detailProgress >= 0.98 ? 'no-hide-descendants' : 'auto')
        .onAreaChange((_oldArea: Area, area: Area) => { this.playbackHeight = Number(area.height); })

        if (this.player.current) {
          Column() {
            SongDetails({
              song: this.player.current,
              playing: this.player.status === 'playing',
              onToggle: this.onToggle,
              onReturn: () => { this.scrollToSection(false); }
            })
          }
          .id('player-track-details')
          .width('100%')
          .constraintSize({ minHeight: this.viewportHeight })
          .opacity(this.motionEnabled ? this.detailProgress : 1)
          .accessibilityLevel(this.detailProgress < 0.16 ? 'no-hide-descendants' : 'auto')
        }
      }
      .width('100%')
    }
    .id('player-section-scroll')
    .width('100%')
    .layoutWeight(1)
    .align(Alignment.Top)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.None)
    .enablePaging(this.motionEnabled && !this.shortWindow && this.playbackHeight <= this.viewportHeight + 1)
    .onAreaChange((_oldArea: Area, area: Area) => { this.viewportHeight = Number(area.height); })
    .onDidScroll(() => { this.scrollY = this.playerScroller.currentOffset().yOffset; })
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
            this.scrollablePlayer()
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
    .onShown(() => {
      this.motionEnabled = allowsPlayerMotion(this.getUIContext().getHostContext());
      this.visible = true;
    })
    .onBackPressed(() => {
      if (this.detailProgress >= 0.6) {
        this.scrollToSection(false);
        return true;
      }
      return false;
    })
    .onHidden(() => { this.visible = false; })
    .systemBarStyle({ statusBarContentColor: '#FFFFFF' })
    .onReady((context: NavDestinationContext) => { this.pathStack = context.pathStack; })
  }
}
