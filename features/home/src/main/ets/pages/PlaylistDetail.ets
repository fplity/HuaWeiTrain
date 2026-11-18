import { AppContext, EXPANDED_CONTENT_WIDTH, formatPlaybackTime, MiniPlayer, MUSIC_GRID_BREAKPOINTS, MusicIcon,
  MusicPageHeader, PlayerStore, Song } from '@cloudmusic/commons';
import { PlaylistDetails, PlaylistPath } from '../model/PlaylistDetails';
import { isPositiveId } from '../service/CatalogValidation';
import { PlaylistService } from '../service/PlaylistService';
import { CatalogListCell } from '../view/CatalogListCell';
import { FeedArtwork } from '../view/FeedArtwork';
import { HomeTheme } from '../view/HomeTheme';
import { SongDataSource } from '../viewmodel/SongDataSource';

@ComponentV2
export struct PlaylistDetail {
  @Require @Param onBack: () => void;
  @Require @Param onSong: (song: Song) => void;
  @Require @Param onPlaySongs: (songs: Song[]) => Promise<void>;
  @Require @Param onStop: () => void;
  @Require @Param onOpenPlayer: () => void;
  @Require @Param onToggle: () => void;
  @Require @Param player: PlayerStore;
  @Local detail: PlaylistDetails | undefined = undefined;
  @Local loading: boolean = false;
  @Local error: string = '';
  @Local compact: boolean = true;
  @Local shortPane: boolean = false;
  private playlistId: number = 0;
  private revision: number = 0;
  private readonly songs: SongDataSource = new SongDataSource();

  aboutToDisappear(): void {
    this.revision++;
  }

  private onReady(context: NavDestinationContext): void {
    const params = context.pathInfo.param as PlaylistPath | undefined;
    if (!params || !isPositiveId(params.playlistId)) {
      context.pathStack.pop();
      return;
    }
    this.playlistId = params.playlistId;
    this.load();
  }

  private async load(): Promise<void> {
    const session = AppContext.session.current;
    if (this.loading || !session || session.user.role !== 'listener') {
      return;
    }
    const revision = ++this.revision;
    this.loading = true;
    this.error = '';
    try {
      const detail = await PlaylistService.load(this.playlistId, session.offline);
      if (revision === this.revision && AppContext.session.current === session) {
        this.songs.reset(detail.songs);
        this.detail = detail;
      }
    } catch (error) {
      if (revision === this.revision && AppContext.session.current === session) {
        this.error = (error as Error).message || '无法加载歌单。';
      }
    } finally {
      if (revision === this.revision) {
        this.loading = false;
      }
    }
  }

  private playAll(): void {
    const playable = this.detail?.songs.filter((song: Song) => !!song.playUrl) ?? [];
    if (playable.length) {
      this.onPlaySongs(playable).catch(() => {});
    }
  }

