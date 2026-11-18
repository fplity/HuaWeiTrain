import { AppContext } from '../utils/AppContext';
import { HttpService } from '../utils/HttpService';
import { MusicTheme } from './MusicTheme';

@ComponentV2
export struct SignOutButton {
  @Local signingOut: boolean = false;
  @Local error: string = '';

  private async signOut(): Promise<void> {
    if (this.signingOut) {
      return;
    }
    this.signingOut = true;
    this.error = '';
    try {
      if (AppContext.session.current?.offline === false) {
        HttpService.post<boolean>('/auth/logout').catch(() => {});
      }
      await AppContext.clear();
    } catch (error) {
      this.error = (error as Error).message;
    } finally {
      this.signingOut = false;
    }
  }

  build() {
    Column({ space: 8 }) {
      if (this.error) {
        Text(this.error).fontColor(MusicTheme.error).fontSize(13)
      }
      Button(this.signingOut ? '正在退出…' : '退出登录')
        .width('100%')
        .height(48)
        .backgroundColor(MusicTheme.accentSurface)
        .fontColor(MusicTheme.accent)
        .fontSize(14)
        .enabled(!this.signingOut)
        .onClick(() => { this.signOut(); })
    }
    .width('100%')
  }
}
