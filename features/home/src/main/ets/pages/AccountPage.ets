import { AppContext, MusicIcon, MusicPageHeader, SessionStore, SignOutButton } from '@cloudmusic/commons';
import { HomeTheme } from '../view/HomeTheme';

@ComponentV2
export struct AccountPage {
  @Require @Param onBack: () => void;
  @Local session: SessionStore = AppContext.session;

  build() {
    NavDestination() {
      Column({ space: 12 }) {
        MusicPageHeader({ title: '我的', caption: 'ACCOUNT', onBack: this.onBack })
        Column({ space: 20 }) {
          Row({ space: 14 }) {
            Stack({ alignContent: Alignment.Center }) {
              MusicIcon({ name: 'person', iconSize: 27 })
            }
            .width(56)
            .height(56)
            .backgroundColor(HomeTheme.wine)
            .borderRadius(18)
            Column({ space: 4 }) {
              Text(this.session.current?.user.nickname || '听众')
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor(HomeTheme.textPrimary)
              Text(this.session.current?.offline ? '离线听众' : '听众')
                .fontSize(13)
                .fontColor(HomeTheme.textSecondary)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
          }
          .width('100%')
          .padding(16)
          .backgroundColor(HomeTheme.surface)
          .borderRadius(18)
          SignOutButton()
        }
        .width('100%')
        .constraintSize({ maxWidth: 440 })
        .padding({ left: 20, right: 20 })
      }
      .height('100%')
      .width('100%')
      .backgroundColor(HomeTheme.background)
    }
    .hideTitleBar(true)
  }
}
