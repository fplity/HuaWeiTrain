import { EXPANDED_CONTENT_WIDTH, MiniPlayer, MUSIC_GRID_BREAKPOINTS, MusicIcon, MusicPageHeader,
  PlayerStore } from '@cloudmusic/commons';
import { PlaylistDetails } from '../model/PlaylistDetails';
import { OfflineMusic } from '../service/OfflineMusic';
import { FeedArtwork } from '../view/FeedArtwork';
import { HomeTheme } from '../view/HomeTheme';

@ComponentV2
export struct AlbumsPage {
  @Require @Param onBack: () => void;
  @Require @Param onAlbum: (id: number) => void;
  @Require @Param onOpenPlayer: () => void;
  @Require @Param onStop: () => void;
  @Require @Param onToggle: () => void;
  @Require @Param player: PlayerStore;
  @Local shortWindow: boolean = false;

  @Builder
  albumCard(album: PlaylistDetails) {
    Column({ space: 5 }) {
      Stack({ alignContent: Alignment.BottomEnd }) {
        FeedArtwork({ src: album.coverUrl ?? '', artworkId: album.id })
        Text(album.songs.length.toString() + ' 首')
          .fontColor('#FFF4F7')
          .fontSize(10)
          .fontWeight(FontWeight.Bold)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor('#C6241821')
          .borderRadius(15)
          .margin(8)
      }
      .width('100%')
      .aspectRatio(1)
      .borderRadius(13)
      .clip(true)
      .margin({ bottom: 4 })

      Text(album.name)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(HomeTheme.textPrimary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(album.albumArtist ?? '')
        .fontSize(12)
        .fontColor(HomeTheme.textSecondary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .accessibilityText(album.name)
    .focusable(true)
    .onClick(() => { this.onAlbum(album.id); })
  }

  build() {
    NavDestination() {
      Column() {
        MusicPageHeader({ title: '专辑', caption: 'THE COLLECTION', onBack: this.onBack })
        Scroll() {
          Column({ space: 14 }) {
            Row({ space: 8 }) {
              MusicIcon({ name: 'albums', iconSize: 16, tint: HomeTheme.accent })
              Text(OfflineMusic.albums.length.toString() + ' 张专辑 · ' + OfflineMusic.songs.length.toString() + ' 首歌')
                .fontSize(13)
                .fontColor(HomeTheme.textSecondary)
            }
            if (OfflineMusic.albums.length) {
              GridRow({ columns: { xs: 2, sm: this.shortWindow ? 4 : 3, md: this.shortWindow ? 5 : 4,
                  lg: this.shortWindow ? 6 : 5 },
                gutter: { x: 14, y: 18 }, breakpoints: { value: [...MUSIC_GRID_BREAKPOINTS, '1080vp'],
                  reference: BreakpointsReference.ComponentSize } }) {
                ForEach(OfflineMusic.albums, (album: PlaylistDetails) => {
                  GridCol() {
                    this.albumCard(album)
                  }
                }, (album: PlaylistDetails) => album.id.toString())
              }
              .width('100%')
            } else {
              Text('还没有可浏览的专辑').fontSize(14).fontColor(HomeTheme.textSecondary)
            }
          }
          .padding({ left: 20, right: 20, top: 4, bottom: 18 })
          .alignItems(HorizontalAlign.Start)
          .width('100%')
        }
        .scrollBar(BarState.Off)
        .width('100%')
        .constraintSize({ maxWidth: EXPANDED_CONTENT_WIDTH })
        .layoutWeight(1)

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
      .onAreaChange((_oldArea: Area, area: Area) => { this.shortWindow = Number(area.height) < 500; })
    }
    .hideTitleBar(true)
  }
}
