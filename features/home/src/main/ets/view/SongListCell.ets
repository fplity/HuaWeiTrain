import { MusicIcon, Song } from '@cloudmusic/commons';
import { FeedArtwork } from './FeedArtwork';
import { HomeTheme } from './HomeTheme';

@ComponentV2
export struct SongListCell {
  @Require @Param song: Song;

  build() {
    Column({ space: 4 }) {
      Stack({ alignContent: Alignment.BottomEnd }) {
        FeedArtwork({ src: this.song.coverUrl ?? '', artworkId: this.song.id })
        Stack() {
          MusicIcon({ name: 'play', iconSize: 14, tint: '#38232D' })
        }
        .width(25)
        .height(25)
        .backgroundColor('#EFFBF2F5')
        .borderRadius(13)
        .margin(6)
      }
      .width('100%')
      .aspectRatio(1)
      .borderRadius(12)
      .clip(true)
      .margin({ bottom: 3 })

      Text(this.song.title)
        .fontSize(14)
        .fontColor(HomeTheme.textPrimary)
        .fontWeight(FontWeight.Bold)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(this.song.artist)
        .fontSize(11)
        .fontColor(HomeTheme.textSecondary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width(108)
    .alignItems(HorizontalAlign.Start)
  }
}
