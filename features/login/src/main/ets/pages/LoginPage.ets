import { ApiConfig, AppContext, MusicTheme, Role, SessionStore } from '@cloudmusic/commons';
import { AuthService } from '../service/AuthService';

@ComponentV2
export struct LoginPage {
  @Local account: string = '';
  @Local password: string = '';
  @Local busy: boolean = false;
  @Local error: string = '';
  @Local session: SessionStore = AppContext.session;

  private async signIn(offlineRole?: Role): Promise<void> {
    if (this.busy) {
      return;
    }
    this.busy = true;
    this.error = '';
    try {
      if (offlineRole) {
        await AuthService.enterOffline(offlineRole);
      } else {
        await AuthService.login(this.account, this.password);
      }
      this.password = '';
    } catch (error) {
      this.error = (error as Error).message;
    } finally {
      this.busy = false;
    }
  }

  @Builder
  brand() {
    Stack({ alignContent: Alignment.Center }) {
      Circle().width(296).height(296).fill(Color.Transparent).stroke('#46FFB0C4').strokeWidth(1)
        .translate({ x: 132, y: -70 })
      Circle().width(248).height(248).fill(Color.Transparent).stroke('#3DFFB0C4').strokeWidth(1)
        .translate({ x: 132, y: -70 })
      Circle().width(201).height(201).fill(Color.Transparent).stroke('#36FFB0C4').strokeWidth(1)
        .translate({ x: 132, y: -70 })
      Circle().width(157).height(157).fill(Color.Transparent).stroke('#2EFFB0C4').strokeWidth(1)
        .translate({ x: 132, y: -70 })
      Column({ space: 12 }) {
        Image($r('app.media.echo_app_icon'))
          .width(51)
          .height(51)
          .borderRadius(15)
          .clip(true)
          .draggable(false)
          .accessibilityLevel('no')

        Column({ space: 4 }) {
          Text('E C H O  /  M U S I C')
            .fontSize(10)
            .fontWeight(FontWeight.Bold)
            .fontColor(MusicTheme.playerAccent)
          Text('回声')
            .fontSize(47)
            .fontWeight(FontWeight.Bold)
            .fontColor(MusicTheme.playerText)
        }
        .alignItems(HorizontalAlign.Start)
        Text('把喜欢的歌，留在耳边。')
          .fontSize(13)
          .fontColor(MusicTheme.playerMuted)
      }
      .width('100%')
      .padding(23)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height(233)
    .linearGradient({ direction: GradientDirection.RightBottom, colors: [['#312132', 0], ['#714157', 1]] })
    .borderRadius(22)
    .clip(true)
  }

  build() {
    Scroll() {
      Column({ space: 17 }) {
        this.brand()
        Column({ space: 5 }) {
          Text(ApiConfig.loginReady ? '欢迎回来' : '开始听歌')
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .fontColor(MusicTheme.textPrimary)
          Text(ApiConfig.loginReady ? '登录后，找回你的音乐。' : '打开本地曲库，随时听你喜欢的歌。')
            .fontSize(14)
            .fontColor(MusicTheme.textSecondary)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')

        if (ApiConfig.loginReady) {
          TextInput({ text: this.account, placeholder: '账号' })
            .accessibilityText('账号')
            .maxLength(128)
            .height(48)
            .backgroundColor(MusicTheme.surfaceAlt)
            .fontColor(MusicTheme.textPrimary)
            .placeholderColor(MusicTheme.textSecondary)
            .enterKeyType(EnterKeyType.Next)
            .onChange((value: string) => { this.account = value; })
            .enabled(!this.busy)
          TextInput({ text: this.password, placeholder: '密码' })
            .accessibilityText('密码')
            .type(InputType.Password)
            .height(48)
            .backgroundColor(MusicTheme.surfaceAlt)
            .fontColor(MusicTheme.textPrimary)
            .placeholderColor(MusicTheme.textSecondary)
            .enterKeyType(EnterKeyType.Go)
            .onChange((value: string) => { this.password = value; })
            .onSubmit(() => { this.signIn(); })
            .enabled(!this.busy)
          Button(this.busy ? '正在登录…' : '登录')
            .width('100%')
            .height(48)
            .fontColor(MusicTheme.onAccent)
            .backgroundColor(MusicTheme.accent)
            .enabled(!this.busy)
            .onClick(() => { this.signIn(); })
        }
        Column({ space: 8 }) {
          Button('以听众身份演示')
            .width('100%')
            .height(48)
            .fontColor(MusicTheme.onAccent)
            .backgroundColor(MusicTheme.accent)
            .enabled(!this.busy)
            .onClick(() => { this.signIn('listener'); })
          Button('以运营身份演示')
            .width('100%')
            .height(46)
            .fontColor(MusicTheme.accent)
            .backgroundColor(MusicTheme.accentSurface)
            .enabled(!this.busy)
            .onClick(() => { this.signIn('operator'); })
        }
        if (this.error || this.session.notice) {
          Text(this.error || this.session.notice)
            .fontSize(13)
            .fontColor(MusicTheme.error)
        }
      }
      .width('100%')
      .constraintSize({ maxWidth: 450 })
      .padding({ left: 24, right: 24, top: 28, bottom: 32 })
      .alignItems(HorizontalAlign.Start)
    }
    .align(Alignment.Center)
    .scrollBar(BarState.Off)
    .width('100%')
    .height('100%')
    .backgroundColor(MusicTheme.background)
  }
}
