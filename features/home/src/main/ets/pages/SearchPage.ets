import { MiniPlayer, MusicPageHeader, PlayerStore, Song } from '@cloudmusic/commons';
import { SearchResult } from '../model/SearchResult';
import { SearchBrowse } from '../view/SearchBrowse';
import { CatalogListCell } from '../view/CatalogListCell';
import { HomeTheme } from '../view/HomeTheme';
import { SearchState } from '../viewmodel/SearchState';

@ComponentV2
export struct SearchPage {
  @Require @Param onBack: () => void;
  @Require @Param onPlaylist: (id: number) => void;
  @Require @Param onAlbums: () => void;
  @Require @Param onSong: (song: Song) => void;
  @Require @Param onStop: () => void;
  @Require @Param onOpenPlayer: () => void;
  @Require @Param onToggle: () => void;
  @Require @Param player: PlayerStore;
  @Local state: SearchState = new SearchState();

  aboutToDisappear(): void {
    this.state.cancel();
  }

  private choose(result: SearchResult): void {
    if (result.playlistId !== undefined) {
      this.onPlaylist(result.playlistId);
    } else if (result.song) {
      this.onSong(result.song);
    }
  }

  @Builder
  status() {
    if (this.state.error) {
      Row({ space: HomeTheme.sm }) {
        Text(this.state.error)
          .fontColor(HomeTheme.error)
          .fontSize(HomeTheme.body)
          .layoutWeight(1)
        Button('重试')
          .backgroundColor(HomeTheme.accent)
          .fontColor(HomeTheme.onAccent)
          .onClick(() => { this.state.retry(); })
      }
      .padding(HomeTheme.lg)
      .width('100%')
      .backgroundColor(HomeTheme.errorSurface)
      .borderRadius(HomeTheme.radiusMd)
    } else if (this.state.loading) {
      Row({ space: HomeTheme.sm }) {
        LoadingProgress().width(20).height(20).color(HomeTheme.accent)
        Text(this.state.count > 0 ? '正在加载更多…' : '正在搜索…')
          .fontColor(HomeTheme.textSecondary).fontSize(HomeTheme.caption)
      }
      .padding(HomeTheme.md)
    } else if (this.state.keyword.trim() && !this.state.waiting && this.state.count === 0) {
      Text('没有找到匹配结果')
        .padding(HomeTheme.md)
        .fontColor(HomeTheme.textSecondary)
    }
  }

  build() {
    NavDestination() {
      Column() {
        MusicPageHeader({ title: '搜索', onBack: this.onBack, maxWidth: 840 })
        Column({ space: 12 }) {
          Search({ value: this.state.keyword, placeholder: '歌曲、艺人、专辑或歌单' })
            .id('catalog-search')
            .placeholderColor(HomeTheme.textSecondary)
            .fontColor(HomeTheme.textPrimary)
            .textFont({ size: 15 })
            .height(48)
            .backgroundColor(HomeTheme.surfaceAlt)
            .borderRadius(14)
            .onChange((keyword: string) => { this.state.setKeyword(keyword); })
            .onSubmit((keyword: string) => { this.state.setKeyword(keyword); })
            .width('100%')

          if (this.state.keyword.trim()) {
            if (this.state.count > 0) {
              Text('已显示 ' + this.state.count.toString() + ' 条结果')
                .fontSize(12)
                .fontColor(HomeTheme.textSecondary)
            }
            List() {
              LazyForEach(this.state.results, (result: SearchResult) => {
                ListItem() {
                  CatalogListCell({
                    title: result.title,
                    subtitle: result.subtitle,
                    coverUrl: result.coverUrl,
                    artworkId: result.artworkId,
                    isSong: !!result.song,
                    active: !!result.song && result.song.id === this.player.current?.id
                  })
                }
                .focusable(true)
                .onClick(() => { this.choose(result); })
              }, (result: SearchResult) => result.key)
            }
            .width('100%')
            .layoutWeight(1)
            .cachedCount(4)
            .scrollBar(BarState.Off)
            .onReachEnd(() => { this.state.loadMore(); })
            this.status()
          } else {
            SearchBrowse({
              onPlaylist: this.onPlaylist,
              onAlbums: this.onAlbums,
              onKeyword: (keyword: string) => { this.state.setKeyword(keyword); }
            })
          }
          MiniPlayer({ player: this.player, onStop: this.onStop, onOpen: this.onOpenPlayer, onToggle: this.onToggle })
        }
        .width('100%')
        .layoutWeight(1)
        .constraintSize({ maxWidth: 840 })
        .padding({ left: 20, right: 20, bottom: 10 })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(HomeTheme.background)
    }
    .hideTitleBar(true)
  }
}
