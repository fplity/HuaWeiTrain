import { AppContext, EXPANDED_CONTENT_WIDTH, MiniPlayer, MusicIcon, PlayerStore, Playlist, SessionStore, Song,
  windowBreakpoint } from '@cloudmusic/commons';
import { BannerSwiper } from '../view/BannerSwiper';
import { DailyRow } from '../view/DailyRow';
import { HomeTheme } from '../view/HomeTheme';
import { PlaylistListCell } from '../view/PlaylistListCell';
import { HomeFeedState } from '../viewmodel/HomeFeedState';

@ComponentV2
export struct HomePage {
  @Require @Param player: PlayerStore;
  @Require @Param onOpenPlayer: () => void;
  @Require @Param onToggle: () => void;
  @Require @Param onStop: () => void;
  @Require @Param onSearch: () => void;
  @Require @Param onAlbums: () => void;
  @Require @Param onAccount: () => void;
  @Require @Param onSong: (song: Song) => void;
  @Require @Param onPlaylist: (id: number) => void;
  private readonly scroller: Scroller = new Scroller();
  @Local session: SessionStore = AppContext.session;
  @Local feed: HomeFeedState = new HomeFeedState();
  @Local expanded: boolean = false;

  aboutToAppear(): void {
    this.feed.load();
  }

  @Builder
  masthead() {
    Row({ space: 10 }) {
      Image($r('app.media.echo_app_icon'))
        .height(36)
        .width(36)
        .borderRadius(10)
        .clip(true)
        .draggable(false)
        .accessibilityLevel('no')
      Column({ space: 1 }) {
        Text('回声')
          .fontColor(HomeTheme.textPrimary)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
        Text('E C H O')
          .fontColor(HomeTheme.accent)
          .fontSize(9)
          .fontWeight(FontWeight.Bold)
      }
      .alignItems(HorizontalAlign.Start)
      Blank()
      if (this.session.current?.offline) {
        Row({ space: 5 }) {
          Circle().width(5).height(5).fill(HomeTheme.accent)
          Text('离线曲库').fontSize(11).fontColor(HomeTheme.textSecondary)
        }
        .backgroundColor(HomeTheme.surfaceAlt)
        .borderRadius(20)
        .padding({ left: 9, right: 9, top: 5, bottom: 5 })
      }
    }
    .width('100%')
  }

  @Builder
  sectionTitle(title: string, detail: string) {
    Row({ space: 8 }) {
      Text(title)
        .fontColor(HomeTheme.textPrimary)
        .fontSize(21)
        .fontWeight(FontWeight.Bold)
      Blank()
      if (detail) {
        Text(detail).fontColor(HomeTheme.textSecondary).fontSize(12)
      }
    }
    .width('100%')
  }

  @Builder
  status(message: string, failed: boolean) {
    Column({ space: HomeTheme.sm }) {
      Text(message)
        .fontSize(HomeTheme.body)
        .fontColor(failed ? HomeTheme.error : HomeTheme.textSecondary)
      if (failed) {
        Button('重试')
          .backgroundColor(HomeTheme.accent)
          .fontColor(HomeTheme.onAccent)
          .onClick(() => { this.feed.load(); })
      }
    }
    .alignItems(HorizontalAlign.Start)
    .padding(HomeTheme.lg)
    .width('100%')
    .backgroundColor(failed ? HomeTheme.errorSurface : HomeTheme.surface)
    .borderRadius(14)
  }

