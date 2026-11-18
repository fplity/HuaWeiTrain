import { MusicIcon, Playlist } from '@cloudmusic/commons';
import { FeedArtwork } from './FeedArtwork';
import { HomeTheme } from './HomeTheme';

@ComponentV2
export struct PlaylistListCell {
  @Require @Param playlist: Playlist;

  build() {
    Row({ space: 12 }) {
      Stack() {
        FeedArtwork({ src: this.playlist.coverUrl ?? '', artworkId: this.playlist.id, thumbnailEdge: 192 })
      }
      .width(53)
      .height(53)
      .borderRadius(11)
      .clip(true)

      Column({ space: 4 }) {
        Text(this.playlist.name)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(HomeTheme.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        if (this.playlist.playCount > 0) {
          Text(this.playlist.playCount.toString() + ' 次播放')
            .fontSize(12)
            .fontColor(HomeTheme.textSecondary)
            .maxLines(1)
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      MusicIcon({ name: 'right', iconSize: 17, tint: HomeTheme.textSecondary })
    }
    .padding({ left: 1, right: 3 })
    .width('100%')
    .height(70)
    .border({ width: { bottom: 1 }, color: HomeTheme.border })
  }
}
