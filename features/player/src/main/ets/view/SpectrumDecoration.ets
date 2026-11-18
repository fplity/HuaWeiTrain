import { MusicTheme } from '@cloudmusic/commons';

@ComponentV2
export struct SpectrumDecoration {
  private readonly heights: number[] = [5, 8, 12, 19, 11, 25, 16, 29, 23, 13, 21, 11, 15, 8, 5];

  build() {
    Row({ space: MusicTheme.xs }) {
      ForEach(this.heights, (height: number) => {
        Rect()
          .width(4)
          .height(height)
          .radius(2)
          .fill(MusicTheme.accent)
      }, (_height: number, index: number) => index.toString())
    }
    .height(30)
    .alignItems(VerticalAlign.Center)
    .accessibilityLevel('no-hide-descendants')
  }
}