  @Builder
  playlistHeader() {
    Stack({ alignContent: Alignment.BottomStart }) {
      FeedArtwork({ src: this.detail?.coverUrl ?? '', artworkId: this.detail?.id ?? 0, wide: true })
        .blur(this.detail?.albumArtist ? 20 : 0)
      Row()
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [['#36180F17', 0], ['#88180F17', 0.48], ['#ED180F17', 1]]
        })
      Row({ space: 15 }) {
        if (this.detail?.albumArtist) {
          Stack() {
            FeedArtwork({ src: this.detail?.coverUrl ?? '', artworkId: this.detail?.id ?? 0 })
          }
          .width(104)
          .height(104)
          .borderRadius(11)
          .border({ width: 1, color: '#55FFFFFF' })
          .clip(true)
        }
        Column({ space: 6 }) {
          Text(this.detail?.name ?? '')
            .fontSize(25)
            .fontWeight(FontWeight.Bold)
            .fontColor(HomeTheme.playerText)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text((this.detail?.albumArtist ? this.detail.albumArtist + '  ·  ' : '') +
            (this.detail?.songs.length ?? 0).toString() + ' 首歌曲')
            .fontSize(13)
            .fontColor('#F1E1EA')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          if (this.detail?.description) {
            Text(this.detail.description)
              .fontSize(12)
              .fontColor('#F1E1EA')
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .padding(16)
    }
    .width('100%')
    .height(this.detail?.albumArtist ? 152 : 188)
    .backgroundColor('#332531')
    .borderRadius(18)
    .clip(true)
  }

  @Builder
  playAllButton() {
    if (this.detail?.songs.some((song: Song) => !!song.playUrl)) {
      Button({ type: ButtonType.Capsule }) {
        Row({ space: 5 }) {
          MusicIcon({ name: 'play', iconSize: 18, tint: HomeTheme.onAccent })
          Text('播放全部')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor(HomeTheme.onAccent)
        }
        .padding({ left: 12, right: 14 })
      }
      .id('playlist-play-all')
      .height(42)
      .backgroundColor(HomeTheme.accent)
      .accessibilityText('播放全部')
      .enabled(this.player.status !== 'loading')
      .onClick(() => { this.playAll(); })
    }
  }

  @Builder
  detailsArtwork(detail: PlaylistDetails, width: Length) {
    Stack() {
      FeedArtwork({ src: detail.coverUrl ?? '', artworkId: detail.id, wide: !this.shortPane })
    }
    .width(width)
    .aspectRatio(1)
    .borderRadius(14)
    .clip(true)
  }

  @Builder
  detailsMetadata(detail: PlaylistDetails) {
    Column({ space: 7 }) {
      Text(detail.name)
        .fontSize(this.shortPane ? 19 : 24)
        .fontWeight(FontWeight.Bold)
        .fontColor(HomeTheme.textPrimary)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text((detail.albumArtist ? detail.albumArtist + ' · ' : '') + detail.songs.length.toString() + ' 首歌曲')
        .fontSize(13)
        .fontColor(HomeTheme.textSecondary)
    }
    .width('100%')
    .layoutWeight(this.shortPane ? 1 : 0)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  detailsPane(detail: PlaylistDetails) {
    Scroll() {
      Column({ space: 14 }) {
        if (this.shortPane) {
          Row({ space: 12 }) {
            this.detailsArtwork(detail, 84)
            this.detailsMetadata(detail)
          }
          .width('100%')
        } else {
          this.detailsArtwork(detail, '100%')
          this.detailsMetadata(detail)
        }
        this.playAllButton()
        if (detail.description) {
          Text(detail.description)
            .fontSize(14)
            .fontColor(HomeTheme.textSecondary)
        }
      }
      .width('100%')
      .constraintSize({ maxWidth: 380 })
      .padding(16)
      .alignItems(HorizontalAlign.Start)
      .backgroundColor(HomeTheme.surface)
      .borderRadius(18)
    }
    .id('playlist-details-pane')
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    .padding({ top: 3, right: 20, left: 8, bottom: 12 })
  }

  @Builder
  listHeader() {
    Column({ space: 15 }) {
      if (this.detail) {
        if (this.compact) {
          this.playlistHeader()
        }
        Row() {
          Text('曲目')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(HomeTheme.textPrimary)
          Blank()
          if (this.compact) {
            this.playAllButton()
          }
        }
        .width('100%')
        if (this.detail?.songs.length === 0) {
          Text('这个歌单暂时没有歌曲').fontSize(14).fontColor(HomeTheme.textSecondary)
        }
      } else if (this.error) {
        Text(this.error).fontColor(HomeTheme.error).fontSize(14)
        Button('重试')
          .backgroundColor(HomeTheme.accent)
          .fontColor(HomeTheme.onAccent)
          .onClick(() => { this.load(); })
      } else {
        LoadingProgress().width(28).height(28).color(HomeTheme.accent).accessibilityText('正在加载歌单')
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ top: 3, bottom: 6 })
  }

  @Builder
  trackList() {
    List() {
      ListItemGroup({ header: this.listHeader() }) {
        LazyForEach(this.songs, (song: Song, index: number) => {
          ListItem() {
            CatalogListCell({
              title: song.title,
              subtitle: song.artist,
              coverUrl: song.coverUrl ?? '',
              artworkId: song.id,
              number: index + 1,
              showArtwork: !this.detail?.albumArtist,
              durationText: song.duration > 0 ? formatPlaybackTime(song.duration) : '',
              isSong: true,
              active: this.player.current?.id === song.id
            })
          }
          .focusable(true)
          .onClick(() => { this.onSong(song); })
        }, (song: Song, index: number) => song.id.toString() + ':' + index.toString())
      }
    }
    .id('playlist-track-list')
    .cachedCount(4)
    .width('100%')
    .height('100%')
    .scrollBar(this.compact ? BarState.Off : BarState.Auto)
    .padding({ left: 20, right: this.compact ? 20 : 8 })
  }

  build() {
    NavDestination() {
      Column() {
        MusicPageHeader({ title: this.detail?.albumArtist ? '专辑详情' : '歌单详情', onBack: this.onBack })
        GridRow({ columns: 12, gutter: 12,
          breakpoints: { value: MUSIC_GRID_BREAKPOINTS, reference: BreakpointsReference.ComponentSize } }) {
          GridCol({ span: { xs: 12, sm: 7, md: 8 } }) {
            this.trackList()
          }
          .height('100%')
          GridCol({ span: { xs: 0, sm: 5, md: 4 } }) {
            if (this.detail && !this.compact) {
              this.detailsPane(this.detail)
            }
          }
          .height('100%')
        }
        .width('100%')
        .constraintSize({ maxWidth: EXPANDED_CONTENT_WIDTH })
        .layoutWeight(1)
        .onBreakpointChange((breakpoint: string) => { this.compact = breakpoint === 'xs'; })
        .onAreaChange((_oldArea: Area, area: Area) => { this.shortPane = Number(area.height) < 360; })
        if (this.player.current) {
          Column() {
            MiniPlayer({ player: this.player, onStop: this.onStop, onOpen: this.onOpenPlayer, onToggle: this.onToggle })
          }
          .width('100%')
          .constraintSize({ maxWidth: EXPANDED_CONTENT_WIDTH })
          .padding({ left: 14, right: 14, top: 7, bottom: 9 })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(HomeTheme.background)
    }
    .hideTitleBar(true)
    .onReady((context: NavDestinationContext) => { this.onReady(context); })
  }
}