  @Builder
  header() {
    Column({ space: 17 }) {
      this.masthead()
      Row() {
        Text('发现音乐')
          .fontSize(32)
          .fontColor(HomeTheme.textPrimary)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Button({ type: ButtonType.Circle }) {
          MusicIcon({ name: 'search', iconSize: 23, tint: HomeTheme.textPrimary })
        }
        .width(46)
        .height(46)
        .backgroundColor(HomeTheme.surface)
        .border({ width: 1, color: HomeTheme.border })
        .id('discover-search')
        .accessibilityText('搜索')
        .onClick(() => { this.onSearch(); })
      }
      .width('100%')

      if (this.feed.error) {
        this.status(this.feed.error, true)
      }
      if (this.feed.data) {
        if ((this.feed.data?.banners.length ?? 0) > 0) {
          BannerSwiper({ banners: this.feed.data?.banners ?? [], onPlaylist: this.onPlaylist })
        }
        Column({ space: 12 }) {
          this.sectionTitle('每日推荐', '左右滑动查看更多')
          if ((this.feed.data?.daily.length ?? 0) > 0) {
            DailyRow({ songs: this.feed.songs, onSong: this.onSong })
          } else {
            this.status('暂无每日推荐', false)
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        this.sectionTitle('推荐歌单', '')
        if ((this.feed.data?.playlists.length ?? 0) === 0) {
          this.status('暂无推荐歌单', false)
        }
      } else if (this.feed.loading || !this.feed.error) {
        Row({ space: HomeTheme.sm }) {
          LoadingProgress().color(HomeTheme.accent).width(26).height(26)
          Text('正在加载推荐…').fontSize(14).fontColor(HomeTheme.textSecondary)
        }
        .padding(HomeTheme.lg)
        .width('100%')
      }
    }
    .padding({ top: 14, bottom: 9 })
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  tab(label: string, icon: string, selected: boolean, run: () => void) {
    Button({ type: ButtonType.Normal }) {
      Column({ space: 3 }) {
        MusicIcon({ name: icon, iconSize: 22, tint: selected ? HomeTheme.accent : HomeTheme.textSecondary })
        Text(label)
          .fontSize(11)
          .fontColor(selected ? HomeTheme.accent : HomeTheme.textSecondary)
          .fontWeight(selected ? FontWeight.Bold : FontWeight.Medium)
      }
    }
    .height(49)
    .width('100%')
    .layoutWeight(this.expanded ? 0 : 1)
    .borderRadius(13)
    .backgroundColor(selected ? HomeTheme.accentSurface : Color.Transparent)
    .accessibilityText(label)
    .accessibilitySelected(selected)
    .onClick(() => { run(); })
  }

  @Builder
  navigationItems() {
    this.tab('发现', 'disc', true, () => { this.scroller.scrollToIndex(0); })
    this.tab('搜索', 'search', false, this.onSearch)
    if (this.session.current?.offline) {
      this.tab('专辑', 'albums', false, this.onAlbums)
    }
    this.tab('我的', 'person', false, this.onAccount)
  }

  @Builder
  discovery() {
    Column() {
      Refresh({ refreshing: this.feed.refreshing }) {
        List({ scroller: this.scroller }) {
          ListItemGroup({ header: this.header() }) {
            LazyForEach(this.feed.playlists, (playlist: Playlist) => {
              ListItem() {
                PlaylistListCell({ playlist: playlist })
              }
              .focusable(true)
              .onClick(() => { this.onPlaylist(playlist.id); })
            }, (playlist: Playlist) => playlist.id.toString() + '|' + playlist.name + '|' +
              (playlist.coverUrl ?? '') + '|' + playlist.playCount.toString())
          }
        }
        .cachedCount(4)
        .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
        .lanes(this.expanded ? 2 : 1, 18)
        .contentEndOffset(16)
        .scrollBar(BarState.Off)
        .padding({ left: 20, right: 20 })
        .width('100%')
        .height('100%')
      }
      .onRefreshing(() => { this.feed.load(true); })
      .width('100%')
      .constraintSize({ maxWidth: EXPANDED_CONTENT_WIDTH })
      .layoutWeight(1)

      if (this.player.current) {
        Column() {
          MiniPlayer({ player: this.player, onStop: this.onStop, onOpen: this.onOpenPlayer, onToggle: this.onToggle })
        }
        .width('100%')
        .constraintSize({ maxWidth: EXPANDED_CONTENT_WIDTH })
        .padding({ left: 14, right: 14, bottom: 7 })
      }
      if (!this.expanded) {
        Column() {
          Row({ space: 8 }) {
            this.navigationItems()
          }
          .width('100%')
          .padding({ left: 15, right: 15, top: 6, bottom: 5 })
        }
        .width('100%')
        .backgroundColor(HomeTheme.surface)
        .border({ width: { top: 1 }, color: HomeTheme.border })
      }
    }
    .layoutWeight(1)
    .height('100%')
  }

  build() {
    Row() {
      if (this.expanded) {
        Scroll() {
          Column({ space: 8 }) {
            this.navigationItems()
          }
          .width('100%')
          .padding({ left: 10, right: 10, top: 15, bottom: 15 })
        }
        .id('discover-navigation-rail')
        .width(90)
        .height('100%')
        .align(Alignment.Top)
        .scrollBar(BarState.Off)
        .backgroundColor(HomeTheme.surface)
        .border({ width: { right: 1 }, color: HomeTheme.border })
      }
      this.discovery()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(HomeTheme.background)
    .onAreaChange((_oldArea: Area, area: Area) => {
      this.expanded = windowBreakpoint(Number(area.width)) === 'expanded';
    })
  }
}
