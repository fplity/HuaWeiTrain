import { MUSIC_GRID_BREAKPOINTS, MusicIcon } from '@cloudmusic/commons';
import { OfflineFeed } from '../service/OfflineFeed';
import { OfflineMusic } from '../service/OfflineMusic';
import { FeedArtwork } from './FeedArtwork';
import { HomeTheme } from './HomeTheme';

interface BrowseCard {
  title: string;
  subtitle: string;
  cover: string;
  id: number;
  color: string;
}

@ComponentV2
export struct SearchBrowse {
  @Require @Param onPlaylist: (id: number) => void;
  @Require @Param onAlbums: () => void;
  @Require @Param onKeyword: (keyword: string) => void;

  private readonly featured = OfflineFeed.playlists.find(item => item.id === 2);
  private readonly themes: number[] = [3, 4, 6, 9];
  private readonly themeColors: string[] = ['#69505D', '#3F5866', '#54415E', '#6B4B3E'];
  private readonly artists: string[] = ['周杰伦', '孙燕姿', '林俊杰'];

  @Builder
  section(title: string) {
    Text(title)
      .fontSize(19)
      .fontWeight(FontWeight.Bold)
      .fontColor(HomeTheme.textPrimary)
      .margin({ top: 6 })
  }

  @Builder
  featuredCard(id: number, title: string, cover: string) {
    Stack({ alignContent: Alignment.Start }) {
      FeedArtwork({ src: cover, artworkId: id, wide: true })
      Row()
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Right,
          colors: [['#F6221727', 0], ['#C3221727', 0.40], ['#35221727', 0.82], ['#00221727', 1]]
        })
      Column({ space: 7 }) {
        Text('精选歌单')
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor('#F1C0CB')
        Text(title)
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(HomeTheme.playerText)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: 6 }) {
          Text('打开歌单').fontSize(12).fontWeight(FontWeight.Bold).fontColor('#361E2A')
          MusicIcon({ name: 'right', iconSize: 13, tint: '#361E2A' })
        }
        .height(32)
        .padding({ left: 11, right: 9 })
        .margin({ top: 4 })
        .backgroundColor('#F9E1E7')
        .borderRadius(10)
      }
      .width('72%')
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 18 })
    }
    .id('search-featured')
    .width('100%')
    .height(166)
    .borderRadius(20)
    .clip(true)
    .accessibilityText('精选歌单：' + title)
    .focusable(true)
    .onClick(() => { this.onPlaylist(id); })
  }

  private themeCard(id: number, index: number): BrowseCard {
    const playlist = OfflineFeed.playlists.find(item => item.id === id);
    return {
      title: playlist?.name ?? '歌单',
      subtitle: '',
      cover: playlist?.coverUrl ?? '',
      id: id,
      color: this.themeColors[index]
    };
  }

  private artistCard(artist: string): BrowseCard {
    const songs = OfflineMusic.songs.filter(song => song.artist.includes(artist));
    return {
      title: artist,
      subtitle: songs.length.toString() + ' 首',
      cover: songs[0]?.coverUrl ?? '',
      id: songs[0]?.id ?? 0,
      color: '#4D394D'
    };
  }

  @Builder
  card(item: BrowseCard, action: () => void) {
    Stack({ alignContent: Alignment.Start }) {
      Row() {
        Blank()
        Stack() {
          FeedArtwork({ src: item.cover, artworkId: item.id, thumbnailEdge: 160 })
        }
        .width('45%')
        .height('100%')
        .clip(true)
      }
      .width('100%')
      .height('100%')
      Row()
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Right,
          colors: [[item.color, 0], [item.color, 0.54], ['#29302230', 0.85], ['#00302230', 1]]
        })
      Column({ space: 4 }) {
        Text(item.title)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(HomeTheme.playerText)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        if (item.subtitle) {
          Text(item.subtitle).fontSize(11).fontColor('#F7E6ED')
        }
      }
      .width('76%')
      .padding({ left: 12 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height(82)
    .backgroundColor(item.color)
    .borderRadius(13)
    .clip(true)
    .accessibilityText(item.title)
    .focusable(true)
    .onClick(action)
  }

  build() {
    Scroll() {
      Column({ space: 12 }) {
        if (this.featured) {
          this.featuredCard(this.featured.id, this.featured.name, this.featured.coverUrl ?? '')
        }
        this.section('按主题听')
        GridRow({ columns: { xs: 2, sm: 4 }, gutter: 10,
          breakpoints: { value: MUSIC_GRID_BREAKPOINTS, reference: BreakpointsReference.ComponentSize } }) {
          ForEach(this.themes, (id: number, index: number) => {
            GridCol() {
              this.card(this.themeCard(id, index), () => { this.onPlaylist(id); })
            }
          }, (id: number) => id.toString())
        }
        .width('100%')

        this.section('浏览曲库')
        GridRow({ columns: { xs: 2, sm: 4 }, gutter: 10,
          breakpoints: { value: MUSIC_GRID_BREAKPOINTS, reference: BreakpointsReference.ComponentSize } }) {
          ForEach(this.artists, (artist: string) => {
            GridCol() {
              this.card(this.artistCard(artist), () => { this.onKeyword(artist); })
            }
          }, (artist: string) => artist)
          GridCol() {
            this.card({
              title: '全部专辑',
              subtitle: OfflineMusic.albums.length.toString() + ' 张专辑',
              cover: OfflineMusic.albums[0]?.coverUrl ?? '',
              id: OfflineMusic.albums[0]?.id ?? 0,
              color: '#624052'
            }, this.onAlbums)
          }
        }
        .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ top: 2, bottom: 12 })
    }
    .id('search-browse')
    .width('100%')
    .layoutWeight(1)
    .align(Alignment.Top)
    .scrollBar(BarState.Off)
  }
}
