import { MusicIcon } from '@cloudmusic/commons';
import { HomeTheme } from './HomeTheme';

@ComponentV2
export struct FeedArtwork {
  @Param src: string = '';
  @Param artworkId: number = 0;
  @Param wide: boolean = false;
  @Param thumbnailEdge: number = 256;
  @Local imageFailed: boolean = false;

  @Monitor('src')
  onSourceChange(): void {
    this.imageFailed = false;
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      if ((this.src.startsWith('https://') || this.src.startsWith('rawfile:')) && !this.imageFailed) {
        Image(this.src.startsWith('rawfile:') ? $rawfile(this.src.substring(8)) : this.src)
          .objectFit(ImageFit.Cover)
          .sourceSize({ width: this.wide ? 840 : this.thumbnailEdge,
            height: this.wide ? (this.src.startsWith('rawfile:') ? 840 : 400) : this.thumbnailEdge })
          .width('100%')
          .height('100%')
          .draggable(false)
          .onError(() => { this.imageFailed = true; })
      } else {
        MusicIcon({ name: 'disc', iconSize: this.wide ? 62 : 23, tint: HomeTheme.artworkAccent(this.artworkId) })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(HomeTheme.artworkBackground(this.artworkId))
    .accessibilityLevel('no')
  }
}
