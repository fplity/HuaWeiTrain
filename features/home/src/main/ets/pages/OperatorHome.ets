import { AppContext, MusicIcon, SessionStore } from '@cloudmusic/commons';
import { HomeTheme } from '../view/HomeTheme';

@ComponentV2
export struct OperatorHome {
  @Local session: SessionStore = AppContext.session;

  build() {
    Column({ space: 16 }) {
      Row({ space: 10 }) {
        MusicIcon({ name: 'disc', iconSize: 23, tint: HomeTheme.accent })
        Text('回声 / ECHO').fontSize(15).fontColor(HomeTheme.accent).fontWeight(FontWeight.Bold)
      }
      Text('内容运营').fontSize(32).fontWeight(FontWeight.Bold).fontColor(HomeTheme.textPrimary)
      Row({ space: 12 }) {
        MusicIcon({ name: 'person', iconSize: 24, tint: HomeTheme.accent })
        Column({ space: 5 }) {
          Text(this.session.current?.user.nickname ?? '').fontSize(17).fontColor(HomeTheme.textPrimary)
          Text(this.session.current?.offline ? '离线演示' : '运营账号')
            .fontSize(13).fontColor(HomeTheme.textSecondary)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .padding(16)
      .backgroundColor(HomeTheme.surface)
      .borderRadius(17)
    }
    .width('100%')
    .constraintSize({ maxWidth: 440 })
    .padding(22)
    .alignItems(HorizontalAlign.Start)
  }
}
