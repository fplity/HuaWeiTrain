import { MusicIcon } from '@cloudmusic/commons';
import { FeedArtwork } from './FeedArtwork';
import { HomeTheme } from './HomeTheme';

@ComponentV2
export struct CatalogListCell {
  @Param title: string = '';
  @Param subtitle: string = '';
  @Param coverUrl: string = '';
  @Param artworkId: number = 0;
  @Param showArtwork: boolean = true;
  @Param durationText: string = '';
  @Param number: number = 0;
  @Param isSong: boolean = false;
  @Param active: boolean = false;

  build() {
    Row({ space: 12 }) {
      if (this.number > 0) {
        Text(this.number.toString().padStart(2, '0'))
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.active ? HomeTheme.accent : HomeTheme.textSecondary)
          .textAlign(TextAlign.Center)
          .width(22)
      }
      if (this.showArtwork) {
        Stack() {
          FeedArtwork({ src: this.coverUrl, artworkId: this.artworkId })
        }
        .width(43)
        .height(43)
        .borderRadius(8)
        .clip(true)
      }
      Column({ space: 4 }) {
        Text(this.title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.active ? HomeTheme.accent : HomeTheme.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.subtitle)
          .fontSize(12)
          .fontColor(HomeTheme.textSecondary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      if (this.durationText) {
        Text(this.durationText)
          .fontColor(HomeTheme.textSecondary)
          .fontSize(11)
      }
      MusicIcon({ name: this.active ? 'disc' : (this.isSong ? 'play' : 'right'), iconSize: 18,
        tint: this.active ? HomeTheme.accent : HomeTheme.textSecondary })
    }
    .padding({ right: 6 })
    .width('100%')
    .height(61)
    .border({ width: { bottom: 1 }, color: HomeTheme.border })
  }
}
