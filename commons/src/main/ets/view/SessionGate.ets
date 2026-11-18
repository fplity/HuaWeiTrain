import { AppContext } from '../utils/AppContext';
import { SessionStore } from '../store/SessionStore';
import { MusicTheme } from './MusicTheme';
import { SignOutButton } from './SignOutButton';

@ComponentV2
export struct SessionGate {
  @BuilderParam login: () => void;
  @BuilderParam listenerHome: () => void;
  @BuilderParam operatorHome: () => void;
  @Local session: SessionStore = AppContext.session;

  aboutToAppear(): void {
    AppContext.restore();
  }

  build() {
    if (!this.session.ready) {
      Column() {
        LoadingProgress()
          .width(36)
          .height(36)
          .color(MusicTheme.accent)
          .accessibilityText('正在恢复登录状态')
      }
      .width('100%')
      .height('100%')
      .backgroundColor(MusicTheme.background)
      .justifyContent(FlexAlign.Center)
    } else if (this.session.current?.user.role === 'operator') {
      Column() {
        this.operatorHome()
        Blank()
        Column() {
          SignOutButton()
        }
        .width('100%')
        .constraintSize({ maxWidth: 440 })
        .padding({ left: 20, right: 20, bottom: 24 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(MusicTheme.background)
    } else if (this.session.current) {
      this.listenerHome()
    } else {
      this.login()
    }
  }
}
