import { MusicIcon } from './MusicIcon';
import { MusicTheme } from './MusicTheme';
import { EXPANDED_CONTENT_WIDTH } from '../utils/Breakpoint';

@ComponentV2
export struct MusicPageHeader {
  @Param title: string = '';
  @Param caption: string = '';
  @Param maxWidth: number = EXPANDED_CONTENT_WIDTH;
  @Require @Param onBack: () => void;

  build() {
    Row({ space: 12 }) {
      Button({ type: ButtonType.Circle }) {
        MusicIcon({ name: 'left', iconSize: 22, tint: MusicTheme.textPrimary })
      }
      .width(44)
      .height(44)
      .backgroundColor(MusicTheme.surfaceAlt)
      .accessibilityText('返回')
      .onClick(() => { this.onBack(); })
      Column({ space: 3 }) {
        if (this.caption) {
          Text(this.caption)
            .fontSize(9)
            .fontWeight(FontWeight.Bold)
            .letterSpacing(2)
            .fontColor(MusicTheme.accent)
        }
        Text(this.title)
          .fontSize(23)
          .fontWeight(FontWeight.Bold)
          .fontColor(MusicTheme.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .padding({ left: 20, right: 20, top: 13, bottom: 12 })
    .width('100%')
    .constraintSize({ maxWidth: this.maxWidth })
  }
}
